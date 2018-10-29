@isTest

private class ContractTrgHelperClsTest {
	
    public static testMethod void testMethod0() {

        Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();       

        Id ChildRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();      

        Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp.CurrencyIsoCode  = 'USD';
        insert opp;     

        Account TestAccount = new Account();
        TestAccount.Name = 'Test Account' + String.valueOf(Math.random());
        insert TestAccount;     

        Contract ParentCont = new Contract();
        ParentCont.AccountId = TestAccount.id;
        ParentCont.Contract_Term_Years__c = '5';
        ParentCont.RecordTypeId = RecordTypeId;
        ParentCont.SBQQ__Opportunity__c = opp.id;
        //ParentCont.Is_Legacy__c = true;
        ParentCont.SBQQ__RenewalQuoted__c = false;
        ParentCont.Failed_Auto_Renew__c = false;
        ParentCont.Renewal_Creation_Date__c = System.today().addYears(1); 

        Product2 product1 = new Product2();
        product1.Name = 'Product 1';
        product1.Contract_Output_Grouping__c = 'Bundle Advertisements';
        product1.Revenue_Type__c = 'Annual Recurring    ';
        insert product1;       

        Contract cont = new Contract();
        cont.RecordTypeId = ChildRecordTypeId;
        cont.AccountId = TestAccount.id;
        cont.Parent_Contract__c = ParentCont.id;
        //cont.Upcoming_Renewal_Type__c = 'Contract Renewal';
        cont.EndDate = System.today();
        //cont.Remaining_Master_Term__c = 0;
        cont.Current_Year__c = 1;
        //cont.Is_Legacy__c = true;
        cont.SBQQ__RenewalQuoted__c = false;
        cont.Failed_Auto_Renew__c = false;
        cont.Multiple_years_Commitment__C = true;
        cont.Renewal_Creation_Date__c = Date.newInstance(2018,9,5); //System.today().addYears(1);
        cont.SBQQ__RenewalQuoted__c = false;
        
        insert cont;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Product__c = product1.id;
        sub.SBQQ__Account__c = TestAccount.id;
        sub.SBQQ__Contract__c = cont.id;
        sub.SBQQ__Quantity__c = 1;    

        insert sub;       

        Test.setCreatedDate(cont.Id,DateTime.newinstance(2015,9,5));

        cont.SBQQ__RenewalQuoted__c = true;

        Id contId = cont.Id ;

        Test.startTest();

        cont = [select parent_contract_term_years__c from contract where Id =: contId];

        update cont;

        Map<Id,Date> accountIdToDate = new Map<Id,Date>();

        accountIdToDate.put(TestAccount.Id,Date.today());

        ContractTrgHelperCls.updateEndDatesOnAccounts(accountIdToDate);

        try {

            ContractTrgHelperCls.throwRenewalException(cont.Id,true);

        }

        catch (Exception e) {



        }

        Test.stopTest();

    }

    public static testMethod void testMethod1() {

        Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');

        opp.CurrencyIsoCode  = 'USD';

        opp.contractedDateTime__c = DateTime.now().addMinutes(-2);

        insert opp; 

        ContractTrgHelperCls.opportunityIdsContracted = new Set<Id>{opp.Id};

        ContractTrgHelperCls.handleContractedMonitoring();

    }

    public static testMethod void testMethod2() {

        Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');

        opp.CurrencyIsoCode  = 'USD';

        opp.contractedDateTime__c = DateTime.now().addMinutes(-2);

        insert opp; 

        SBQQ__Quote__c testQuote = createQuote();

        Set<Id> quoteIds = new Set<Id>{testQuote.Id};

        scheduleSomeJobs(quoteIds);

        ContractTrgHelperCls.opportunityIdsContracted = new Set<Id>{opp.Id};

        ContractTrgHelperCls.handleContractedMonitoring();        

    }

    public static testMethod void testMethod3() {

        Id RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();       

        Id ChildRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();      

        Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp.CurrencyIsoCode  = 'USD';
        insert opp;     

        Account TestAccount = new Account();
        TestAccount.Name = 'Test Account' + String.valueOf(Math.random());
        insert TestAccount;     

        Contract ParentCont = new Contract();
        ParentCont.AccountId = TestAccount.id;
        ParentCont.Contract_Term_Years__c = '5';
        ParentCont.RecordTypeId = RecordTypeId;
        ParentCont.SBQQ__Opportunity__c = opp.id;
        //ParentCont.Is_Legacy__c = true;
        ParentCont.SBQQ__RenewalQuoted__c = false;
        ParentCont.Failed_Auto_Renew__c = false;
        ParentCont.Renewal_Creation_Date__c = System.today().addYears(1); 

        insert ParentCont;

        Product2 product1 = new Product2();
        product1.Name = 'Product 1';
        product1.Contract_Output_Grouping__c = 'Bundle Advertisements';
        product1.Revenue_Type__c = 'Annual Recurring    ';
        insert product1;       

        Contract cont = new Contract();
        cont.RecordTypeId = ChildRecordTypeId;
        cont.AccountId = TestAccount.id;
        cont.Parent_Contract__c = ParentCont.id;
        //cont.Upcoming_Renewal_Type__c = 'Contract Renewal';
        cont.EndDate = System.today();
        cont.StartDate = System.today().addMonths(-12);
        //cont.Remaining_Master_Term__c = 0;
        cont.Current_Year__c = 1;
        //cont.Is_Legacy__c = true;
        cont.SBQQ__RenewalQuoted__c = false;
        cont.Failed_Auto_Renew__c = false;
        cont.Multiple_years_Commitment__C = true;
        cont.Renewal_Creation_Date__c = Date.newInstance(2018,9,5); //System.today().addYears(1);
        cont.SBQQ__RenewalQuoted__c = false;
        
        insert cont;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Product__c = product1.id;
        sub.SBQQ__Account__c = TestAccount.id;
        sub.SBQQ__Contract__c = cont.id;
        sub.SBQQ__Quantity__c = 1;    

        insert sub;       

        Test.setCreatedDate(cont.Id,DateTime.newinstance(2015,9,5));

        System.debug('in test method, is renewal quoted checked: ' + cont.SBQQ__RenewalQuoted__c);

        Id contId = cont.Id ;

        cont = [select parent_contract_term_years__c from contract where Id =: contId];

        System.debug('contract Parent_Contract_Term_Years__c: ' + cont.Parent_Contract_Term_Years__c);

        cont.SBQQ__RenewalQuoted__c = true;

        update cont;

    }

    public static SBQQ__Quote__c createQuote() {

        Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');
        opp.CurrencyIsoCode  = 'USD';
        insert opp;     

        SBQQ__Quote__c TestQuote = new SBQQ__Quote__c();
        TestQuote.SBQQ__Opportunity2__c = opp.id;
        TestQuote.Contract_Term_Years__c = '2';
        TestQuote.SBQQ__Type__c = 'Amendment';
        TestQuote.Current_Year__c = 2;
        TestQuote.Contract_Executed__c = true;
        TestQuote.SBQQ__StartDate__c = System.today().addYears(-1);
        TestQuote.SBQQ__EndDate__c = System.today();
        TestQuote.createdFromLegacyContract__c = true;
        //TestQuote.Multiple_Years_Commitment__c = true;
        TestQuote.statusCheckCount__c = 0;
        insert TestQuote;

        return TestQuote;

    }   

    public static void scheduleSomeJobs(Set<Id> quoteIds) {

		Decimal minutesBetweenJobs = .2;

		Integer numberOfJobs = 81;

		List<Integer> secondsBeforeJobs = new List<Integer>();

		for(Integer i = 1; i <= numberOfJobs; i++) {

			Integer secondsBeforeThisJob = (Integer) ( (Decimal)i * 60.00 * minutesBetweenJobs );
			
			DateTime dateTimeForThisJob = DateTime.now().addSeconds(secondsBeforeThisJob);
			
			String cronString = CventMyd_UtilityMethods.getCronString(secondsBeforeThisJob);
			
			String dateTimeString = CventMyd_UtilityMethods.getFormattedDateTimeString(dateTimeForThisJob,true,false);

			String jobName = 'Dummy Schedulable Job @ ' + dateTimeString;

			CventMyd_DeleteGhostQuotes dummySchedulableClass = new CventMyd_DeleteGhostQuotes(quoteIds,jobName);
			
			System.schedule(jobName,cronString,dummySchedulableClass);
			
		}  

	}    

}