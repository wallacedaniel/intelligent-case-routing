trigger CaseRoutingTrigger on Case (before insert, before update) {
    // Initialize router class
    CaseRoutingService router = new CaseRoutingService();
    
    // Process cases that need routing
    List<Case> casesToRoute = new List<Case>();
    
    for (Case c : Trigger.new) {
        // Only route new cases or cases where routing criteria have changed
        if (Trigger.isInsert || 
            (Trigger.isUpdate && 
             (c.Product__c != Trigger.oldMap.get(c.Id).Product__c || 
              c.Type != Trigger.oldMap.get(c.Id).Type))) {
            casesToRoute.add(c);
        }
    }
    
    // Route cases if any need routing
    if (!casesToRoute.isEmpty()) {
        router.routeCases(casesToRoute);
    }
}