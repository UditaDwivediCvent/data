global class ScheduledFinanceShellBatch implements Schedulable {
	global void execute(SchedulableContext sc) {
      Date todayDate = Date.today();
      Date lastWeekDate = todayDate.addDays(-7);
      Set<Id> opportunityIds = new Set<Id>();

      List<Contract_Reviewing__c> lstContractReviewed = [SELECT Opportunity__c 
                                                           FROM Contract_Reviewing__c 
                                                          WHERE Final_Review_Date__c >= :lastWeekDate 
                                                            AND Final_Review_Date__c <= :todayDate
                                                            AND Contract_Review_Ok__c = 'Yes'];
      for(Contract_Reviewing__c lstItr : lstContractReviewed){
            opportunityIds.add(lstItr.Opportunity__c);
      }
      CreateFincanceShallFromOpp b = new CreateFincanceShallFromOpp(opportunityIds); 
      Database.executeBatch(b,1);
   }
}