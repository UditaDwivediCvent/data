public class JustToTestCLS {
    private final Account acct;
     public string Id{get;set;}
     public JustToTestCLS (ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
        Account inst = [SELECT ID,Other_AccountId__C FROM Account WHERE Id=:ApexPages.currentPage().getParameters().get('Id')];
        Id = inst.Other_AccountId__C;
    }
}