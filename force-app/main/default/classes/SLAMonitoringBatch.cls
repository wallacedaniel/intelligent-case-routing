global class SLAMonitoringBatch implements Database.Batchable<sObject>, Schedulable {
    
    // Schedulable interface method
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(this);
    }
    
    // Batchable interface methods
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, CaseNumber, OwnerId, Status, First_Response_Deadline__c, 
                   Resolution_Deadline__c, First_Response_Completed__c, Priority
            FROM Case
            WHERE Status NOT IN ('Closed', 'Resolved')
            AND (
                (First_Response_Completed__c = false AND First_Response_Deadline__c <= :System.now())
                OR
                (Resolution_Deadline__c <= :System.now())
            )
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Task> tasksToCreate = new List<Task>();
        List<Case> casesToUpdate = new List<Case>();
        
        for (Case c : scope) {
            if (!c.First_Response_Completed__c && c.First_Response_Deadline__c <= System.now()) {
                // First response SLA breach
                Task t = new Task(
                    WhatId = c.Id,
                    OwnerId = c.OwnerId,
                    Subject = 'URGENT: First Response SLA Breached - ' + c.CaseNumber,
                    Description = 'The first response SLA has been breached for this case.',
                    Priority = 'High',
                    Status = 'Not Started',
                    ActivityDate = Date.today()
                );
                tasksToCreate.add(t);
                
                // Mark case for visual indicator
                c.SLA_Status__c = 'First Response Breached';
                casesToUpdate.add(c);
            }
            
            if (c.Resolution_Deadline__c <= System.now()) {
                // Resolution SLA breach
                Task t = new Task(
                    WhatId = c.Id,
                    OwnerId = c.OwnerId,
                    Subject = 'URGENT: Resolution SLA Breached - ' + c.CaseNumber,
                    Description = 'The resolution SLA has been breached for this case.',
                    Priority = 'High',
                    Status = 'Not Started',
                    ActivityDate = Date.today()
                );
                tasksToCreate.add(t);
                
                // Mark case for visual indicator
                c.SLA_Status__c = 'Resolution Breached';
                casesToUpdate.add(c);
                
                // Automatically escalate high priority cases
                if (c.Priority == 'High') {
                    c.Escalation_Level__c = c.Escalation_Level__c != null ? c.Escalation_Level__c + 1 : 1;
                    // Escalation routing will be handled by trigger
                }
            }
        }
        
        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
        
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // Send summary email to admin
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        String[] toAddresses = new String[] {System.Label.SLA_Admin_Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('SLA Monitoring Batch Job Completed');
        mail.setPlainTextBody('The SLA monitoring batch job has completed.');
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}