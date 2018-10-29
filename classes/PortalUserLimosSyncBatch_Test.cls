/**@author Hemant Rana
Test Class for "PortalUserLimosSyncBatch" && "schduleBatchPortalUserLimosSync"
Version 1.0
Date: 17th Feb 2016
*/
@isTest
private class PortalUserLimosSyncBatch_Test{
    //test Method for the "schduleBatchPortalUserLimosSync" class
    static testMethod void test_schedulerClass()
    {
        Test.startTest();
        /* Get any profile for the given type.*/
        Id portalProfileId = [SELECT Id FROM Profile WHERE Name = 'Cvent Customer Community User' limit 1].Id; 

        Account portalAccount = new Account(name = 'portalAccount');//create a portal account first
        insert portalAccount;
        Contact portalContact = new contact(LastName = 'portalContact', AccountId = portalAccount.Id); //create a portal contact
        insert portalContact;
        User u1 = new User( email='PortalUserLimosSyncBatch@gmail.com',
            profileid = portalProfileId, 
            UserName='PortalUserLimosSyncBatch@gmail.com', 
            Alias = 'GDS',
            TimeZoneSidKey='America/New_York',
            EmailEncodingKey='ISO-8859-1',
            LocaleSidKey='en_US', 
            LanguageLocaleKey='en_US',
            ContactId = portalContact.Id,
            PortalRole = 'Manager',
            FirstName = 'Genelia',
            LastName = 'Dsouza');
            
        schduleBatchPortalUserLimosSync schedulerVar=new schduleBatchPortalUserLimosSync();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test PortalUserLimosSyncBatch', sch, schedulerVar); 
        Test.stopTest();
    }
}