public class BookingClassificationHandler{
    public static void onAfterInsert(Map<Id,Booking_Classification__c> newMap){
        System.debug('Inside Method Insert');
        if(BookingClassification_CheckRecursive.runAfterInsert())
            passOpportunityId(newMap);
    }
    public static void onAfterUpdate(Map<Id,Booking_Classification__c> oldMap,Map<Id,Booking_Classification__c> newMap){
        System.debug('Inside Method Update');
        if(BookingClassification_CheckRecursive.runAfterUpdate())
            passOpportunityId(newMap);
    }
    public static void onAfterDelete(Map<Id,Booking_Classification__c> oldMap){
        System.debug('Inside Method Delete');
        if(BookingClassification_CheckRecursive.runAfterDelete())
            passOpportunityId(oldMap);
    }
    
    public static void passOpportunityId(Map<Id,Booking_Classification__c> newMap){
        Set<Id> opportunityIdSet = new Set<Id>();//Opportunity Id Set......
        For(Booking_Classification__c BCTRec : newMap.values())
        {
            opportunityIdSet.add(BCTRec.Opportunity__c);
        }
        if(opportunityIdSet.size()>0)
        {
            RollUpBCTValuesToOpportunity(opportunityIdSet);
        }
    }
    /*Roll up Actual Amount up for Renewal & Total NBB Value value on Opportunity from BCT*/
    //@future
    public static void RollUpBCTValuesToOpportunity(Set<Id> opportunityIdSet){//
        //Set<Id> opportunityIdSet = new Set<Id>();//Opportunity Id Set......
        Map<Id,Decimal> opportunityVsAARValue = new Map<Id,Decimal>();
        Map<Id,Decimal> opportunityVsNBBValue = new Map<Id,Decimal>();
        Map<Id,Decimal> opportunityVsRenewalValue = new Map<Id,Decimal>();
        Map<Id,Decimal> opportunityVsMYDValue = new Map<Id,Decimal>();
        Map<Id,Decimal> opportunityVsOtherValue = new Map<Id,Decimal>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        Booking_Classification__c oldBCTRecords;
        Decimal ARRValue;
        Decimal NBBValue;
        //For After Update..................
        /*if(!oldMap.isEmpty()){
            For(Booking_Classification__c BCTRec : newMap.values())
            {
                oldBCTRecords = oldMap.get(BCTRec.Id);
                if(oldBCTRecords.UFR_Total__c )
            }
        }
        else{//For After Insert & Delete of the BCT...........
            
        }*/
        
        
        System.debug('opportunityIdSet**************'+opportunityIdSet);
        //if(opportunityIdSet.size()>0)
        //{
            For(Booking_Classification__c BCTQuery : [SELECT Opportunity__c,UFR__c,Total_NBB_Total__c,Renewal_Value_Total__c,MYD_Total__c,Others__c FROM Booking_Classification__c WHERE Opportunity__c IN : opportunityIdSet]){
                //ARR Value
                if(!opportunityVsAARValue.containsKey(BCTQuery.Opportunity__c))
                {
                     opportunityVsAARValue.put(BCTQuery.Opportunity__c,(BCTQuery.UFR__c!=null?BCTQuery.UFR__c:0));                       
                }
                else{
                    opportunityVsAARValue.put(BCTQuery.Opportunity__c,(opportunityVsAARValue.get(BCTQuery.Opportunity__c)+(BCTQuery.UFR__c!=null?BCTQuery.UFR__c:0)));
                }
                //Total NBB Value..
                if(!opportunityVsNBBValue.containsKey(BCTQuery.Opportunity__c))
                {
                     opportunityVsNBBValue.put(BCTQuery.Opportunity__c,(BCTQuery.Total_NBB_Total__c!=null?BCTQuery.Total_NBB_Total__c:0));                       
                }
                else{
                    opportunityVsNBBValue.put(BCTQuery.Opportunity__c,(opportunityVsNBBValue.get(BCTQuery.Opportunity__c)+(BCTQuery.Total_NBB_Total__c!=null?BCTQuery.Total_NBB_Total__c:0)));
                }
            }
            System.debug('opportunityVsAARValue**************'+opportunityVsAARValue);
            System.debug('opportunityVsNBBValue**************'+opportunityVsNBBValue);
            For(Opportunity oppRec : [SELECT Id,Actual_Amount_Up_for_Renewal__c,Total_NBB_Values__c FROM Opportunity WHERE Id IN :opportunityIdSet]){
                Opportunity oppRecInsert = new Opportunity();
                if((opportunityVsAARValue.containsKey(oppRec.Id) && 
                opportunityVsAARValue.get(oppRec.Id)!=oppRec.Actual_Amount_Up_for_Renewal__c) ||
                (opportunityVsNBBValue.containsKey(oppRec.Id) &&            
                opportunityVsNBBValue.get(oppRec.Id)!=oppRec.Total_NBB_Values__c)){
                    System.debug('Inside If'+oppRec);
                    oppRecInsert = new Opportunity(Id = oppRec.Id);
                    if(opportunityVsAARValue.containsKey(oppRec.Id) && opportunityVsAARValue.get(oppRec.Id)!=oppRec.Actual_Amount_Up_for_Renewal__c)
                        oppRecInsert.Actual_Amount_Up_for_Renewal__c = opportunityVsAARValue.containsKey(oppRec.Id)?opportunityVsAARValue.get(oppRec.Id):0;
                    if(opportunityVsNBBValue.containsKey(oppRec.Id) && opportunityVsNBBValue.get(oppRec.Id)!=oppRec.Total_NBB_Values__c)
                        oppRecInsert.Total_NBB_Values__c = opportunityVsNBBValue.containsKey(oppRec.Id)?opportunityVsNBBValue.get(oppRec.Id):0;
                    opportunityList.add(oppRecInsert);
                }
                else if(oppRec.Actual_Amount_Up_for_Renewal__c != 0 || oppRec.Total_NBB_Values__c!=0){
                    System.debug('Inside else'+oppRec);
                    oppRecInsert = new Opportunity(Id = oppRec.Id);
                    if(oppRecInsert.Actual_Amount_Up_for_Renewal__c != 0)
                        oppRecInsert.Actual_Amount_Up_for_Renewal__c = 0;
                    if(oppRecInsert.Total_NBB_Values__c != 0)
                    oppRecInsert.Total_NBB_Values__c = 0;
                        opportunityList.add(oppRecInsert);
                }
                
            }
            System.debug('opportunityList**************'+opportunityList);
            if(opportunityList.size()>0)
                update opportunityList;
        //}
    }
}