/*
//////////////////////////////////////
//		@author Abhishek Pandey		//
/////////////////////////////////////
Version :	1.0
Date : 3rd July 2014
Description : Supplies Data to page Report_Budget_Actual_page for showing opportunity data on the basis of filters given on page binded with this controller
*/
trigger AdvocateTrg on Advocates__c (after delete, after insert, after undelete,after update, before delete, before insert, before update) {
	AdvocateTrgHelperCls handler = new AdvocateTrgHelperCls();
       
    if(Trigger.isInsert && Trigger.isBefore){
        handler.OnBeforeInsert(Trigger.new);          
    }
    else if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.newMap);        
    }
    else if(Trigger.isUpdate && Trigger.isBefore){
        handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);        
    }
    else if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);        
    }    
    else if(Trigger.isDelete && Trigger.isBefore){
        handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);        
    }
    else if(Trigger.isDelete && Trigger.isAfter){
        handler.OnAfterDelete(Trigger.old, Trigger.oldMap);        
    }    
    else if(Trigger.isUnDelete){
        handler.OnUndelete(Trigger.new);          
    }
}