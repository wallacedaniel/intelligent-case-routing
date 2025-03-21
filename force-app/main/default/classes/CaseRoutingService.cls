public class CaseRoutingService {
    
    public void routeCases(List<Case> cases) {
        Map<String, Id> queueIdByProductAndType = getQueueMappings();
        Map<Id, Id> defaultAssigneeByQueue = getDefaultAssignees();
        
        for (Case c : cases) {
            String routingKey = c.Product__c + '|' + c.Type;
            
            // Assign to queue based on product and type
            if (queueIdByProductAndType.containsKey(routingKey)) {
                c.OwnerId = queueIdByProductAndType.get(routingKey);
            } else {
                // Fallback to default queue for the product
                String productKey = c.Product__c + '|*';
                if (queueIdByProductAndType.containsKey(productKey)) {
                    c.OwnerId = queueIdByProductAndType.get(productKey);
                }
            }
            
            // Set escalation path based on priority
            setEscalationPath(c);
            
            // Calculate SLA deadlines
            calculateSLADeadlines(c);
        }
    }
    
    private Map<String, Id> getQueueMappings() {
        Map<String, Id> mappings = new Map<String, Id>();
        
        // Query custom settings or custom metadata for routing rules
        for (Routing_Rule__mdt rule : [SELECT Product__c, Case_Type__c, Queue_API_Name__c, Queue_Id__c 
                                     FROM Routing_Rule__mdt 
                                     WHERE Active__c = true]) {
            String key = rule.Product__c + '|' + rule.Case_Type__c;
            mappings.put(key, rule.Queue_Id__c);
        }
        
        return mappings;
    }
    
    private Map<Id, Id> getDefaultAssignees() {
        Map<Id, Id> assignees = new Map<Id, Id>();
        
        // Get default assignees for each queue if needed
        for (Default_Assignee__mdt da : [SELECT Queue_Id__c, User_Id__c 
                                       FROM Default_Assignee__mdt 
                                       WHERE Active__c = true]) {
            assignees.put(da.Queue_Id__c, da.User_Id__c);
        }
        
        return assignees;
    }
    
    private void setEscalationPath(Case c) {
        // Set escalation path based on case priority and product
        if (c.Priority == 'High') {
            c.Escalation_Level__c = 1;
            c.Next_Escalation_Time__c = System.now().addHours(4);
        } else if (c.Priority == 'Medium') {
            c.Escalation_Level__c = 0;
            c.Next_Escalation_Time__c = System.now().addHours(24);
        } else {
            c.Escalation_Level__c = 0;
            c.Next_Escalation_Time__c = System.now().addHours(48);
        }
    }
    
    private void calculateSLADeadlines(Case c) {
        // Get business hours
        BusinessHours defaultHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
        
        // Calculate response time based on priority
        DateTime responseDeadline;
        if (c.Priority == 'High') {
            responseDeadline = BusinessHours.add(defaultHours.Id, System.now(), 60 * 60 * 1000); // 1 hour
        } else if (c.Priority == 'Medium') {
            responseDeadline = BusinessHours.add(defaultHours.Id, System.now(), 4 * 60 * 60 * 1000); // 4 hours
        } else {
            responseDeadline = BusinessHours.add(defaultHours.Id, System.now(), 8 * 60 * 60 * 1000); // 8 hours
        }
        c.First_Response_Deadline__c = responseDeadline;
        
        // Calculate resolution time based on priority and product
        DateTime resolutionDeadline;
        if (c.Priority == 'High') {
            resolutionDeadline = BusinessHours.add(defaultHours.Id, System.now(), 8 * 60 * 60 * 1000); // 8 hours
        } else if (c.Priority == 'Medium') {
            resolutionDeadline = BusinessHours.add(defaultHours.Id, System.now(), 24 * 60 * 60 * 1000); // 24 hours
        } else {
            resolutionDeadline = BusinessHours.add(defaultHours.Id, System.now(), 48 * 60 * 60 * 1000); // 48 hours
        }
        c.Resolution_Deadline__c = resolutionDeadline;
    }
}