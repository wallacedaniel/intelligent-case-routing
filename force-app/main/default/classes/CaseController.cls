public with sharing class CaseController {
    
    @AuraEnabled
    public static Id createCase(Map<String, Object> caseData) {
        try {
            // Convert map to Case object
            Case newCase = new Case();
            newCase.Subject = (String) caseData.get('Subject');
            newCase.Description = (String) caseData.get('Description');
            newCase.Type = (String) caseData.get('Type');
            newCase.Priority = (String) caseData.get('Priority');
            newCase.Product__c = (String) caseData.get('Product__c');
            newCase.Origin = 'Community';
            
            // Set contact ID to current user's contact
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
            if (currentUser.ContactId != null) {
                newCase.ContactId = currentUser.ContactId;
            }
            
            // Insert the case
            insert newCase;
            return newCase.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating case: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getMyCases() {
        // Get the current user's contact ID
        User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        Id contactId = currentUser.ContactId;
        
        if (contactId != null) {
            return [
                SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, 
                       Product__c, Type, First_Response_Deadline__c, Resolution_Deadline__c
                FROM Case
                WHERE ContactId = :contactId
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        }
        return new List<Case>();
    }
    
    @AuraEnabled(cacheable=true)
    public static Case getCaseDetails(Id caseId) {
        // Verify the current user has access to this case
        User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        Id contactId = currentUser.ContactId;
        
        if (contactId != null) {
            List<Case> cases = [
                SELECT Id, CaseNumber, Subject, Description, Status, Priority, CreatedDate, 
                       Product__c, Type, First_Response_Deadline__c, Resolution_Deadline__c,
                       (SELECT Id, Body, CreatedDate, CreatedById, CreatedBy.Name 
                        FROM CaseComments 
                        WHERE IsPublished = true
                        ORDER BY CreatedDate DESC)
                FROM Case
                WHERE Id = :caseId AND ContactId = :contactId
            ];
            
            if (!cases.isEmpty()) {
                return cases[0];
            }
        }
        
        throw new AuraHandledException('Case not found or you do not have access to it.');
    }
    
    @AuraEnabled
    public static Id addCaseComment(Id caseId, String commentBody) {
        // Verify the current user has access to this case
        User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        Id contactId = currentUser.ContactId;
        
        if (contactId != null) {
            List<Case> cases = [SELECT Id FROM Case WHERE Id = :caseId AND ContactId = :contactId];
            
            if (!cases.isEmpty()) {
                CaseComment comment = new CaseComment(
                    ParentId = caseId,
                    CommentBody = commentBody,
                    IsPublished = true
                );
                insert comment;
                return comment.Id;
            }
        }
        
        throw new AuraHandledException('Case not found or you do not have access to it.');
    }
}