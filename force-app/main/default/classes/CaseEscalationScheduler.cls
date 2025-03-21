global class CaseEscalationScheduler implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        escalateCases();
    }
    
    @future
    public static void escalateCases() {
        // Query cases that need escalation based on Next_Escalation_Time__c
        List<Case> casesToEscalate = [
            SELECT Id, OwnerId, Escalation_Level__c, Priority, Product__c, 
                   Next_Escalation_Time__c, Status
            FROM Case
            WHERE Status NOT IN ('Closed', 'Resolved')
            AND Next_Escalation_Time__c <= :System.now()
        ];
        
        // Get escalation paths
        Map<String, Escalation_Path__mdt> escalationPaths = getEscalationPaths();
        
        List<Case> casesToUpdate = new List<Case>();
        List<Task> tasksToCreate = new List<Task>();
        
        for (Case c : casesToEscalate) {
            // Create escalation key
            String escalationKey = c.Product__c + '|' + c.Priority + '|' + c.Escalation_Level__c;
            
            if (escalationPaths.containsKey(escalationKey)) {
                Escalation_Path__mdt path = escalationPaths.get(escalationKey);
                
                // Update case with new owner and escalation level
                c.Escalation_Level__c = c.Escalation_Level__c + 1;
                c.OwnerId = path.New_Owner_Id__c;
                c.Next_Escalation_Time__c = System.now().addHours(path.Hours_Until_Next_Escalation__c.intValue());
                casesToUpdate.add(c);
                
                // Create notification task
                Task t = new Task(
                    WhatId = c.Id,
                    OwnerId = path.Notification_Recipient_Id__c,
                    Subject = 'Case Escalated - ' + c.Escalation_Level__c,
                    Description = 'This case has been escalated to level ' + c.Escalation_Level__c,
                    Priority = 'High',
                    Status = 'Not Started',
                    ActivityDate = Date.today()
                );
                tasksToCreate.add(t);
            }
        }
        
        // Update cases
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
        
        // Create notification tasks
        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }
    
    private static Map<String, Escalation_Path__mdt> getEscalationPaths() {
        Map<String, Escalation_Path__mdt> paths = new Map<String, Escalation_Path__mdt>();
        
        for (Escalation_Path__mdt path : [
            SELECT Product__c, Case_Priority__c, Current_Escalation_Level__c,
                   New_Owner_Id__c, Notification_Recipient_Id__c, Hours_Until_Next_Escalation__c
            FROM Escalation_Path__mdt
            WHERE Active__c = true
        ]) {
            String key = path.Product__c + '|' + path.Case_Priority__c + '|' + path.Current_Escalation_Level__c;
            paths.put(key, path);
        }
        
        return paths;
    }
}