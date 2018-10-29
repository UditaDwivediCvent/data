@isTest
public class LitmosProvisionClassTest{
    static testMethod void unitMethod(){
        User userObj = [SELECT Id,Name,Contact.Account.Name,ShowLitmosTab__c,Email,Litmos__Sync_Litmos__c,Litmos__Litmos_Activated__c,Litmos__LitmosUserId__c FROM User WHERE IsportalEnabled = TRUE AND ISACTIVE = TRUE AND ProfileId ='00eo00000016QNc' AND Litmos__Sync_Litmos__c=FALSE AND Litmos__Litmos_Activated__c=FALSE LIMIT 1];
        Test.StartTest();
        PageReference pageRef = Page.LitmosProvisioning;
        Test.setCurrentPage(pageRef);
        LitmosProvisionClass testAccPlan = new LitmosProvisionClass();
        testAccPlan.Email = userObj.Email;
        testAccPlan.SearchUser();
        testAccPlan.SyncLitmos();
        Test.StopTest();
    }
}