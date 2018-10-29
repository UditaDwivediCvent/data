/**
//////////////////////////////////////
//      @author Abhishek Pandey     //
/////////////////////////////////////
Version :   1.0
Date : 23rd July 2014
Description: Tests the ContactTrgHelperCls , stopping the creation of Task depending on campaign members "Member Status Updated"  date value . 
 */
@isTest
public class ContactTrgHelperClsTest {
    public static Account instofAcc = new Account();
    public static Contact instContact = new Contact();
    public static Contact_Role__c conRoleObj;
    public static Contact contactObj;
    public static List<Contact> contactList; 
    public static List<Contact_Role__c> conRoleList; 
    public static Contact instContactFif = new Contact();   
    public static Campaign_Assignment__c instOfCampAss = new Campaign_Assignment__c();  
    public static ISOSetting__c instOfIso = new ISOSetting__c();
    public static ISOSetting__c instOfIsoSec = new ISOSetting__c();
    static{
        instOfIso.Name = '1';
        instOfIso.Country_Name__c = 'America';
        instOfIso.ISO__c = 'USA';
        insert instOfIso;
        
        instOfIsoSec.Name = '2';
        instOfIsoSec.Country_Name__c = 'India';
        instOfIsoSec.ISO__c = 'IND';
        insert instOfIsoSec;
        
        Campaign instOfCamp = new Campaign();
        instOfCamp.Name = 'Test';
        insert instOfCamp;
        
        instOfCampAss.Name = '1';
        instOfCampAss.Lead_Source__c = 'WEB-Chat (CrowdCompass)';
        instOfCampAss.Campaign_Id__c = instOfCamp.Id;
        instOfCampAss.Assigned_Role__c = 'CrowdTorch';
        insert instOfCampAss;
        
        Id custRecTypeId = Schema.SObjectType.Contact_Role__c.getRecordTypeInfosByName().get('Customer Role').getRecordTypeId();
        
        RecordType rtType = [SELECT r.SobjectType, r.DeveloperName,r.IsActive FROM RecordType r WHERE SobjectType='Account' AND DeveloperName='Biz_Ac' And IsActive = true];
        StopCloudMDMExe.stopExecutionCloudMdm = false;
        instofAcc.Supplier_Type__c = 'Venue';
        instofAcc.Venue_Type__c = 'CVB';
        instofAcc.RecordTypeId = rtType.id;
        instofAcc.Name = 'Test';
        insert instofAcc;
        
        contactList = new List<Contact>();        
        instContact.LastName = 'Test';
        instContact.AccountId = instofAcc.Id;
        instContact.CT_Contact_Status__c= 'Open Opportunity';
        instContact.Event_Contact_Status__c = 'Open Opportunity';
        instContact.TM_Contact_Status__c = 'Open Opportunity';
        instContact.LeadSource = 'WEB-Chat (CrowdCompass)';
        instContact.Mood_Level__c = 2;
        instContact.Purchasing_Interest_CSNP__c = '4 - Very interested';
        instContact.Purchasing_Interest_PK__c='3 - Somewhat interested';
        instContact.Attended__c = 'CSG';
        instContact.MailingCountryCode = 'IN';
        
        Country_Phone_Codes__c setting = new Country_Phone_Codes__c();
        setting.Name = 'IN';
        setting.ISD_Code__c = '91';
        insert setting;
        
        instContact.Phone = '056465465465';
        instContact.MobilePhone = '056465465465';
        instContact.OtherPhone = '056465465465';
        contactList.add(instContact);
        
        instContactFif.LastName = 'Test';
        instContactFif.AccountId = instofAcc.Id;
        instContactFif.CT_Contact_Status__c= 'E - Attended';
        instContactFif.Event_Contact_Status__c = 'Trash';//'E - Attended';
        instContactFif.TM_Contact_Status__c = 'E - Attended';
        instContactFif.LeadSource = 'WEB-Chat (CT-Mobile)';
        instContactFif.Mood_Level__c = 4;
        instContactFif.Attended__c = 'OD/PS';
        instContactFif.Purchasing_Interest_CSNP__c = '4 - Very interested';
        contactList.add(instContactFif);
        
        contactObj = new Contact();       
        contactObj.LastName = 'Test';
        contactObj.AccountId = instofAcc.Id;
        contactObj.Mood_Level__c = 2;
        contactObj.Event_Contact_Status__c= 'Trash';
        contactObj.Event_Recycle_Reason__c = 'NO longer there';
        contactObj.Survey_Contact_Status__c = 'Trash';
        contactObj.Survey_Recycle_Reason__c = 'NO longer there';
        contactObj.CSN_P_Contact_Status__c= 'Trash';
        contactObj.CSN_P_Status_Details__c = 'NO longer there';
        contactObj.SMM_Contact_Status__c = 'Trash';
        contactObj.SMM_Recycle_Trash_Reason__c = 'NO longer there';
        contactObj.CSNS_Contact_Status__c= 'Trash';
        contactObj.CSN_S_Recycle_Trash__c = 'NO longer there';
        contactObj.CC_Contact_Status__c = 'Trash';
        contactObj.CC_Recycle_Trash_Reason__c = 'NO longer there';
        contactObj.TM_Contact_Status__c= 'Trash';
        contactObj.TM_Recycle_Trash_Reason__c = 'NO longer there';
        contactObj.CT_Contact_Status__c= 'J - Trash';
        contactObj.CT_Recycle_Trash_Reason__c = 'NO longer there'; 
        contactObj.Purchasing_Interest_PK__c='3 - Somewhat interested';
        contactObj.Attended__c = 'CSG';
        contactObj.Purchasing_Interest_Inquisium__c ='3 - Somewhat interested';
        
        instContactFif = new Contact();
        instContactFif.LastName = 'Test';
        instContactFif.AccountId = instofAcc.Id;
        instContactFif.CT_Contact_Status__c= 'E - Attended';
        instContactFif.Event_Contact_Status__c = 'Trash';//'E - Attended';
        instContactFif.TM_Contact_Status__c = 'E - Attended';
        instContactFif.LeadSource = 'WEB-Chat (CT-Mobile)';
        instContactFif.Mood_Level__c = 4;
        instContactFif.Attended__c = 'CSG';
        instContactFif.Purchasing_Interest_CSNP__c = '4 - Very interested';
        contactList.add(instContactFif);
        contactList.add(contactObj);
        
        instContactFif = new Contact();
        instContactFif.LastName = 'Test';
        instContactFif.AccountId = instofAcc.Id;
        instContactFif.CT_Contact_Status__c= 'E - Attended';
        instContactFif.Event_Contact_Status__c = 'Trash';//'E - Attended';
        instContactFif.TM_Contact_Status__c = 'E - Attended';
        instContactFif.LeadSource = 'WEB-Chat (CT-Mobile)';
        instContactFif.Mood_Level__c = 4;
        instContactFif.Attended__c = 'CSG';
        instContactFif.Purchasing_Interest_Inquisium__c = '3 - Somewhat interested';
        contactList.add(instContactFif);
        
        insert contactList;
        
        conRoleList = new List<Contact_Role__c>();        
        conRoleObj = new Contact_Role__c();        
        conRoleObj.Account_Customer_Role__c = instofAcc.Id;
        conRoleObj.Contact__c = contactList[2].Id;
        conRoleObj.RecordTypeId = custRecTypeId;
        conRoleObj.User__c = false;
        conRoleObj.User_Sub_Role__c = 'Administrator;Community Portal Administrator'; // added by Vaibhav Jain (2nd Mar 2017 8:51 pm IST)
        conRoleList.add(conRoleObj);        
        
        conRoleObj = new Contact_Role__c();
        conRoleObj.Account_Customer_Role__c = instofAcc.Id;
        conRoleObj.Contact__c = contactList[2].Id;
        conRoleObj.RecordTypeId = custRecTypeId;
        conRoleObj.User_Sub_Role__c = 'Administrator;Community Portal Administrator'; // added by Vaibhav Jain (2nd Mar 2017 8:51 pm IST)
        conRoleObj.User__c = false;
        conRoleList.add(conRoleObj); 
        
        insert conRoleList;
    }
    
    static testMethod void myUnitTest() {
        /*Contact instOfContactThir = [SELECT Id,CT_Contact_Status__c,Event_Contact_Status__c,TM_Contact_Status__c FROM Contact WHERE Id =: instContact.id LIMIT 1];
        instOfContactThir.CT_Contact_Status__c= 'H - Closed Won';
        instOfContactThir.Event_Contact_Status__c = 'Closed Won';
        instOfContactThir.TM_Contact_Status__c = 'H - Closed Won';
        update instOfContactThir;*/
        
        contactList[0].Purchasing_Interest_CSNP__c = '3 - Somewhat interested';
        contactList[0].Purchasing_Interest_PK__c = '4 - Very interested';
        contactList[0].Last_Attended_Event__c = System.today();
        
        contactList[1].Purchasing_Interest_CSNP__c = '3 - Somewhat interested';
        contactList[1].Last_Attended_Event__c = System.today();
        
        contactList[2].Purchasing_Interest_PK__c = '4 - Very interested';
        contactList[2].Purchasing_Interest_Inquisium__c = '4 - Very interested';
        contactList[2].Last_Attended_Event__c = System.today();
                
        contactList[3].Purchasing_Interest_CSNP__c = '3 - Somewhat interested';
        contactList[3].Last_Attended_Event__c = System.today();
        
        contactList[4].Purchasing_Interest_Inquisium__c = '4 - Very interested';
        contactList[4].Last_Attended_Event__c = System.today();
                
        update contactList;
        
        Contact instOfContactSEC = [SELECT Id,CT_Contact_Status__c,Event_Contact_Status__c,TM_Contact_Status__c FROM Contact WHERE Id =: instContact.id LIMIT 1];
        delete instOfContactSEC;
    }
    
    static testMethod void myUnitTestGDPR(){
        contactList[0].Is_GDPR__c = true;
        update contactList;
    }
}