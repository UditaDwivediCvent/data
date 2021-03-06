// ===============================
// Name				: AMValidationBacthTest
// AUTHOR           : Shanu Aggarwal    
// CREATED DATE     : 20 Sep 2016
// CLASS       		: AMValidationBacth
// SPECIAL NOTES    :
// ===============================
@istest
public class AMValidationBacthTest {

    
    static testMethod void myUnitTest() {
        
        Test.startTest();
        //Inserting User...............
        Profile p = [SELECT Id FROM Profile WHERE Name='Finance - Management']; 

        USerrole[] testroleId=[select id from userRole where name ='AM (Event)' OR name ='Pre Sales - Special Projects' limit 2];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Sops', LanguageLocaleKey='en_US', FirstName='TestUser',
        LocaleSidKey='en_US', ProfileId = p.Id, userRoleId=testroleId[0].id,
        TimeZoneSidKey='America/Los_Angeles', UserName='Test'+'deploymentuser@cvent.com');
        
        
        system.runAs(u){
            
            Account acc= new Account();
            acc.Name = 'Test Account 1';
            acc.Supplier_Type__c = 'Venue';
            acc.AM_Event__c = UserInfo.getName();
            acc.Account_Status__c = 'Active';
            insert acc;
            
            Contact con = new Contact();
            con.AccountId = acc.Id; 
            con.LastName = 'Contact 1';
            con.Product_Desired__c  = 'CrowdCompass';
            insert con;
            
            Contact_Role__c cr = new Contact_Role__c();
            cr.RecordTypeId = Schema.SObjectType.Contact_Role__c.getRecordTypeInfosByName().get('Buyer Role').getRecordTypeId();
            cr.Contact__c = con.Id;
            cr.Account_Buyer_Role__c = acc.Id;
            insert cr;
            
            
            
        }
        /*
        AMValidationBacth ab= new AMValidationBacth() ;
    	Database.executeBatch(ab,50);
        */
        SchedulableContext SC;
        AMValidationBatchScheduler aScheduler = new AMValidationBatchScheduler();
        aScheduler.execute(SC);
        Test.stopTest();
        
    }

}