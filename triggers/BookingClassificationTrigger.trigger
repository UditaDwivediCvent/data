trigger BookingClassificationTrigger on Booking_Classification__c (after insert,after update,before delete,after delete) {
    if(trigger.isInsert){
        if(trigger.isBefore){            
        }
        else if(trigger.isAfter){
            //For ByPassing Opportunity Trigger...
            Constants.IsOpportunityTriggerActive = FALSE;
            system.debug('Test insert0');
            BookingClassificationHandler.onAfterInsert(trigger.newMap);
        }
    }
    else if(trigger.isUpdate){
        if(trigger.isBefore){
        }
        else if(trigger.isAfter){
            //For ByPassing Opportunity Trigger...
            Constants.IsOpportunityTriggerActive = FALSE;
            system.debug('Test insert1');
            BookingClassificationHandler.onAfterUpdate(trigger.oldMap,trigger.newMap);
        }
    }
    else if(trigger.isDelete){
        if(trigger.isBefore){
             
        }
        else if(trigger.isAfter){
            //For ByPassing Opportunity Trigger...
            Constants.IsOpportunityTriggerActive = FALSE;
            system.debug('Test insert2');
            BookingClassificationHandler.onAfterDelete(trigger.oldMap);
        }
    }
}