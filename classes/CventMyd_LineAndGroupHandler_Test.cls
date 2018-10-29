@isTest(SeeAllData=false)

private class CventMyd_LineAndGroupHandler_Test {

//  private static testMethod void testTestVariables() {
        
//         // cLAG.GroupWrapper gW = new cLAG.GroupWrapper();
//         // cLAG.QuoteLineWrapper qlW = new cLAG.QuoteLineWrapper();
        
//         Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();
//      Id ChildRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();
       
//      Account TestAccount = new Account();
//         TestAccount.Name = 'Test Account';
//         insert TestAccount;
        
//         Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
//         opp.CurrencyIsoCode  = 'USD';
//         opp.AccountId = TestAccount.Id;
//         insert opp;

        
//         //Parent Contract to have Parent_Contract_Term_Years__c, Upcoming_Renewal_Type__c, Parent_Contract_Term_Years__c
//         Contract ParentCont = new Contract();
//         ParentCont.AccountId = TestAccount.id;
//         ParentCont.Contract_Term_Years__c = '1';
//         ParentCont.RecordTypeId = RecordTypeId;
//         ParentCont.SBQQ__Opportunity__c = opp.id;
//         insert ParentCont;

        
//         //Normal Quote
//         //Try inserting a Quote SBQQ__Type__c == Renewal
//         SBQQ__Quote__c TestQuote = new SBQQ__Quote__c();
//         TestQuote.SBQQ__Opportunity2__c = opp.id;
//         TestQuote.Contract_Term_Years__c = '2';
//         TestQuote.SBQQ__Type__c = 'Renewal';
//         TestQuote.Current_Year__c = 1;
//         TestQuote.Contract_Term_Years__c = '2';
//         TestQuote.SBQQ__EndDate__c = System.today();
//         TestQuote.Contract_Executed__c = true;
//         //TestQuote.Multiple_Years_Commitment__c = true;
//         TestQuote.SBQQ__Type__c = 'Amendment';
//         TestQuote.jsonString__c = '{"startDate":"2018-04-17","settings":{"preCalculationFieldNames":["SBQQ__Quantity__c","SBQQ__Discount__c","Custom_Discount__c","Discount_Type__c","SBQQ__AdditionalDiscount__c","Rate__c","Zone_Level__c","Number_of_Guest_Rooms__c","Lanyon_Chain_Affiliation__c","Chain_Affiliation__c","Setup_Days__c","Travel_Days__c","Event_Start_Date__c","Event_End_Date__c","Attendees__c","OnArrival_360_Event_Selection__c"],"calculatedFieldNames":["SBQQ__OriginalPrice__c","SBQQ__ListPrice__c","SBQQ__RegularPrice__c","SBQQ__NetPrice__c","Rack_Rate__c"],"msAtLastUpdate":1525180814312},"outyearMap":{"2":{"year":2,"startDate":"2019-04-17","endDate":"2020-04-16"},"3":{"year":3,"startDate":"2020-04-17","endDate":"2021-04-16"},"4":{"year":4,"startDate":"2021-04-17","endDate":"2022-04-16"},"5":{"year":5,"startDate":"2022-04-17","endDate":"2023-04-16"}},"isManuallyCreatedFirstYear":null,"endDate":"2019-04-16","automationStage":{"renewalStage":null,"codeStatus":"CALCULATION_CYCLE_FINISHED"}}';
//         insert TestQuote;
        
//         SBQQ__QuoteLineGroup__c newQuoteLineGroup = new SBQQ__QuoteLineGroup__c(
//             Name = 'Group 1',
//             SBQQ__Number__c = 1,
//             groupType__c = 'Proposal Comparison Group',
//             SBQQ__ListTotal__c = 0,
//             SBQQ__CustomerTotal__c = 0,
//             SBQQ__NetTotal__c = 0,
//             SBQQ__Quote__c = TestQuote.id);
        
//         Product2 prod = new Product2(Name = 'Laptop X200',
//                                      Family = 'Hardware');
//         insert prod;

//         Id pricebookId = Test.getStandardPricebookId();
        
//         PricebookEntry standardPrice = new PricebookEntry(
//             Pricebook2Id = pricebookId, Product2Id = prod.Id,
//             UnitPrice = 10000, IsActive = true);
//         insert standardPrice;

//         SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c(
//             Account_Name__c = opp.accountId,
//             SBQQ__Product__c = prod.Id,
//             SBQQ__Quantity__c = 1,
//             SBQQ__Quote__c = TestQuote.Id
//             );
            
//         TestQuote.Multiple_Years_Commitment__c = true;
//         update TestQuote;
        
        
//         CventMyd_LineAndGroupHandler cLAG = new CventMyd_LineAndGroupHandler();
//         Map<String,Opportunity> testOpp = new Map<String,Opportunity>();
//         testOpp.put(opp.Id,opp);
//         quoteObject qqqq = new quoteObject();
//         qqqq.insertionId = opp.Id;
//         CventMyd_QuoteTriggerHandler.quoteInsertionIdToOpportunity = testOpp;
//         CventMyd_LineAndGroupHandler.QuoteWrapper qW = new CventMyd_LineAndGroupHandler.QuoteWrapper(TestQuote);
//         CventMyd_LineAndGroupHandler.GroupWrapper gW = new CventMyd_LineAndGroupHandler.GroupWrapper(newQuoteLineGroup);
//         CventMyd_LineAndGroupHandler.QuoteLineWrapper qLW = new CventMyd_LineAndGroupHandler.QuoteLineWrapper(newQuoteLine,TestQuote.Id);
//         //cLAG.groupCurrentYearQuoteLines(new Set<Id>{TestQuote.Id});
//         //cLAG.groupCurrentYearQuoteLines(new Set<Id>{TestQuote.Id});
//  }
    
    private static testMethod void testFunction() {
        // Id profId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' limit 1].Id;
        // Id roleId = [SELECT Id FROM UserRole WHERE Name = 'Administrator' limit 1].Id;
        // User newUser = new User(
        //     LastName = 'Test', 
        //     FirstName = 'Test',
        //     CommunityNickname = 'test', 
        //     Username = 'Test@testohno.com', 
        //     Email = 'Test@testohno.com', 
        //     UserRoleId = roleId, 
        //     ProfileId = profId, 
        //     Validation_Bypass__c = true,
        //     Alias = 'TT',
        //     TimeZoneSidKey = 'America/New_York',
        //     LocaleSidKey = 'en_US',
        //     EmailEncodingKey = 'UTF-8',
        //     LanguageLocaleKey = 'en_US'
        //     );
        // insert newUser;
        // System.runAs(newUser){
            Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();
        //Id ChildRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();
       
       // Account TestAccount = new Account();
    //     TestAccount.Name = 'Test Account';
    //     insert TestAccount;
        
    //     Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
    //     opp.CurrencyIsoCode  = 'USD';
    //     opp.AccountId = TestAccount.Id;
        
    //     insert opp;
        
        //Create product/Pricebook entry/standard pricebook
        // Product2 prod = new Product2(
        //     Name = 'Laptop X200',
        //     Family = 'Hardware',
        //     Revenue_Type__c = 'Non-Recurring');
        // insert prod;

        // Id pricebookId = Test.getStandardPricebookId();
        
        // PricebookEntry standardPrice = new PricebookEntry(
        //     Pricebook2Id = pricebookId, Product2Id = prod.Id,
        //     UnitPrice = 10000, IsActive = true);
        // insert standardPrice;
        
        //Normal Quote
        //Try inserting a Quote SBQQ__Type__c == Renewal
        // SBQQ__Quote__c TestQuote = new SBQQ__Quote__c();
        // TestQuote.SBQQ__Opportunity2__c = opp.id;
        // TestQuote.Contract_Term_Years__c = '2';
        // TestQuote.SBQQ__Type__c = 'Amendment'; 
        // TestQuote.Current_Year__c = 1;
        // TestQuote.Contract_Term_Years__c = '2';
        // TestQuote.SBQQ__EndDate__c = Date.newInstance(System.Today().year()+20, 03, 03);
        // TestQuote.Contract_Executed__c  = true;
        // TestQuote.Multiple_Years_Commitment__c = true;
        //TestQuote.SBQQ__Type__c = 'Amendment';
        //TestQuote.jsonString__c = '{"startDate":"2018-04-17","settings":{"preCalculationFieldNames":["SBQQ__Quantity__c","SBQQ__Discount__c","Custom_Discount__c","Discount_Type__c","SBQQ__AdditionalDiscount__c","Rate__c","Zone_Level__c","Number_of_Guest_Rooms__c","Lanyon_Chain_Affiliation__c","Chain_Affiliation__c","Setup_Days__c","Travel_Days__c","Event_Start_Date__c","Event_End_Date__c","Attendees__c","OnArrival_360_Event_Selection__c"],"calculatedFieldNames":["SBQQ__OriginalPrice__c","SBQQ__ListPrice__c","SBQQ__RegularPrice__c","SBQQ__NetPrice__c","Rack_Rate__c"],"msAtLastUpdate":1525180814312},"outyearMap":{"2":{"year":2,"startDate":"2019-04-17","endDate":"2020-04-16"},"3":{"year":3,"startDate":"2020-04-17","endDate":"2021-04-16"},"4":{"year":4,"startDate":"2021-04-17","endDate":"2022-04-16"},"5":{"year":5,"startDate":"2022-04-17","endDate":"2023-04-16"}},"isManuallyCreatedFirstYear":null,"endDate":"2019-04-16","automationStage":{"renewalStage":null,"codeStatus":"CALCULATION_CYCLE_FINISHED"}}';
        // TestQuote.jsonString__c='{"startDate":"2018-04-17","settings":{"preCalculationFieldNames":["SBQQ__Quantity__c","SBQQ__Discount__c","Custom_Discount__c","Discount_Type__c","SBQQ__AdditionalDiscount__c","Rate__c","Zone_Level__c","Number_of_Guest_Rooms__c","Lanyon_Chain_Affiliation__c","Chain_Affiliation__c","Setup_Days__c","Travel_Days__c","Event_Start_Date__c","Event_End_Date__c","Attendees__c","OnArrival_360_Event_Selection__c"],"calculatedFieldNames":["SBQQ__OriginalPrice__c","SBQQ__ListPrice__c","SBQQ__RegularPrice__c","SBQQ__NetPrice__c","Rack_Rate__c"],"msAtLastUpdate":1525180814312},"outyearMap":{"2":{"year":2,"startDate":"2019-04-17","endDate":"2020-04-16"}},"isManuallyCreatedFirstYear":null,"endDate":"2019-04-16","automationStage":{"renewalStage":null,"codeStatus":"CALCULATION_CYCLE_FINISHED"}}';
        // insert TestQuote;
        
        // TestQuote.SBQQ__EndDate__c = Date.newInstance(System.Today().year()+22, 03, 03);
        // update TestQuote;
        //create quote line group
        // SBQQ__QuoteLineGroup__c newQuoteLineGroup = new SBQQ__QuoteLineGroup__c(
        //     Name = 'Group 1',
        //     SBQQ__Number__c = 1,
        //     groupType__c = 'Proposal Comparison Group',
        //     SBQQ__ListTotal__c = 0,
        //     SBQQ__CustomerTotal__c = 0,
        //     SBQQ__NetTotal__c = 0,
        //     SBQQ__Quote__c = TestQuote.id);
        // insert newQuoteLineGroup;
        
        // SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c(
        //     Account_Name__c = opp.accountId,
        //     SBQQ__Product__c = prod.Id,
        //     SBQQ__Quantity__c = 1,
        //     SBQQ__Quote__c = TestQuote.Id
        //     );
            
        // insert newQuoteLine;
        
        
        //Parent Contract to have Parent_Contract_Term_Years__c, Upcoming_Renewal_Type__c, Parent_Contract_Term_Years__c
        // Contract ParentCont = new Contract();
        // ParentCont.AccountId = opp.accountId;
        // ParentCont.Contract_Term_Years__c = '1';
        // ParentCont.RecordTypeId = RecordTypeId;
        // ParentCont.SBQQ__Opportunity__c = opp.id;
        // insert ParentCont;
    
    /*

        test.startTest();
        List<SBQQ__Quote__c> testQuote1 = new List<SBQQ__Quote__c>();
        
        //system.debug('testQuote>>>>>>>>>>>>>>>>>>>>>'+testQuote1);
        //testQuote1.Quote_Title__c = 'this is a quote title test';
        
        
        //CventMyd_LineAndGroupHandler.getQuoteLinesToDeleteOnTermRenewal(new List<SBQQ__Quote__c>{TestQuote});
        Map<Id,SBQQ__QuoteLine__c> quoteLineMap = new Map<Id,SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c eachQuoteLine:[SELECT Id,SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Optional__c = true]){
            quoteLineMap.put(eachQuoteLine.SBQQ__Quote__c ,eachQuoteLine);
            
        }
        for(SBQQ__Quote__c eachQUote: [SELECT SBQQ__LineItemCount__c,SBQQ__Type__c,previousQuoteLineCount__c,previousQuoteNonOptionalLineCount__c, jsonString__c FROM SBQQ__Quote__c WHERE (SBQQ__Type__c ='Amendment' OR SBQQ__Type__c ='Renewal' ) AND Multiple_Years_Commitment__c = true AND ID ='aFXm00000008PQhGAM']){
            if(eachQUote.jsonString__c != null){
               String codeStatus = eachQUote.jsonString__c.substringAfter('"codeStatus":"');
               String outYearProcessing = eachQUote.jsonString__c.substringAfter('"outyearProcessingStage":"');
                
                //LAST_UPDATED_BY_TRIGGER
                //system.debug(beforeFreeTrial.contains('CALCULATION_CYCLE_FINISHED'));
                if(codeStatus.contains('LAST_UPDATED_BY_TRIGGER') && !outYearProcessing.contains('OUTYEAR_PROCESSING_COMPLETE')){
                    //if(eachQUote.previousQuoteLineCount__c-eachQUote.previousQuoteNonOptionalLineCount__c != 0){
                        system.debug('eachQUote.Id'+eachQUote.Id);
                    
                        testQuote1.add(eachQUote);
                    //}
                    
                } 
            }
    
    //system.debug(beforeFreeTrial.contains('LAST_UPDATED_BY_TRIGGER'));
        }
        for(SBQQ__Quote__c eachQuote:testQuote1){
            eachQuote.Quote_Title__c = 'this is a quote title test';
        }
        
        update testQuote1;
        test.stopTest();
        }

        */
        
    }
    
    private static testMethod void test1() {
                
        Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();
        Id ChildRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();

        SBQQ.TriggerControl.disable();
        
        Account TestAccount = new Account();
        TestAccount.Name = 'Test Account';
        TestAccount.BillingCountryCode = 'US';
        TestAccount.BillingStateCode = 'NY';
        TestAccount.BillingPostalCode = '4654';
        insert TestAccount;
        
        Opportunity opp0 = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp0.CurrencyIsoCode  = 'USD';
        opp0.AccountId = TestAccount.id;
        insert opp0;
        
        /*
        Account TestAccount = TestUtil.createAccount('Test Account', 'Biz A/c');
        insert TestAccount;
        */

        SBQQ__Quote__c testQuote0 = new SBQQ__Quote__c();
        testQuote0.SBQQ__Opportunity2__c = opp0.id;
        testQuote0.SBQQ__Type__c = 'Quote';
        testQuote0.Current_Year__c = 1;
        testQuote0.Contract_Term_Years__c = '3';
        testQuote0.SBQQ__StartDate__c = System.today();
        testQuote0.SBQQ__EndDate__c = testQuote0.SBQQ__StartDate__c.addMonths(12);
        testQuote0.Contract_Executed__c = true;
        testQuote0.Multiple_Years_Commitment__c = true;

        insert testQuote0;

        List<SBQQ__QuoteLineGroup__c> groups = new List<SBQQ__QuoteLineGroup__c>();

        for(Integer i = 1; i <=3; i++) {

            SBQQ__QuoteLineGroup__c qlGroup = new SBQQ__QuoteLineGroup__c();
            qlGroup.Name = 'Group ' + String.valueOf(i);
            qlGroup.SBQQ__Number__c = i;
            qlGroup.SBQQ__ListTotal__c = 10;
            qlGroup.SBQQ__NetTotal__c = 100;
            qlGroup.SBQQ__CustomerTotal__c = 1000;
            qlGroup.SBQQ__Quote__c = testQuote0.id;
            qlGroup.term__c = (Decimal)i;  
            groups.add(qlGroup);

        }

        insert(groups);

        testQuote0.SBQQ__Opportunity2__c = opp0.Id;

        update testQuote0;

        //Product
        Product2 product1 = new Product2();
        product1.Name = 'Product 1';
        product1.Contract_Output_Grouping__c = 'Bundle Advertisements';
        product1.Revenue_Type__c = 'Non-Recurring';
        insert product1;   

        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

        for(SBQQ__QuoteLineGroup__c qlg : groups) {
        
            //Insert Quote Line
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Quantity__c = 1;
            ql.SBQQ__Product__c = product1.Id;
            ql.SBQQ__ListPrice__c = 10;
            ql.SBQQ__NetPrice__c = 10;
            ql.Rack_Rate__c = 10;
            ql.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            ql.SBQQ__Number__c = 1;
            ql.SBQQ__Group__c = qlg.id;
            ql.SBQQ__Quote__c = testQuote0.Id;
            ql.Notes__c = 'abc';
            ql.jsonString__c = JSON.serialize(getTestQuoteLineObject());
            quoteLines.add(ql);

        }

        insert quoteLines;
        
        //Parent Contract to have Parent_Contract_Term_Years__c, Upcoming_Renewal_Type__c, Parent_Contract_Term_Years__c

        Contract ParentCont = new Contract();
        ParentCont.AccountId = TestAccount.id;
        ParentCont.Contract_Term_Years__c = '3';
        ParentCont.RecordTypeId = RecordTypeId;
        ParentCont.SBQQ__Opportunity__c = opp0.id;
        insert ParentCont;
        
        //Child Contract
        Contract cont = new Contract();
        cont.RecordTypeId = ChildRecordTypeId;
        cont.AccountId = TestAccount.id;
        cont.Parent_Contract__c = ParentCont.id;
        //cont.Upcoming_Renewal_Type__c = 'Contract Renewal';
        cont.EndDate = System.today();
        //cont.Remaining_Master_Term__c = 0;
        cont.Current_Year__c = 1;
        cont.Multiple_Years_Commitment__c = true;
        cont.SBQQ__RenewalQuoted__c = true;
        cont.SBQQ__Quote__c = testQuote0.Id;

        insert cont;

        System.debug('childContract.Id: ' + cont.Id);

        System.debug('childContract currentYear0 : ' + cont.Current_Year__c);

        Opportunity opp1 = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp1.CurrencyIsoCode  = 'USD';
        opp1.AccountId = TestAccount.id;

        
        insert opp1;

        opp1.SBQQ__RenewedContract__c = cont.id;

        update opp1;

        System.debug('childContract currentYear1 : ' + cont.Current_Year__c);

        SBQQ.TriggerControl.enable();
        
        //Normal Quote
        //Try inserting a Quote SBQQ__Type__c == Renewal
        SBQQ__Quote__c testQuote1 = new SBQQ__Quote__c();
        testQuote1.SBQQ__Opportunity2__c = opp1.id;
        testQuote1.Contract_Term_Years__c = '2';
        testQuote1.SBQQ__Type__c = 'Renewal';
        testQuote1.Current_Year__c = 2;
        testQuote1.Contract_Term_Years__c = '3';
        testQuote1.SBQQ__EndDate__c = System.today();
        testQuote1.Contract_Executed__c = true;
        testQuote1.Multiple_Years_Commitment__c = true;
        
        Test.startTest();
        
        insert testQuote1;

        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c();
        ql1.SBQQ__Quantity__c = 1;
        ql1.SBQQ__Product__c = product1.Id;
        ql1.SBQQ__ListPrice__c = 10;
        ql1.SBQQ__NetPrice__c = 10;
        ql1.Rack_Rate__c = 10;
        ql1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        ql1.SBQQ__Number__c = 1;
        ql1.SBQQ__Quote__c = testQuote1.Id;
        ql1.Notes__c = 'abc';
        ql1.jsonString__c = JSON.serialize(getTestQuoteLineObject());

        insert ql1;

        Test.stopTest();
        
        
        //Insert Subscription
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Product__c = product1.id;
        sub.SBQQ__Account__c = TestAccount.id;
        sub.SBQQ__Contract__c = ParentCont.id;
        sub.SBQQ__Quantity__c = 1;
        // insert sub;
        
    }

    public static CventMyd_QuoteLineObject getTestQuoteLineObject() {

        CventMyd_QuoteLineObject quoteLineObject = new CventMyd_QuoteLineObject();

        quoteLineObject.qleId = CventMyd_UtilityMethods.getQleId();

        quoteLineObject.insertOnNextCurrentYear = false;

        quoteLineObject.deleteThisLine = false;

        quoteLineObject.preCalculationFieldValueMap = new Map<String,List<String>>();

        quoteLineObject.calculatedFieldValueMap = new Map<String,List<String>>();

        for(List<String> fieldNameList : CventMyd_Settings.fieldValueMapFieldNameLists) {

            Integer index = CventMyd_Settings.fieldValueMapFieldNameLists.indexOf(fieldNameList);

            for(String fieldName : fieldNameList) {

                if(index == 0) {

                    quoteLineObject.preCalculationFieldValueMap.put(fieldName, new List<String>());

                    quoteLineObject.preCalculationFieldValueMap.get(fieldName).add('dummyString');

                }

                else if(index == 1) {
                    
                    quoteLineObject.calculatedFieldValueMap.put(fieldName, new List<String>());

                    quoteLineObject.calculatedFieldValueMap.get(fieldName).add('dummyString');


                }

            }

        }

        quoteLineObject.nextYearQleId = CventMyd_UtilityMethods.getQleId();

        return quoteLineObject;


    }

}