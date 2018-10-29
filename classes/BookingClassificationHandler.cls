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
            if(BCTRec.Product_Family__c != 'Not Identified')
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
        Boolean addOpportunityInList;
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
                System.debug('BCTQuery.Renewal_Value_Total__c*************'+BCTQuery.Renewal_Value_Total__c);
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
                //Total Renewal Value..
                if(!opportunityVsRenewalValue.containsKey(BCTQuery.Opportunity__c))
                {
                     opportunityVsRenewalValue.put(BCTQuery.Opportunity__c,(BCTQuery.Renewal_Value_Total__c!=null?BCTQuery.Renewal_Value_Total__c:0));                       
                }
                else{
                    opportunityVsRenewalValue.put(BCTQuery.Opportunity__c,(opportunityVsRenewalValue.get(BCTQuery.Opportunity__c)+(BCTQuery.Renewal_Value_Total__c!=null?BCTQuery.Renewal_Value_Total__c:0)));
                }
                //Total MYD Value..
                if(!opportunityVsMYDValue.containsKey(BCTQuery.Opportunity__c))
                {
                     opportunityVsMYDValue.put(BCTQuery.Opportunity__c,(BCTQuery.MYD_Total__c!=null?BCTQuery.MYD_Total__c:0));                       
                }
                else{
                    opportunityVsMYDValue.put(BCTQuery.Opportunity__c,(opportunityVsMYDValue.get(BCTQuery.Opportunity__c)+(BCTQuery.MYD_Total__c!=null?BCTQuery.MYD_Total__c:0)));
                }
                //Total Other Value..
                if(!opportunityVsOtherValue.containsKey(BCTQuery.Opportunity__c))
                {
                     opportunityVsOtherValue.put(BCTQuery.Opportunity__c,(BCTQuery.Others__c!=null?BCTQuery.Others__c:0));                       
                }
                else{
                    opportunityVsOtherValue.put(BCTQuery.Opportunity__c,(opportunityVsOtherValue.get(BCTQuery.Opportunity__c)+(BCTQuery.Others__c!=null?BCTQuery.Others__c:0)));
                }
            }
            System.debug('opportunityVsAARValue**************'+opportunityVsAARValue);
            System.debug('opportunityVsNBBValue**************'+opportunityVsNBBValue);
            System.debug('opportunityVsRenewalValue**************'+opportunityVsRenewalValue);
            System.debug('opportunityVsOtherValue**************'+opportunityVsOtherValue);
            System.debug('opportunityVsMYDValue**************'+opportunityVsMYDValue);
            For(Opportunity oppRec : [SELECT Id,Actual_Amount_Up_for_Renewal__c,Total_NBB_Values__c,Total_MYD_Value__c,Total_Others_Value__c,Total_Renewal_Value__c FROM Opportunity WHERE Id IN :opportunityIdSet]){
                addOpportunityInList = FALSE;
                //Total Renewal
                if(opportunityVsRenewalValue.containsKey(oppRec.Id)){
                    if(opportunityVsRenewalValue.get(oppRec.Id)!=oppRec.Total_Renewal_Value__c){
                        System.debug('Inside Renewal if');
                        oppRec.Total_Renewal_Value__c = opportunityVsRenewalValue.containsKey(oppRec.Id)?opportunityVsRenewalValue.get(oppRec.Id):0;
                        addOpportunityInList = TRUE;
                        //opportunityList.add(oppRec);
                    }
                }
                else if(oppRec.Total_Renewal_Value__c != 0 ){
                    System.debug('Inside Renewal else');
                    oppRec.Total_Renewal_Value__c = 0;
                    addOpportunityInList = TRUE;
                    //opportunityList.add(oppRec);
                }
                //Total MYD
                if(opportunityVsMYDValue.containsKey(oppRec.Id)){
                    if(opportunityVsMYDValue.get(oppRec.Id)!=oppRec.Total_MYD_Value__c){
                        System.debug('Inside MYD if');
                        oppRec.Total_MYD_Value__c = opportunityVsMYDValue.containsKey(oppRec.Id)?opportunityVsMYDValue.get(oppRec.Id):0;
                        addOpportunityInList = TRUE;
                        //opportunityList.add(oppRec);
                    }
                }
                else if(oppRec.Total_MYD_Value__c != 0 ){
                    System.debug('Inside MYD else');
                    oppRec.Total_MYD_Value__c = 0;
                    addOpportunityInList = TRUE;
                    //opportunityList.add(oppRec);
                }
                
                //Total Other
                if(opportunityVsOtherValue.containsKey(oppRec.Id)){
                    if(opportunityVsOtherValue.get(oppRec.Id)!=oppRec.Total_Others_Value__c){
                        System.debug('Inside Other if');
                        oppRec.Total_Others_Value__c = opportunityVsOtherValue.containsKey(oppRec.Id)?opportunityVsOtherValue.get(oppRec.Id):0;
                        addOpportunityInList = TRUE;
                        //opportunityList.add(oppRec);
                    }
                }
                else if(oppRec.Total_Others_Value__c != 0 ){
                    System.debug('Inside Other else');
                    oppRec.Total_Others_Value__c = 0;
                    addOpportunityInList = TRUE;
                    //opportunityList.add(oppRec);
                }
                //Total ARR
                if(opportunityVsAARValue.containsKey(oppRec.Id)){
                    if(opportunityVsAARValue.get(oppRec.Id)!=oppRec.Actual_Amount_Up_for_Renewal__c){
                        System.debug('Inside ARR if');
                        oppRec.Actual_Amount_Up_for_Renewal__c = opportunityVsAARValue.containsKey(oppRec.Id)?opportunityVsAARValue.get(oppRec.Id):0;
                        addOpportunityInList = TRUE;
                        //opportunityList.add(oppRec);
                    }
                }
                else if(oppRec.Actual_Amount_Up_for_Renewal__c != 0 ){
                    System.debug('Inside ARR else');
                    oppRec.Actual_Amount_Up_for_Renewal__c = 0;
                    addOpportunityInList = TRUE;
                    //opportunityList.add(oppRec);
                }
                //Total NBB
                if(opportunityVsNBBValue.containsKey(oppRec.Id)){ 
                    if(opportunityVsNBBValue.get(oppRec.Id)!=oppRec.Total_NBB_Values__c){
                        System.debug('Inside Total if');
                        oppRec.Total_NBB_Values__c = opportunityVsNBBValue.containsKey(oppRec.Id)?opportunityVsNBBValue.get(oppRec.Id):0;
                        addOpportunityInList = TRUE;
                        //opportunityList.add(oppRec);
                    }
                }
                else if(oppRec.Total_NBB_Values__c!= 0 ){
                    System.debug('Inside Total Else');
                    oppRec.Total_NBB_Values__c = 0;
                    addOpportunityInList = TRUE;
                    //opportunityList.add(oppRec);
                }
                System.debug('addOpportunityInList ****'+addOpportunityInList );
                if(addOpportunityInList)
                    opportunityList.add(oppRec);
            }
            System.debug('opportunityList**************'+opportunityList);
            if(opportunityList.size()>0)
                update opportunityList;
        //}
    }
}