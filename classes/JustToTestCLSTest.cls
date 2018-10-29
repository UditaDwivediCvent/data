@istest
private class JustToTestCLSTest{
    static testMethod void myUnitTest(){
        Account instOfAcc = new Account();
        instOfAcc.Name = 'TEST';
        insert instOfAcc;
        instOfAcc.Other_AccountId__c = instOfAcc.Id;
        update instOfAcc;
        Apexpages.currentPage().getParameters().put('Id',instOfAcc.Id);
        Apexpages.Standardcontroller controller = new Apexpages.Standardcontroller(instOfAcc);
        JustToTestCLS instOfJTTC = new JustToTestCLS(controller);
        
    }
}