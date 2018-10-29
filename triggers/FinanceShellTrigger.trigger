trigger FinanceShellTrigger on Finance_Shell__c (after insert,
                                                 after update) {
   // public static Boolean isExecuted = false;
    if(Trigger.isAfter){       
        FinanceShellsTriggerHandler handler = new FinanceShellsTriggerHandler();
        if(Trigger.isInsert){            
            handler.handleAfterInsert(Trigger.new);
        }
        else if(Trigger.isUpdate){ 
            if(checkRecursive.runOnce() || Test.isRunningTest()){
                handler.handleAfterUpdate(Trigger.new);                
            }            
        }       
    }
}