/*------------------------------------------------------------------------------------------------------------------------------+
Simplus(info@Simplus.com)
Purpose: Finance Shells Trigger Handler
 
Details: Trigger Handler Framework
 
History:
06/26/2018 CJ Abreu
    -- Created
 

-------------------------------------------------------------------------------------------------------------------------------+*/
public class FinanceShellsTriggerHandler 
{
    //Public static Map<String,Decimal> mapCurrencyConv {get; set;}
    /*Public FinanceShellsTriggerHandler(){
       
    }*/
    public void handleAfterInsert(List<Finance_Shell__c> lstNewFinanceShells){
        if(!lstNewFinanceShells.isEmpty() && lstNewFinanceShells.size() > 0){
            List<Finance_Shell__c> lstActiveFinanceShells = new List<Finance_Shell__c>();
            for(Finance_Shell__c lstItr : lstNewFinanceShells){
                if(!lstItr.Contract_Expired__c){
                    lstActiveFinanceShells.add(lstItr);
                }
            }
            createFinanceBudget(lstNewFinanceShells);
            createUpdateFinanceCommission(lstActiveFinanceShells,false);
        }
    }

    public void handleAfterUpdate(List<Finance_Shell__c> lstNewFinanceShells){
        if(!lstNewFinanceShells.isEmpty() && lstNewFinanceShells.size() > 0){
            deleteFinanceBudget(lstNewFinanceShells);
            //deleteFinanceCommision(lstNewFinanceShells);
            createFinanceBudget(lstNewFinanceShells);
            createUpdateFinanceCommission(lstNewFinanceShells,true);
        }

    }

   // @future
  
    public static void createUpdateFinanceCommission(List<Finance_Shell__c> lstNewFinanceShells , Boolean isUpdate)
    {  
        if(isUpdate){
            Set<Id> setFinanceShell = new Set<Id>();
            String finCommIds = '';
            for(Finance_Shell__c lstItr : lstNewFinanceShells){
                setFinanceShell.add((String)lstItr.Id);
 
            }           
            String queryFinanceCommision = 'SELECT '+FinanceReportingQueryMaker.getQueryWithAllFields('Finance_Commission__c') +
                                            ' FROM Finance_Commission__c WHERE Finance_shell__c IN :setFinanceShell';
            List<Finance_Commission__c> lstFinanceCommision = Database.query(queryFinanceCommision);
            Database.DeleteResult[] delFinanceCommisions = Database.delete(lstFinanceCommision);
        }
        Set<Id> setQuoteIds = new Set<Id>();
        List<Finance_Commission__c> lstFinanceCommisions = new List<Finance_Commission__c>();
        Map<Id,Finance_Shell__c> mapShell = new Map<Id,Finance_Shell__c>();
        for(Finance_Shell__c lstItr : lstNewFinanceShells){     
            if(lstItr.Quote_ID__c != null){
                setQuoteIds.add(lstItr.Quote_ID__c);
                mapShell.put(lstItr.Quote_ID__c,lstItr);
            }           
        }
        System.debug('67--->' +setQuoteIds);
        List<SBQQ__QuoteLine__c> lstQuoteLines = [SELECT  Id,SBQQ__StartDate__c,SBQQ__Quote__c,SBQQ__Product__c,SBQQ__ProductCode__c,SBQQ__RequiredBy__c,
                                                          SBQQ__Discount__c,
                                                          SBQQ__EffectiveQuantity__c,
                                                          SBQQ__EndDate__c,
                                                          SBQQ__ListPrice__c,
                                                          SBQQ__NetTotal__c,
                                                          SBQQ__Quantity__c,
                                                          SBQQ__TotalDiscountRate__c,
                                                          SBQQ__ListTotal__c,
                                                          Cloned_from_Quote_Line__c,
                                                          Rack_Rate__c,
                                                          term__c,
                                                          SBQQ__ProductFamily__c,
                                                          SBQQ__NetPrice__c,
                                                          SBQQ__Quote__r.Contract_Term_Years__c,
                                                          SBQQ__Quote__r.Current_Year__c,
                                                          SBQQ__Quote__r.Multiple_Years_Commitment__c,
                                                          Revenue_Type__c,
                                                          SBQQ__EffectiveEndDate__c,
                                                          SBQQ__EffectiveStartDate__c,
                                                          SBQQ__Quote__r.CurrencyIsoCode,
                                                          SBQQ__Group__c,
                                                          SBQQ__RenewedSubscription__c,
                                                          SBQQ__UpgradedSubscription__c,
                                                          SBQQ__UpgradedSubscription__r.SBQQ__QuoteLine__r.SBQQ__NetTotal__c,
                                                          jsonString__c,
                                                          SBQQ__Quote__r.jsonString__c,
                                                          SBQQ__Quote__r.SBQQ__EndDate__c,
                                                          SBQQ__Quote__r.SBQQ__StartDate__c,
                                                          SBQQ__Quote__r.Contract_Extension__c
                                                          FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :setQuoteIds ORDER BY term__c ASC];
        Map<Id,SBQQ__QuoteLine__c> mapKeyGen = new Map<Id,SBQQ__QuoteLine__c>();
        Map<Id,String> mapUniqueId = new Map<Id,String>();
        lstQuoteLines.sort(); 
        System.debug('98--->' + mapUniqueId);
        System.debug('99--->' + lstQuoteLines.size());
        List<SBQQ__QuoteLine__c> lstUnsortedLines = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c lstItr : lstQuoteLines){
            if(lstItr.SBQQ__RequiredBy__c!= null){
                mapKeyGen.put(lstItr.Id,lstItr);
            }
            if(lstItr.Cloned_from_Quote_Line__c == null && lstItr.SBQQ__Quote__r.Multiple_Years_Commitment__c && lstItr.jsonString__c!= null){
                CventMyd_QuoteLineObject quoteLineObject = new CventMyd_QuoteLineObject();
                quoteLineObject = (CventMyd_QuoteLineObject)JSON.deserialize(lstItr.jsonString__c,CventMyd_QuoteLineObject.class);
                List<String> lstClonedFromQleIds = quoteLineObject.clonedFromQleIds;
                System.debug(lstClonedFromQleIds);
        String key = '';
                Boolean isPresent = false;  
        if(lstClonedFromQleIds.size() == 0){
          key = quoteLineObject.qleId;
                   // isPresent = true;
                    mapUniqueId.put(lstItr.Id,quoteLineObject.qleId);
        }
        else {  
                     lstUnsortedLines.add(lstItr);
        }                         
                System.debug('120-->' + mapUniqueId);
            }            
        }

        if(lstUnsortedLines.size() > 0){
            for(SBQQ__QuoteLine__c lstItr : lstUnsortedLines){
                String key = '';
                 if(lstItr.Cloned_from_Quote_Line__c == null && lstItr.SBQQ__Quote__r.Multiple_Years_Commitment__c && lstItr.jsonString__c!= null){
                    CventMyd_QuoteLineObject quoteLineObject = new CventMyd_QuoteLineObject();
                    quoteLineObject = (CventMyd_QuoteLineObject)JSON.deserialize(lstItr.jsonString__c,CventMyd_QuoteLineObject.class);
                    List<String> lstClonedFromQleIds = quoteLineObject.clonedFromQleIds;
                    for(Id Itr : mapUniqueId.keySet()){
                        if(lstClonedFromQleIds.contains(mapUniqueId.get(Itr))){
                            key = mapUniqueId.get(Itr);                                                
                        }
                    }
                }
                mapUniqueId.put(lstItr.Id,key);
            }
        }
        System.debug('140-->' + mapUniqueId);
        Map<Id,Map<String,List<SBQQ__QuoteLine__c>>> mapQuoteLines = new Map<Id,Map<String,List<SBQQ__QuoteLine__c>>>();
        for(SBQQ__QuoteLine__c lstItr : lstQuoteLines){ 
             String productMapKey = (String)lstItr.SBQQ__ProductCode__c;
            if(lstItr.Cloned_from_Quote_Line__c == null && lstItr.SBQQ__Quote__r.Multiple_Years_Commitment__c){
                productMapKey+= ''+mapUniqueId.get(lstItr.Id);
            } 
            else {
                productMapKey += '' + lstItr.Cloned_from_Quote_Line__c;      
            }          
            if(lstItr.SBQQ__RequiredBy__c != null){
                productMapKey += getMapKey(lstItr.SBQQ__RequiredBy__c,mapKeyGen,productMapKey);
            }
            Map<String,List<SBQQ__QuoteLine__c>> mapProductLines = new Map<String,List<SBQQ__QuoteLine__c>>();                       
            if(mapQuoteLines.containsKey(lstItr.SBQQ__Quote__c)){
                mapProductLines = mapQuoteLines.get(lstItr.SBQQ__Quote__c);
                if(mapProductLines.containsKey(productMapKey)){
                    List<SBQQ__QuoteLine__c> lstYearQle =  mapProductLines.get(productMapKey);                    
                    lstYearQle.add(lstItr);
                    mapProductLines.put(productMapKey,lstYearQle);
                    mapQuoteLines.put(lstItr.SBQQ__Quote__c,mapProductLines);
                }
                else {
                    List<SBQQ__QuoteLine__c> lstProductLines = new  List<SBQQ__QuoteLine__c>();
                    lstProductLines.add(lstItr);
                    mapProductLines.put(productMapKey,lstProductLines);
                    mapQuoteLines.put(lstItr.SBQQ__Quote__c,mapProductLines);
                }
            }
            else {
                List<SBQQ__QuoteLine__c> lstProductLines = new  List<SBQQ__QuoteLine__c>();
                lstProductLines.add(lstItr);
                mapProductLines.put(productMapKey,lstProductLines);
                mapQuoteLines.put(lstItr.SBQQ__Quote__c,mapProductLines);
            }         
            
        }
        System.debug('177-->' + mapQuoteLines.size());
        //for(Finance_Commission__c lstItr : lstFinanceCommisions){
        for(Id lstItr : mapQuoteLines.keySet()){
           
                Map<String,List<SBQQ__QuoteLine__c>> mapProdutLines = mapQuoteLines.get(lstItr);
                System.debug('mapProdutLines-->' + mapProdutLines.size());
                for(String eachProduct : mapProdutLines.keySet()){
                    Finance_Commission__c  fcObj = new Finance_Commission__c();  
                    fcObj.Finance_shell__c =  mapShell.get(lstItr).Id;
                    fcObj.Close_Date__c =  mapShell.get(lstItr).Closed_Date__c;
                    fcObj.Total_Duration__c = mapShell.get(lstItr).Total_Duration__c;
                    fcObj.Type__c =  mapShell.get(lstItr).Opportunity_type__c;             
                    List<SBQQ__QuoteLine__c> lstQleRecords = mapProdutLines.get(eachProduct);                    
                    Integer iterator = Integer.valueOf(lstQleRecords[0].SBQQ__Quote__r.Current_Year__c);
                    System.debug('lstQleRecords-->' + lstQleRecords.size());
                    System.debug('SBQQ__Quote__r-->' + lstQleRecords[0].SBQQ__Quote__c);
                    CventMyd_QuoteObject quoteObject = new CventMyd_QuoteObject();
                    quoteObject = (CventMyd_QuoteObject)JSON.deserialize(lstQleRecords[0].SBQQ__Quote__r.jsonString__c,CventMyd_QuoteObject.class);
                    Boolean boo_ifGroup = lstQleRecords[0].SBQQ__Group__c==null?true:false;
                    for(SBQQ__QuoteLine__c eachQle : lstQleRecords){ 
                        if(boo_ifGroup)
                        {
                            fcObj = new Finance_Commission__c(); 
                            fcObj.Finance_shell__c =  mapShell.get(lstItr).Id;
                            fcObj.Close_Date__c =  mapShell.get(lstItr).Closed_Date__c;
                            fcObj.Total_Duration__c = mapShell.get(lstItr).Total_Duration__c;
                            fcObj.Type__c =  mapShell.get(lstItr).Opportunity_type__c; 
                            
                        }
                       // Decimal currRate = mapCurrencyConv.get(eachQle.SBQQ__Quote__r.CurrencyIsoCode);
                        if(eachQle.SBQQ__Quote__r.Multiple_Years_Commitment__c){ 
                            Integer index = Integer.valueOf(eachQle.term__c) - Integer.valueOf(eachQle.SBQQ__Quote__r.Current_Year__c)+1; 
                            if(iterator <=5){
                                if(index == 1){
                                     fcObj.put('Year_'+index+'_start_date__c',eachQle.SBQQ__Quote__r.SBQQ__StartDate__c);
                                     fcObj.put('Year_'+index+'_end_date__c',eachQle.SBQQ__Quote__r.SBQQ__EndDate__c);
                                }
                                else {
                                    if(quoteObject.outyearMap != null){ 
                                        Map<Integer,CventMyd_Outyear> outyearMap  = quoteObject.outyearMap;
                                        fcObj.put('Year_'+index+'_start_date__c',outyearMap.get(Integer.valueOf(eachQle.term__c)).startDate);
                                        fcObj.put('Year_'+index+'_end_date__c',outyearMap.get(Integer.valueOf(eachQle.term__c)).endDate);
                                    }
                                }
                                fcObj.put('Term_'+index+'__c',eachQle.term__c);        
                                fcObj.put('Quote_line_y'+index+'__c',eachQle.Id);  
                                fcObj.Product__c = eachQle.SBQQ__Product__c;
                                fcObj.CurrencyIsoCode= eachQle.SBQQ__Quote__r.CurrencyIsoCode;
                                fcObj.product_family__c = eachQle.SBQQ__ProductFamily__c;
                                fcObj.Product_Revenue_type__c = eachQle.Revenue_Type__c; 
                                fcObj.ProductCode__c = eachQle.SBQQ__ProductCode__c;
                                fcObj.Quote_Lookup__c = eachQle.SBQQ__Quote__c;                                
                                fcObj.VariableOptions__c = eachQle.SBQQ__Quote__r.Multiple_Years_Commitment__c;
                                fcObj.put('Year_'+index+'_discount__c',eachQle.SBQQ__Discount__c);
                                fcObj.put('Year_'+index+'_Compound_Discount__c',eachQle.SBQQ__TotalDiscountRate__c);
                                fcObj.put('Year_'+index+'_effective_Quantity__c',eachQle.SBQQ__EffectiveQuantity__c);
                                fcObj.put('Year_'+index+'_List_price__c',eachQle.SBQQ__ListPrice__c);
                                fcObj.put('Year_'+index+'_List_total__c',eachQle.SBQQ__ListTotal__c);
                                fcObj.put('Year_'+index+'_Net_Amount__c',(eachQle.SBQQ__NetTotal__c == null ? 0 : eachQle.SBQQ__NetTotal__c));
                                fcObj.put('Year_'+index+'_Net_Price__c',eachQle.SBQQ__NetPrice__c);
                                fcObj.put('Year_'+index+'_Quantity__c',eachQle.SBQQ__Quantity__c);
                                fcObj.put('Year_'+index+'_Rackrate__c',eachQle.Rack_Rate__c);
                                if(fcObj.Type__c == 'Renewal'){
                                    fcObj.Subscription__c = eachQle.SBQQ__RenewedSubscription__c;
                                }
                                else if(fcObj.Type__c == 'Amendment'){
                                    fcObj.Subscription__c = eachQle.SBQQ__UpgradedSubscription__c;
                                }

                               /* CventMyd_QuoteLineObject quoteLineObject = new CventMyd_QuoteLineObject();
                                quoteLineObject = (CventMyd_QuoteLineObject)JSON.deserialize(eachQle.jsonString__c,CventMyd_QuoteLineObject.class);
                                if( quoteLineObject.preCalculationFieldValueMap != null){
                                    System.debug('quoteLineObject.preCalculationFieldValueMap-->' + quoteLineObject.preCalculationFieldValueMap);
                                    Map<String,List<String>> preCalculationFieldValueMap = quoteLineObject.preCalculationFieldValueMap;
                                    if(preCalculationFieldValueMap.containsKey('SBQQ__StartDate__c')){
                                        if((preCalculationFieldValueMap.get('SBQQ__StartDate__c'))[0]!= null){
                                            fcObj.put('Year_'+index+'_start_date__c',Date.valueOf(preCalculationFieldValueMap.get('SBQQ__StartDate__c')[0]));
                                        }
                                        
                                    }
                                    if(preCalculationFieldValueMap.containsKey('SBQQ__EndDate__c')){
                                        if((preCalculationFieldValueMap.get('SBQQ__EndDate__c'))[0]!= null){
                                            fcObj.put('Year_'+index+'_end_date__c',Date.valueOf(preCalculationFieldValueMap.get('SBQQ__EndDate__c')[0]));
                                        }
                                    }
                                }*/
                                iterator++;
                            }
                        }  
                        else{
                            System.debug('Count 1');
                            Integer int_extensionNums = eachQle.SBQQ__Quote__r.Contract_Extension__c != null ? (Integer.valueOf(eachQle.SBQQ__Quote__r.Contract_Term_Years__c)-Integer.valueOf(eachQle.SBQQ__Quote__r.Contract_Extension__c)): Integer.valueOf(eachQle.SBQQ__Quote__r.Contract_Term_Years__c);
                            fcObj.Product__c = eachQle.SBQQ__Product__c; 
                            fcObj.product_family__c = eachQle.SBQQ__ProductFamily__c;  
                            fcObj.ProductCode__c = eachQle.SBQQ__ProductCode__c; 
                            fcObj.Quote_Lookup__c = eachQle.SBQQ__Quote__c;
                            fcObj.VariableOptions__c = eachQle.SBQQ__Quote__r.Multiple_Years_Commitment__c;
                            fcObj.CurrencyIsoCode= eachQle.SBQQ__Quote__r.CurrencyIsoCode;
                            Date dt_startDate = eachQle.SBQQ__EffectiveStartDate__c;
                            Date dt_endDate = eachQle.SBQQ__EffectiveEndDate__c;
                            for(Integer i=Integer.valueOf(eachQle.SBQQ__Quote__r.Current_Year__c);i<=Integer.valueOf(eachQle.SBQQ__Quote__r.Contract_Term_Years__c);i++){

                                Integer index = i-Integer.valueOf(eachQle.SBQQ__Quote__r.Current_Year__c)+1;
                                fcObj.put('Quote_line_y'+index+'__c',eachQle.Id);
                                fcObj.put('Term_'+index+'__c',i);                                
                                fcObj.put('Year_'+index+'_discount__c',eachQle.SBQQ__Discount__c); 
                                fcObj.put('Year_'+index+'_Compound_Discount__c',eachQle.SBQQ__TotalDiscountRate__c);                               
                                fcObj.put('Year_'+index+'_effective_Quantity__c',eachQle.SBQQ__EffectiveQuantity__c);                                
                                fcObj.put('Year_'+index+'_List_price__c',eachQle.SBQQ__ListPrice__c);
                                fcObj.put('Year_'+index+'_List_total__c',eachQle.SBQQ__ListTotal__c);
                                 if(index > int_extensionNums && int_extensionNums != Integer.valueOf(eachQle.SBQQ__Quote__r.Contract_Term_Years__c)){
                                    if(eachQle.SBQQ__UpgradedSubscription__c != null){
                                        fcObj.put('Year_'+index+'_Net_Amount__c',(eachQle.SBQQ__UpgradedSubscription__r.SBQQ__QuoteLine__r.SBQQ__NetTotal__c == null ? 0 : eachQle.SBQQ__UpgradedSubscription__r.SBQQ__QuoteLine__r.SBQQ__NetTotal__c ));
                                    }
                                }
                                else {
                                    fcObj.put('Year_'+index+'_Net_Amount__c',(eachQle.SBQQ__NetTotal__c == null ? 0 : eachQle.SBQQ__NetTotal__c));
                                }
                                fcObj.put('Year_'+index+'_Net_Price__c',eachQle.SBQQ__NetPrice__c);
                                fcObj.put('Year_'+index+'_Quantity__c',eachQle.SBQQ__Quantity__c);
                               // Date startDate =
                                fcObj.put('Year_'+index+'_end_date__c',dt_endDate);
                                fcObj.put('Year_'+index+'_start_date__c',dt_startDate);
                                Date newEndDate = dt_endDate;
                                dt_startDate = newEndDate.addDays(1);
                                dt_endDate = newEndDate.addYears(1);
                                
                                //fcObj.put('USD_Year_'+index+'_Rackrate__c',(eachQle.Rack_Rate__c)/ currRate);
                                fcObj.put('Year_'+index+'_Rackrate__c',eachQle.Rack_Rate__c);
                                if(fcObj.Type__c == 'Renewal'){
                                    fcObj.Subscription__c = eachQle.SBQQ__RenewedSubscription__c;
                                }
                                else if(fcObj.Type__c == 'Amendment'){
                                     fcObj.Subscription__c = eachQle.SBQQ__UpgradedSubscription__c;
                                } 

                            }                            
                        }
                        if(boo_ifGroup)
                        {
                            lstFinanceCommisions.add(fcObj);  
                        }                  
                    }
                    if(!boo_ifGroup)
                    {
                        lstFinanceCommisions.add(fcObj);  
                    } 
                }
           // }
        }

        try{
            System.debug(lstFinanceCommisions.size());
            insert lstFinanceCommisions;
        }
        catch(DMLException e){
            System.debug('Insert Error : Cause --> ' + e.getCause());
            System.debug('Insert Error : Line Number --> ' + e.getLineNumber());
            System.debug('Insert Error : Message --> ' + e.getMessage());
        }

    }

    public static String getMapKey(Id qlReqId, Map<Id,SBQQ__QuoteLine__c> mapQls, String mapKey){       
        if(mapQls.containsKey(qlReqId)){
            mapKey = mapQls.get(qlReqId).SBQQ__ProductCode__c;
            if(mapQls.get(qlReqId).SBQQ__RequiredBy__c != null){
                mapKey += getMapKey(mapQls.get(qlReqId).SBQQ__RequiredBy__c,mapQls,mapKey);
            }
        }
        else{
            System.debug('Key Not Found');
        }
        return mapKey;
    }

    /*public void deleteFinanceCommision(List<Finance_Shell__c> lstNewFinanceShells){
        Set<Id> setFinanceShell = new Set<Id>();
        for(Finance_Shell__c lstItr : lstNewFinanceShells){
            
            setFinanceShell.add(lstItr.Id);
        }
        String queryFinanceCommision = 'SELECT Id FROM Finance_Commission__c WHERE Finance_shell__c IN :setFinanceShell';
       // System.debug('queryFinanceCommision-->' + queryFinanceCommision);
        List<Finance_Commission__c> lstFinanceCommision = Database.query(queryFinanceCommision);
        Database.DeleteResult[] delFinanceCommisions = Database.delete(lstFinanceCommision);
        System.debug('Records Deleted');
    }*/
    
    public void deleteFinanceBudget(List<Finance_Shell__c> lstNewFinanceShells){
        Set<Id> setFinanceShell = new Set<Id>();
        for(Finance_Shell__c lstItr : lstNewFinanceShells){
            
            setFinanceShell.add(lstItr.Id);
        }
        String queryFinanceBudget = 'SELECT Id FROM Finance_Budget__c WHERE Finance_shell__c IN :setFinanceShell';
       // System.debug('queryFinanceBudget-->' + queryFinanceBudget);
        List<Finance_Budget__c> lstFinanceBudget = Database.query(queryFinanceBudget);
        Database.DeleteResult[] delFinanceBudget = Database.delete(lstFinanceBudget);
        System.debug('Records Deleted');
    }
    //@future
    public static void createFinanceBudget(List<Finance_Shell__c> lstNewFinanceShells)
    {
        //if it's none MYD 1 to many, if true 1 to 1
        Set<Id> setAllQuoteIds = new Set<Id>();
        Set<Id> setMYDQuoteIds = new Set<Id>();
        Set<Id> setNotMYDQuoteIds = new Set<Id>();
        Map<String, Finance_Shell__c> map_FS = new Map<String, Finance_Shell__c>();
        List<Finance_Budget__c> lst_FB = new List<Finance_Budget__c>();
        for(Finance_Shell__c lstItr : lstNewFinanceShells){ 
            if(lstItr.Variable_Options__c == true){
                setMYDQuoteIds.add(lstItr.Quote_ID__c);
            }
            else{
                setNotMYDQuoteIds.add(lstItr.Quote_ID__c);
            }
            setAllQuoteIds.add(lstItr.Quote_ID__c);
            map_FS.put(lstItr.Quote_ID__c, lstItr);
        }
        
        List<SBQQ__QuoteLine__c> lstQuoteLines = [SELECT Id,
                                                         SBQQ__Quote__c,
                                                         SBQQ__Product__c,
                                                         SBQQ__ProductCode__c,
                                                         SBQQ__ProductFamily__c,
                                                         SBQQ__RequiredBy__c,
                                                         SBQQ__Discount__c,
                                                         SBQQ__EffectiveQuantity__c,
                                                         SBQQ__EndDate__c,
                                                         SBQQ__StartDate__c,
                                                         SBQQ__ListPrice__c,
                                                         SBQQ__NetTotal__c,
                                                         SBQQ__Quantity__c,
                                                         SBQQ__TotalDiscountRate__c,
                                                         SBQQ__ListTotal__c,
                                                         Revenue_Type__c,
                                                         Rack_Rate__c,
                                                         SBQQ__AdditionalDiscount__c,
                                                         Cloned_from_Quote_Line__c,
                                                         term__c,
                                                         SBQQ__Quote__r.SBQQ__EndDate__c,
                                                         SBQQ__Quote__r.SBQQ__StartDate__c,
                                                         SBQQ__NetPrice__c,
                                                         SBQQ__Quote__r.Contract_Term__c,
                                                         SBQQ__Quote__r.Contract_Term_Years__c,
                                                         SBQQ__Quote__r.Current_Year__c,
                                                         SBQQ__Quote__r.Multiple_Years_Commitment__c,
                                                         SBQQ__Quote__r.Contract_Remaining_Term__c,
                                                         SBQQ__Quote__r.SBQQ__Opportunity2__r.OwnerId,
                                                         SBQQ__Quote__r.CurrencyIsoCode,
                                                       SBQQ__Quote__r.Contract_Extension__c,
                                                         SBQQ__UpgradedSubscription__r.SBQQ__QuoteLine__r.SBQQ__NetTotal__c,
                                                         SBQQ__RequiredBy__r.SBQQ__Product__c,
                                                         SBQQ__EffectiveStartDate__c,
                                                         SBQQ__EffectiveEndDate__c,
                                                         SBQQ__Quote__r.jsonString__c,
                                                         jsonString__c
                                                    FROM SBQQ__QuoteLine__c 
                                                   WHERE SBQQ__Quote__c IN :setAllQuoteIds];
        Map<Id,Map<String,List<SBQQ__QuoteLine__c>>> mapQuoteLines = new Map<Id,Map<String,List<SBQQ__QuoteLine__c>>>();
        Map<String,List<SBQQ__QuoteLine__c>> mapProductLines = new Map<String,List<SBQQ__QuoteLine__c>>();
        for(SBQQ__QuoteLine__c lp : lstQuoteLines)
        {
            if(setMYDQuoteIds.contains(lp.SBQQ__Quote__c)){
                Date startDate = lp.SBQQ__EffectiveStartDate__c;
                Date endDate = lp.SBQQ__EffectiveEndDate__c;
                if(!Test.isRunningTest()){   
                    if(Integer.valueOf(lp.term__c)!=Integer.valueOf(lp.SBQQ__Quote__r.Current_Year__c)){
                        CventMyd_QuoteObject quoteObject = new CventMyd_QuoteObject();
                        quoteObject = (CventMyd_QuoteObject)JSON.deserialize(lp.SBQQ__Quote__r.jsonString__c,CventMyd_QuoteObject.class); 
                        if(quoteObject.outyearMap != null){
                            Map<Integer,CventMyd_Outyear> outyearMap  = quoteObject.outyearMap;
                            startDate = outyearMap.get(Integer.valueOf(lp.term__c)).startDate;
                            endDate = outyearMap.get(Integer.valueOf(lp.term__c)).endDate;
                        }
                    }  
                    else {
                        startDate = lp.SBQQ__Quote__r.SBQQ__StartDate__c;
                        endDate = lp.SBQQ__Quote__r.SBQQ__EndDate__c;
                    }                  
                }
                Finance_Budget__c newFB = updateFinanceBudget(lp, map_FS,startDate, endDate, lp.term__c, false,false);
                lst_FB.add(newFB);
            }
            else if(setNotMYDQuoteIds.contains(lp.SBQQ__Quote__c)){
                Decimal dec_term = lp.term__c;
                System.debug('lp.term__c;' + lp.term__c);
                //need to use Contract term year instead of contract remaining term
                //extension - Contract_Term_Years__c.. end point 
                CventMyd_QuoteObject quoteObject = new CventMyd_QuoteObject();
                quoteObject = (CventMyd_QuoteObject)JSON.deserialize(lp.SBQQ__Quote__r.jsonString__c,CventMyd_QuoteObject.class); 
                Date dt_startDate = lp.SBQQ__Quote__r.SBQQ__StartDate__c;
                Date dt_endDate = lp.SBQQ__Quote__r.SBQQ__EndDate__c;
                Integer int_extensionNums = lp.SBQQ__Quote__r.Contract_Extension__c != null ? (Integer.valueOf(lp.SBQQ__Quote__r.Contract_Term_Years__c)-Integer.valueOf(lp.SBQQ__Quote__r.Contract_Extension__c)): Integer.valueOf(lp.SBQQ__Quote__r.Contract_Term_Years__c);
                for(Integer i =(Integer)lp.SBQQ__Quote__r.Current_Year__c; i<= Integer.valueOf(lp.SBQQ__Quote__r.Contract_Term_Years__c); i++) {
                    Finance_Budget__c newFB = new Finance_Budget__c(); 
                    if(i != (Integer)lp.SBQQ__Quote__r.Current_Year__c){
                        if(quoteObject.outyearMap != null){
                            Map<Integer,CventMyd_Outyear> outyearMap  = quoteObject.outyearMap;dt_startDate = outyearMap.get(Integer.valueOf(dec_term)).startDate;dt_endDate = outyearMap.get(Integer.valueOf(dec_term )).endDate;
                        }
                        if(i > int_extensionNums && int_extensionNums != Integer.valueOf(lp.SBQQ__Quote__r.Contract_Term_Years__c)){ newFB = updateFinanceBudget(lp, map_FS,dt_startDate, dt_endDate, dec_term, true,true);}else{ newFB = updateFinanceBudget(lp, map_FS,dt_startDate, dt_endDate, dec_term, false, true); }
                         
                    }
                    else {
                        if(i > int_extensionNums && int_extensionNums != Integer.valueOf(lp.SBQQ__Quote__r.Contract_Term_Years__c)){newFB = updateFinanceBudget(lp, map_FS,dt_startDate, dt_endDate, dec_term, true,false);} else{ newFB = updateFinanceBudget(lp, map_FS,dt_startDate, dt_endDate, dec_term, false, false);} dt_startDate = lp.SBQQ__Quote__r.SBQQ__StartDate__c; dt_endDate = lp.SBQQ__Quote__r.SBQQ__EndDate__c;

                    }
              //      if(i!=(Integer)lp.SBQQ__Quote__r.Current_Year__c){
                       
                 //   }
                    dec_term =  dec_term+1; lst_FB.add(newFB);
                }
            }             
        }
        if(lst_FB.size()>0){
            System.debug(lst_FB);
            upsert lst_FB;
        }
    }
   /* public static Finance_Budget__c updateFinanceBudget(SBQQ__QuoteLine__c lp, Map<String, Finance_Shell__c> map_FS, Date dt_startDate, Date dt_endDate, Decimal dec_term, Boolean boo_Extension)
    {
        Finance_Budget__c newFB = new Finance_Budget__c();
        newFB.Active_Contract_year__c = lp.SBQQ__Quote__r.Current_Year__c;
        //Decimal currRate = mapCurrencyConv.get(lp.SBQQ__Quote__r.CurrencyIsoCode);
        newFB.Compound_Discount__c = lp.SBQQ__TotalDiscountRate__c;
        newFB.Contract_Expired__c = map_FS.containsKey(lp.SBQQ__Quote__c) ? map_FS.get(lp.SBQQ__Quote__c).Contract_Expired__c : false;
        newFB.Contract_Received_Date__c = map_FS.containsKey(lp.SBQQ__Quote__c) ? map_FS.get(lp.SBQQ__Quote__c).Contract_Received_Date__c : null;
        newFB.Discount__c = lp.SBQQ__AdditionalDiscount__c;   
        newFB.Effective_Quantity__c = lp.SBQQ__EffectiveQuantity__c;
        newFB.End_Date__c = dt_endDate;//lp.SBQQ__EndDate__c; //In case of non variable this will be changing depending on for loop iterator
        newFB.Finance_Shell__c = map_FS.get(lp.SBQQ__Quote__c).Id;
        newFB.Full_Contract_End_Date__c = map_FS.containsKey(lp.SBQQ__Quote__c) ? map_FS.get(lp.SBQQ__Quote__c).Parent_Contract_End_Date__c : null;
        newFB.Full_Contract_Start_Date__c = map_FS.containsKey(lp.SBQQ__Quote__c) ? map_FS.get(lp.SBQQ__Quote__c).Parent_Contract_Start_Date__c : null;
        newFB.Full_contract_term__c = Integer.valueOf(lp.SBQQ__Quote__r.Contract_Term_Years__c);
        newFB.List_price__c = (lp.SBQQ__ListPrice__c);
        newFB.List_total__c = (lp.SBQQ__ListTotal__c);
        newFB.Net_Amount__c =boo_Extension ? lp.SBQQ__UpgradedSubscription__r.SBQQ__QuoteLine__r.SBQQ__NetTotal__c : (lp.SBQQ__NetTotal__c); //coming from condition boo_Extension  
        newFB.Net_Price__c = (lp.SBQQ__NetPrice__c);
        newFB.CurrencyIsoCode= lp.SBQQ__Quote__r.CurrencyIsoCode;
        newFB.Opportunity_Owner__c = lp.SBQQ__Quote__r.SBQQ__Opportunity2__r.OwnerId;
        newFB.Parent_product__c = lp.SBQQ__RequiredBy__r.SBQQ__Product__c;
        newFB.Product__c = lp.SBQQ__Product__c;
        newFB.ProductCode__c = lp.SBQQ__ProductCode__c;
        newFB.product_family__c = lp.SBQQ__ProductFamily__c;
        newFB.Product_Revenue_type__c = lp.Revenue_Type__c;
        newFB.Quantity__c = lp.SBQQ__Quantity__c;        //newFB.Quote__c = lp.SBQQ__Quote__c;//this is a formula field
        newFB.Quote_Line__c = lp.id;
        newFB.Rackrate__c = lp.Rack_Rate__c;
        newFB.Start_Date__c = dt_startDate;//lp.SBQQ__StartDate__c; //In case of non variable this will be changing depending on for loop iterator
        newFB.Term__c = dec_term;//lp.term__c; //In case of non variable this will be changing depending on for loop iterator
        newFB.Type__c = 'New';
        if(map_FS.get(lp.SBQQ__Quote__c).Opportunity_type__c =='Amendment') {
            newFB.Type__c = 'Amendment';
        } else if(map_FS.get(lp.SBQQ__Quote__c).Opportunity_type__c == 'Renewal') {
            newFB.Type__c = 'Renewal';
        }

        return newFB;
    }*/
    public static Finance_Budget__c updateFinanceBudget(SBQQ__QuoteLine__c lp, Map<String, Finance_Shell__c> map_FS, Date dt_startDate, Date dt_endDate, Decimal dec_term, Boolean boo_Extension, Boolean isProrated)
    {
        Finance_Budget__c newFB = new Finance_Budget__c();
        newFB.Active_Contract_year__c = lp.SBQQ__Quote__r.Current_Year__c;
        //Decimal currRate = mapCurrencyConv.get(lp.SBQQ__Quote__r.CurrencyIsoCode);
        newFB.Compound_Discount__c = lp.SBQQ__TotalDiscountRate__c;
        newFB.Contract_Expired__c = map_FS.containsKey(lp.SBQQ__Quote__c) ? map_FS.get(lp.SBQQ__Quote__c).Contract_Expired__c : false;
        newFB.Contract_Received_Date__c = map_FS.containsKey(lp.SBQQ__Quote__c) ? map_FS.get(lp.SBQQ__Quote__c).Contract_Received_Date__c : null;
        newFB.Discount__c = lp.SBQQ__AdditionalDiscount__c;   
        newFB.Effective_Quantity__c = lp.SBQQ__EffectiveQuantity__c;
        newFB.End_Date__c = dt_endDate;//lp.SBQQ__EndDate__c; //In case of non variable this will be changing depending on for loop iterator
        newFB.Finance_Shell__c = map_FS.get(lp.SBQQ__Quote__c).Id;
        newFB.Full_Contract_End_Date__c = map_FS.containsKey(lp.SBQQ__Quote__c) ? map_FS.get(lp.SBQQ__Quote__c).Parent_Contract_End_Date__c : null;
        newFB.Full_Contract_Start_Date__c = map_FS.containsKey(lp.SBQQ__Quote__c) ? map_FS.get(lp.SBQQ__Quote__c).Parent_Contract_Start_Date__c : null;
        newFB.Full_contract_term__c = Integer.valueOf(lp.SBQQ__Quote__r.Contract_Term_Years__c);
        if(isProrated == true){
            newFB.List_price__c = (lp.SBQQ__ListPrice__c );
            newFB.List_total__c = (lp.SBQQ__ListTotal__c);
          //  newFB.Net_Amount__c =boo_Extension ? (lp.SBQQ__UpgradedSubscription__r.SBQQ__QuoteLine__r.SBQQ__NetTotal__c ): (lp.SBQQ__NetTotal__c ); //coming from condition boo_Extension  
            if(boo_Extension){
                if(lp.SBQQ__NetTotal__c != 0 && lp.SBQQ__NetTotal__c!= null){
                    newFB.Net_Amount__c = lp.SBQQ__NetTotal__c;
                } 
                else if(lp.SBQQ__UpgradedSubscription__c != null ) {
                    newFB.Net_Amount__c = (lp.SBQQ__UpgradedSubscription__r.SBQQ__QuoteLine__r.SBQQ__NetTotal__c == null ? 0 : lp.SBQQ__UpgradedSubscription__r.SBQQ__QuoteLine__r.SBQQ__NetTotal__c);
                }
            }
            else {
                newFB.Net_Amount__c = (lp.SBQQ__NetTotal__c == null ? 0 : lp.SBQQ__NetTotal__c);
            }
            newFB.Net_Price__c = (lp.SBQQ__NetPrice__c );
        }
        else {
            newFB.List_price__c = (lp.SBQQ__ListPrice__c);
            newFB.List_total__c = (lp.SBQQ__ListTotal__c); 
            newFB.Net_Price__c = (lp.SBQQ__NetPrice__c);            
            newFB.Net_Amount__c = (lp.SBQQ__NetTotal__c == null ? 0 : lp.SBQQ__NetTotal__c);
           // newFB.CurrencyIsoCode= lp.SBQQ__Quote__r.CurrencyIsoCode;
        }        
        newFB.Opportunity_Owner__c = lp.SBQQ__Quote__r.SBQQ__Opportunity2__r.OwnerId;newFB.Parent_product__c = lp.SBQQ__RequiredBy__r.SBQQ__Product__c;newFB.Product__c = lp.SBQQ__Product__c;
        newFB.ProductCode__c = lp.SBQQ__ProductCode__c;newFB.product_family__c = lp.SBQQ__ProductFamily__c;newFB.Product_Revenue_type__c = lp.Revenue_Type__c;newFB.CurrencyIsoCode= lp.SBQQ__Quote__r.CurrencyIsoCode;newFB.Quantity__c = lp.SBQQ__Quantity__c;        //newFB.Quote__c = lp.SBQQ__Quote__c;//this is a formula field
        newFB.Quote_Line__c = lp.id;newFB.Rackrate__c = lp.Rack_Rate__c;newFB.Start_Date__c = dt_startDate;//lp.SBQQ__StartDate__c; //In case of non variable this will be changing depending on for loop iterator
        newFB.Term__c = dec_term;newFB.Type__c = 'New'; if(map_FS.get(lp.SBQQ__Quote__c).Opportunity_type__c =='Amendment') {
            newFB.Type__c = 'Amendment'; } else if(map_FS.get(lp.SBQQ__Quote__c).Opportunity_type__c == 'Renewal') {newFB.Type__c = 'Renewal'; }

        return newFB;
    }
}