@isTest
private class CventMyd_QuoteTriggerHandler_Test {

    //Uses Quote type Renewal and Contract = Contract Renewal
	private static testMethod void BeforeInsert_test1() {
	    
	    Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();
	    Id ChildRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();
	   
        
        Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp.CurrencyIsoCode  = 'USD';
        insert opp;
        
        /*
        Account TestAccount = TestUtil.createAccount('Test Account', 'Biz A/c');
        insert TestAccount;
        */
        
        Account TestAccount = new Account();
        TestAccount.Name = 'Test Account';
        insert TestAccount;
        
        //Parent Contract to have Parent_Contract_Term_Years__c, Upcoming_Renewal_Type__c, Parent_Contract_Term_Years__c
        Contract ParentCont = new Contract();
        ParentCont.AccountId = TestAccount.id;
        ParentCont.Contract_Term_Years__c = '1';
        ParentCont.RecordTypeId = RecordTypeId;
        ParentCont.SBQQ__Opportunity__c = opp.id;
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
        insert cont;
        
        opp.SBQQ__RenewedContract__c = cont.id;
        update opp;
        
        //Normal Quote
        //Try inserting a Quote SBQQ__Type__c == Renewal
        SBQQ__Quote__c TestQuote = new SBQQ__Quote__c();
        TestQuote.SBQQ__Opportunity2__c = opp.id;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.SBQQ__Type__c = 'Renewal';
        TestQuote.Current_Year__c = 1;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.SBQQ__EndDate__c = System.today();
        TestQuote.Contract_Executed__c = true;
        insert TestQuote;
        
	}
	
	//Uses Quote type Renewal and Contract = MYD Renewal
	private static testMethod void BeforeInsert_test2() {
	    
	    Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();
	    Id ChildRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();
        
        Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp.CurrencyIsoCode  = 'USD';
        insert opp;
        
        /*
        Account TestAccount = TestUtil.createAccount('Test Account', 'Biz A/c');
        insert TestAccount;
        */
        
        Account TestAccount = new Account();
        TestAccount.Name = 'Test Account';
        insert TestAccount;
        
        //Parent Contract to have Parent_Contract_Term_Years__c, Upcoming_Renewal_Type__c, Parent_Contract_Term_Years__c
        Contract ParentCont = new Contract();
        ParentCont.AccountId = TestAccount.id;
        ParentCont.Contract_Term_Years__c = '5';
        ParentCont.RecordTypeId = RecordTypeId;
        ParentCont.SBQQ__Opportunity__c = opp.id;
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
        insert cont;
        
        opp.SBQQ__RenewedContract__c = cont.id;
        update opp;
        
        //Normal Quote
        //Try inserting a Quote SBQQ__Type__c == Renewal
        SBQQ__Quote__c TestQuote = new SBQQ__Quote__c();
        TestQuote.SBQQ__Opportunity2__c = opp.id;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.SBQQ__Type__c = 'Renewal';
        TestQuote.Current_Year__c = 1;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.SBQQ__EndDate__c = System.today();
        TestQuote.Contract_Executed__c = true;
        insert TestQuote;
        
	}
	
	//Quote type Amendment and Contract = 
	private static testMethod void BeforeInsert_test3() {
	    
	    Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();
	    Id ChildRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();
        
        Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp.CurrencyIsoCode  = 'USD';
        insert opp;
        
        Address__c addr = new Address__c();
        addr.Address__c = 'Test Address';
        addr.Type__c = 'Billing';
        insert addr;
        
        Opportunity opp2 = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp2.CurrencyIsoCode  = 'USD';
        opp2.Bill_To_Address__c = addr.id;
        insert opp2;
        
        /*
        Account TestAccount = TestUtil.createAccount('Test Account', 'Biz A/c');
        insert TestAccount;
        */
        
        Account TestAccount = new Account();
        TestAccount.Name = 'Test Account';
        insert TestAccount;
        
        //Parent Contract to have Parent_Contract_Term_Years__c, Upcoming_Renewal_Type__c, Parent_Contract_Term_Years__c
        Contract ParentCont = new Contract();
        ParentCont.AccountId = TestAccount.id;
        ParentCont.Contract_Term_Years__c = '1';
        ParentCont.RecordTypeId = RecordTypeId;
        ParentCont.SBQQ__Opportunity__c = opp.id;
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
        cont.SBQQ__Opportunity__c = opp2.id;
        insert cont;
        
        opp.SBQQ__AmendedContract__c = cont.id;
        update opp;
        
        //Normal Quote
        //Try inserting a Quote SBQQ__Type__c == Renewal
        SBQQ__Quote__c TestQuote = new SBQQ__Quote__c();
        TestQuote.SBQQ__Opportunity2__c = opp.id;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.SBQQ__Type__c = 'Amendment';
        TestQuote.Current_Year__c = 1;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.Contract_Executed__c = true;
        
        //Date newDate = System.today().addYears(1);
        
        TestQuote.SBQQ__StartDate__c = System.today().addYears(-1); //System.today().year() - 1;
        TestQuote.SBQQ__EndDate__c = System.today();
        insert TestQuote;
        
	}
	
	//Quote type Amendment and Contract = 
	private static testMethod void BeforeInsert_test4() {
	    
	    Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();
	    Id ChildRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();
        
        Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp.CurrencyIsoCode  = 'USD';
        insert opp;
        
        Address__c addr = new Address__c();
        addr.Address__c = 'Test Address';
        addr.Type__c = 'Billing';
        insert addr;
        
        Opportunity opp2 = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp2.CurrencyIsoCode  = 'USD';
        opp2.Bill_To_Address__c = addr.id;
        insert opp2;
        
        /*
        Account TestAccount = TestUtil.createAccount('Test Account', 'Biz A/c');
        insert TestAccount;
        */
        
        Account TestAccount = new Account();
        TestAccount.Name = 'Test Account';
        insert TestAccount;
        
        //Parent Contract to have Parent_Contract_Term_Years__c, Upcoming_Renewal_Type__c, Parent_Contract_Term_Years__c
        Contract ParentCont = new Contract();
        ParentCont.AccountId = TestAccount.id;
        ParentCont.Contract_Term_Years__c = '1';
        ParentCont.RecordTypeId = RecordTypeId;
        ParentCont.SBQQ__Opportunity__c = opp.id;
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
        cont.SBQQ__Opportunity__c = opp2.id;
        insert cont;
        
        opp.SBQQ__AmendedContract__c = cont.id;
        update opp;
        
        //Normal Quote
        //Try inserting a Quote SBQQ__Type__c == Renewal
        SBQQ__Quote__c TestQuote = new SBQQ__Quote__c();
        TestQuote.SBQQ__Opportunity2__c = opp.id;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.SBQQ__Type__c = 'Amendment';
        TestQuote.Current_Year__c = 1;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.Contract_Executed__c = true;
        
        //Date newDate = System.today().addYears(1);
        
        TestQuote.SBQQ__StartDate__c = System.today().addYears(-1); //System.today().year() - 1;
        TestQuote.SBQQ__EndDate__c = System.today();
        insert TestQuote;
        
        SBQQ__Quote__c TestQuote2 = new SBQQ__Quote__c();
        TestQuote2.SBQQ__Opportunity2__c = opp.id;
        TestQuote2.Contract_Term_Years__c = '2';
        TestQuote2.SBQQ__Type__c = 'Renewal';
        TestQuote2.Contract_Executed__c = true;
        TestQuote2.SBQQ__StartDate__c = System.today().addYears(-1);
        TestQuote2.SBQQ__EndDate__c = System.today();
        insert TestQuote2;
        
        cont.contractedAmendmentQuote__c = TestQuote2.id;
        update cont;
        
	}
	
	//Quote type Amendment and Contract = 
	private static testMethod void BeforeInsert_test5() {
	    
	    Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();
	    Id ChildRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();
        
        Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp.CurrencyIsoCode  = 'USD';
        insert opp;
        
        Address__c addr = new Address__c();
        addr.Address__c = 'Test Address';
        addr.Type__c = 'Billing';
        insert addr;
        
        Opportunity opp2 = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp2.CurrencyIsoCode  = 'USD';
        opp2.Bill_To_Address__c = addr.id;
        insert opp2;
        
        /*
        Account TestAccount = TestUtil.createAccount('Test Account', 'Biz A/c');
        insert TestAccount;
        */
        
        Account TestAccount = new Account();
        TestAccount.Name = 'Test Account';
        insert TestAccount;
        
        //Parent Contract to have Parent_Contract_Term_Years__c, Upcoming_Renewal_Type__c, Parent_Contract_Term_Years__c
        Contract ParentCont = new Contract();
        ParentCont.AccountId = TestAccount.id;
        ParentCont.Contract_Term_Years__c = '1';
        ParentCont.RecordTypeId = RecordTypeId;
        ParentCont.SBQQ__Opportunity__c = opp.id;
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
        cont.SBQQ__Opportunity__c = opp2.id;
        insert cont;
        
        opp.SBQQ__AmendedContract__c = cont.id;
        update opp;
        
        //Normal Quote
        //Try inserting a Quote SBQQ__Type__c == Renewal
        SBQQ__Quote__c TestQuote = new SBQQ__Quote__c();
        TestQuote.SBQQ__Opportunity2__c = opp.id;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.SBQQ__Type__c = 'Amendment';
        TestQuote.Current_Year__c = 1;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.Contract_Executed__c = true;
        
        //Date newDate = System.today().addYears(1);
        
        TestQuote.SBQQ__StartDate__c = System.today().addYears(-1); //System.today().year() - 1;
        TestQuote.SBQQ__EndDate__c = System.today();
        insert TestQuote;
        
        SBQQ__Quote__c TestQuote2 = new SBQQ__Quote__c();
        TestQuote2.SBQQ__Opportunity2__c = opp.id;
        TestQuote2.Contract_Term_Years__c = '2';
        TestQuote2.SBQQ__Type__c = 'Amendment';
        TestQuote2.Contract_Executed__c = true;
        TestQuote2.SBQQ__StartDate__c = System.today().addYears(-1);
        TestQuote2.SBQQ__EndDate__c = System.today();
        insert TestQuote2;
        
        cont.contractedAmendmentQuote__c = TestQuote2.id;
        update cont;
	}
	
	private static testMethod void testBatch() {
	    
	    Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();
	    
	    //Account
	    Account TestAccount = new Account();
        TestAccount.Name = 'Test Account';
        insert TestAccount;
	    
	    //Insert Opp
	    Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp.CurrencyIsoCode  = 'USD';
        insert opp;
    
        //Insert Quote
        SBQQ__Quote__c TestQuote = new SBQQ__Quote__c();
        TestQuote.SBQQ__Opportunity2__c = opp.id;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.SBQQ__Type__c = 'Renewal';
        TestQuote.Current_Year__c = 2;
        TestQuote.Contract_Executed__c = true;
        TestQuote.SBQQ__StartDate__c = System.today().addYears(-1);
        TestQuote.SBQQ__EndDate__c = System.today();
        TestQuote.createdFromLegacyContract__c = true;
        //TestQuote.Multiple_Years_Commitment__c = true;
        insert TestQuote;
        
        //Quote Line Group
        SBQQ__QuoteLineGroup__c qlGroup = new SBQQ__QuoteLineGroup__c();
        qlGroup.Name = 'Group 1';
        qlGroup.SBQQ__Number__c = 10;
        qlGroup.SBQQ__ListTotal__c = 10;
        qlGroup.SBQQ__NetTotal__c = 100;
        qlGroup.SBQQ__CustomerTotal__c = 1000;
        qlGroup.SBQQ__Quote__c = TestQuote.id;
        insert qlGroup;
        
        TestQuote.Multiple_Years_Commitment__c = true;
        update TestQuote;
        
        //Parent Contract to have Parent_Contract_Term_Years__c, Upcoming_Renewal_Type__c, Parent_Contract_Term_Years__c
        Contract ParentCont = new Contract();
        ParentCont.AccountId = TestAccount.id;
        ParentCont.Contract_Term_Years__c = '1';
        ParentCont.RecordTypeId = RecordTypeId;
        ParentCont.SBQQ__Opportunity__c = opp.id;
        insert ParentCont;
        
        //Product
        Product2 product1 = new Product2();
        product1.Name = 'Product 1';
        product1.Contract_Output_Grouping__c = 'Bundle Advertisements';
        insert product1;
        
        //Insert Subscription
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Product__c = product1.id;
        sub.SBQQ__Account__c = TestAccount.id;
        sub.SBQQ__Contract__c = ParentCont.id;
        sub.SBQQ__Quantity__c = 1;
        insert sub;
        
        //Insert Quote Line
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c();
        ql1.SBQQ__Quantity__c = 1;
        ql1.SBQQ__Product__c = product1.Id;
        ql1.SBQQ__ListPrice__c = 10;
        ql1.SBQQ__NetPrice__c = 10;
        ql1.Rack_Rate__c = 10;
        ql1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        ql1.SBQQ__Number__c = 1;
        ql1.SBQQ__Group__c = qlGroup.id;
        ql1.SBQQ__Quote__c = TestQuote.Id;
        ql1.Notes__c = 'abc';
        ql1.SBQQ__UpgradedSubscription__c = sub.id;
        insert ql1;
        
        //Quote2
        SBQQ__Quote__c TestQuote2 = new SBQQ__Quote__c();
        TestQuote2.SBQQ__Opportunity2__c = opp.id;
        TestQuote2.Contract_Term_Years__c = '2';
        TestQuote2.Current_Year__c = 2;
        TestQuote2.SBQQ__Type__c = 'Renewal';
        TestQuote2.Contract_Executed__c = true;
        TestQuote2.SBQQ__StartDate__c = System.today().addYears(-1);
        TestQuote2.SBQQ__EndDate__c = System.today();
        //TestQuote2.Multiple_Years_Commitment__c = true;
        TestQuote2.previousQuote__c = TestQuote.id;
        insert TestQuote2;
        
        TestQuote2.Multiple_Years_Commitment__c = true;
        update TestQuote2;
        
        //Insert Quote Line2
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c();
        ql2.SBQQ__Quantity__c = 1;
        ql2.SBQQ__Product__c = product1.Id;
        ql2.SBQQ__ListPrice__c = 10;
        ql2.SBQQ__NetPrice__c = 10;
        ql2.Rack_Rate__c = 10;
        ql2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        ql2.SBQQ__Number__c = 1;
        ql2.SBQQ__Group__c = qlGroup.id;
        ql2.SBQQ__Quote__c = TestQuote2.Id;
        ql2.Notes__c = 'abc';
        ql2.SBQQ__UpgradedSubscription__c = sub.id;
        insert ql2;

        //Insert CPQ Audit record
        CpqAudit__c testAudit = new CpqAudit__c();
        testAudit.Name = 'Test Audit';
        insert testAudit;
        
        Set<Id> quoteIdsBatch = new Set<Id>();
        quoteIdsBatch.add(TestQuote.id);
        quoteIdsBatch.add(TestQuote2.id);
        
        //String JobName = 'Test Batch Quote';
        
        //Test.startTest();
        
        //Run batch
        CventMyd_QuoteSchedulable BatchRun = new CventMyd_QuoteSchedulable(quoteIdsBatch, 'Test Batch Run', testAudit.id);
        //CventMyd_QuoteSchedulable renewalQuoteSchedulable = new CventMyd_QuoteSchedulable(renewalQuoteMap.keySet(),renewalJobName,renewalJobAuditRecord.Id);
        //ID batchprocessid = Database.executeBatch(BatchRun,200);
        String sch = '0 0 23 * * ?';
        system.schedule('Test Run', sch, BatchRun);
        
        //Test.stopTest();
    
	}

}