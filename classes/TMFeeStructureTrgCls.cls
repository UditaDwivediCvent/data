/*
//////////////////////////////////////
//      @author Abhishek Pandey     //
/////////////////////////////////////
Version :   1.0
Date : 23rd Feb 2014
*/
public class TMFeeStructureTrgCls {
    
    public void OnBeforeInsert(List<TM_Fee_Structure__c> newValues){
        Set<Id> setOppId = new Set<Id>();
        for(TM_Fee_Structure__c instOfTMFS : newValues){
            if(instOfTMFS.Opportunity__c != null)
            setOppId.add(instOfTMFS.Opportunity__c);
        }
        
        map<Id,Opportunity> maplstOpp = new map<Id,Opportunity>();
        
        if(setOppId.size()>0)
        maplstOpp = new map<Id,Opportunity>([SELECT ID,CurrencyIsoCode,Exchange_Rate__c FROM Opportunity WHERE Id =: setOppId]);
        
        for(TM_Fee_Structure__c instOfTMFS : newValues){
            if(maplstOpp.containsKey(instOfTMFS.Opportunity__c)){
                instOfTMFS.CurrencyIsoCode = maplstOpp.get(instOfTMFS.Opportunity__c).CurrencyIsoCode;
                instOfTMFS.Exchange_Rate__c = maplstOpp.get(instOfTMFS.Opportunity__c).Exchange_Rate__c;
            }
        }
    }
    public void OnAfterInsert(Map<Id,TM_Fee_Structure__c> newMapValues){
        
    }
    public void OnBeforeUpdate(Map<Id,TM_Fee_Structure__c> oldMapValues,Map<Id,TM_Fee_Structure__c> newMapValues){
        
    }
    public void OnAfterUpdate(Map<Id,TM_Fee_Structure__c> oldMapValues,Map<Id,TM_Fee_Structure__c> newMapValues){
        
    }
    public void OnBeforeDelete(List<TM_Fee_Structure__c> oldValues,Map<Id,TM_Fee_Structure__c> oldMapValues){        
        
    }
    public void OnAfterDelete(List<TM_Fee_Structure__c> oldValues,Map<Id,TM_Fee_Structure__c> oldMapValues){
        
    }
    public void OnUndelete(List<TM_Fee_Structure__c> newValues){
        
    }
}