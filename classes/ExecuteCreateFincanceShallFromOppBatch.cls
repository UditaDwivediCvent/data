global with sharing class ExecuteCreateFincanceShallFromOppBatch{
   WebService static String createFincanceShallFromOpp(String oppId){
        String recordId = '';
        Opportunity opp = [SELECT Id, SBQQ__PrimaryQuote__c, 
                            (SELECT Opportunity__c
                               FROM Contract_Reviews__r 
                              WHERE Contract_Review_Ok__c = 'Yes') 
                               FROM Opportunity WHERE Id = :oppId 
                               LIMIT 1];   

        if(opp.Contract_Reviews__r != null && opp.SBQQ__PrimaryQuote__c != null){
            if(opp.Contract_Reviews__r.size() > 0){
                CreateFincanceShallFromOppSingleRec b = new CreateFincanceShallFromOppSingleRec(oppId);   
                recordId = b.createFinanceShellRecord(); 
                System.debug('recordId-->' + recordId);
            } 
        }        
        return recordId;
    }   
}