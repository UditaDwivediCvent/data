@isTest

private class CventMyd_ContractGenerationMonitor_Test {
	
	private static testMethod void testMethod0() {

                CventMyd_Settings.minutesBeforeContractMonitor = 2;

                Opportunity opp = TestUtil.createOpportunity('Test Opp', 'Renewal', 'Closed Won');

                opp.CurrencyIsoCode  = 'USD';

                insert opp;

                opp.SBQQ__Contracted__c = true;

                Test.startTest();

                update opp;

                Test.stopTest();

	}

}