/**
///////////////////////////////
//    @author Rohit Saxena    //
///////////////////////////////

Version 1.0
Date: 10th July 2015
Description : To test salesResourcesTrgHelperCls
*/
@isTest
private class salesResourcesTrgHelperClsTest {
    
    public static Id createAccount(){
        ISOSetting__c instSetting = new ISOSetting__c();
        instSetting.Country_Name__c = 'IN';
        instSetting.ISO__c = 'IN';
        instSetting.Name = 'Australia';
        insert instSetting;
        
        ISOSetting__c instSettingSec = new ISOSetting__c();
        instSettingSec.Country_Name__c = 'Afghanistan';
        instSettingSec.ISO__c = 'AFG';
        instSettingSec.Name = 'Afghanistan';
        insert instSettingSec;    
        
        RecordType rtType = [SELECT r.SobjectType, r.DeveloperName,r.IsActive FROM RecordType r WHERE SobjectType = 'Account' And DeveloperName = 'Biz_Ac' And IsActive=true];
        Account instofAcc = new Account();
        instofAcc.Back_Office_System__c = '123Signup';
        instofAcc.API_connected_with__c= '44fish.com';
        instofAcc.RecordTypeId = rtType.id;
        //instofAcc.BillingState = 'Queensland';
        //instofAcc.BillingStreet = 'Delhi';
        //instofAcc.BillingCountry = 'Australia';
        instofAcc.Name = 'Test';
        instofAcc.BillingCountryCode='IN';
        instofAcc.CVII_ID__c='4654654';
        instofAcc.Federal_Tax_ID_VAT_Number__c='46544654';
        instofAcc.Region__c='Test';
        instofAcc.AM_CrowdCompass__c='Brandon Beall';
        instofAcc.AM_CrowdTorch__c='Brandon Beall';
        instofAcc.AM_CSN__c='Brandon Beall';
        instofAcc.AM_CT_TM__c='Brandon Beall';
        instofAcc.AM_Event__c='Brandon Beall';
        instofAcc.AM_PA__c='Brandon Beall';
        instofAcc.AM_Survey__c='Brandon Beall';
        instofAcc.CS_Rep__c='Brandon Beall';
        
        Country_Phone_Codes__c setting = new Country_Phone_Codes__c();
        setting.Name = 'IN';
        setting.ISD_Code__c = '91';
        insert setting;
        
        CountryCode__c cCode = new CountryCode__c();
        cCode.Name = 'IN';
        cCode.Code__c = 'INDIA';
        insert cCode;
        
        instofAcc.Phone = '056465465465';
        insert instofAcc;
        
        
        //inserting HODI record
        HODI_Inventory__c HODIInventory=new HODI_Inventory__c();
        HODIInventory.Name='Test User';
        HODIInventory.Head_of_Department__c=UserInfo.getUserId();
        HODIInventory.Pool_Point__c=50;
        insert HODIInventory;
        
        //instofAcc.BillingCountry = 'Afghanistan';
        instofAcc.IsHODI_Dev__c = true;
        instofAcc.HODI_Approver_Dev__c=UserInfo.getUserId();
        instofAcc.Service_Tier__c='Basic';
        instofAcc.HODI_Request_Date_Dev__c=system.today();
        instofAcc.IsRejected_Dev__c=false;
        instofAcc.HODI_Id_Dev__c= HODIInventory.Id;
        instofAcc.Desired_Tier_Dev__c='464644';
        instofAcc.HOD_Comment_Dev__c='test';
        instofAcc.HODI_Count_Dev__c= 464646;
        instofAcc.Previous_Tier_Dev__c='464644';
        update instofAcc;
        return instofAcc.id;
    }
    
    static testMethod void muUnitTest(){
        Id accid = createAccount();
        
        List<Sales_Resources__c>lstSalRes = new lIst<Sales_Resources__c>();
        RecordType instRecType=[SELECT ID FROM RecordType WHERE SobjectType='Sales_Resources__c' AND DeveloperName='Sales_Engineering' AND isActive=true LIMIT 1];
        
        Sales_Resources__c instOfSalRes = new Sales_Resources__c();
        instOfSalRes.Back_Office_System_New__c = '123Signup';
        instOfSalRes.API_connected_with__c = '44fish.com';
        instOfSalRes.RecordTypeId = instRecType.Id;
        instOfSalRes.Account__c = createAccount();
        lstSalRes.add(instOfSalRes);
        
        Sales_Resources__c instOfSalResSec = new Sales_Resources__c();
        instOfSalResSec.Back_Office_System_New__c = 'Blackboard';
        instOfSalResSec.API_connected_with__c = 'Advanced CRM';
        instOfSalResSec.RecordTypeId = instRecType.Id;
        instOfSalResSec.Account__c = createAccount();
        lstSalRes.add(instOfSalResSec);
        
        Insert lstSalRes;
        
        
        lstSalRes[0].Back_Office_System_New__c = 'aMember Pro';
        lstSalRes[0].API_connected_with__c = 'Advanced CRM';
        lstSalRes[0].RecordTypeId = instRecType.Id;
        
        
        Update lstSalRes[0];
        
    }
    
    static testMethod void testPrimarySyncAddressFunc(){
        Id accid = createAccount();
        
        Address__c adr = new Address__c();
        adr.Account__c = accid;
        adr.Primary_Sync__c=true;
        insert adr;
        
        Account acc = new Account(Id=accid);
        delete acc;
    }
}