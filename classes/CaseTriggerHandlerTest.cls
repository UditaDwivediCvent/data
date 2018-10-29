// ===============================
// AUTHOR     : Shanu Aggarwal    
// CREATED DATE     :18/03/2016
// PURPOSE     :  To handle trigger methods
// TEST CLASS :   
// SPECIAL NOTES: 

//VERSIONS:
//Ver1.0 updateTotalTimeSpentTest4() uodated because there are too manny DML's for case hitting too many soql error
//Ver2.0 
//Ver3.0 
//Ver4.0 


// ===============================
@isTest 
private class CaseTriggerHandlerTest
{
    public static Account instofAcc = new Account();
    public static Contact instofCon =  new Contact();
    public static AccountTeamMember  instofAccMember =  new AccountTeamMember ();
      
      static testMethod void updateTotalTimeSpentTest4(){
        
        ClientProficiencyLevelMapping__c client = new ClientProficiencyLevelMapping__c();
        client.Level__c = 1;
        client.name='Basic';
        insert client;
        
        
        Id recTypeCase  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Event').getRecordTypeId();
        Id recTypeCase1 = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Sales Cases').getRecordTypeId();
        Id recTypeCase2 = Schema.SObjectType.Case.getRecordTypeInfosByName().get('New CrowdCompass').getRecordTypeId();
        Id recTypeCase3 = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Client Management (Global)').getRecordTypeId();
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        
        //Create a Test User
        User u = new User(Alias = 'testUX', Email='ggg@torg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='syd@torg.com');
        insert u;
        //Create a
        User u2 = new User(Alias = 'testUX1', Email='syd@torg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='yy@torg.com');
        
        //Case Segeration Test Class
        
        //Insert Account record..........
        instofAcc.Name = 'TestCaseSegeration';
        instofAcc.Supplier_Type__c = 'Venue';
        instofAcc.Venue_Type__c = 'CVB';
        insert instofAcc;

        //Insert AccountTeamMeber Record...........
        instofAccMember.AccountId = instofAcc.Id;
        instofAccMember.TeamMemberRole = 'Strategic Account Consultant';
        instofAccMember.UserId = UserInfo.GetUserId();
        insert instofAccMember;
        
        //Insert Case Record..............
        Case caseObj = new Case();
        caseObj.recordTypeId = caseRecordTypeId ;
        //caseObj.Product_Type__c = 'Event Tool';
        caseObj.Status = 'Open';
        caseObj.Minutesoncase__c = 30; 
        caseObj.OwnerId = u.Id;
        caseObj.AccountId=instofAcc.Id;
        caseObj.subject='Test Hosp Cloud Implementation Survey';
        caseObj.Origin ='Email';       
        caseObj.description='The details of Francisco De Asis Grageras response are below.Dear Francisco De Asis Gragera,Thank you for completing the Hosp Cloud Implementation Survey! We appreciate the time you spent to provide us with the contract details. Given below is a snaphot of the survey response. Respondent Information Survey Title: Hosp Cloud Implementation Survey Response Number: 50104104 Total Score: 0.00/0.00 Start Date: 01/09/2017 1:07 PM Completion Date: 01/09/2017 1:25 PM Response Information Question Answer Score Contract Type CSN Bundle 0.00 Please provide the Salesforce link to the Contract Signer https://cvent.my.salesforce.com/'+instofAcc.Id+' 0.00 Bundle Type Single Property Bundle 0.00 Salesforce Account Link: https://cvent.my.salesforce.com/00100000008DBY3 0.00';
        insert caseObj;
        
        //Update Case Record............
        caseObj.Minutesoncase__c = 15 ;
        update caseObj;
        
        
        
        
        Id caseId;
        Case c = new Case(); 
        //Case c1 = new Case();
        Case c2 = new Case();
        Case c3 = new Case();

        Mobile_Card__c mc = new Mobile_Card__c();
        
        System.runAs(u){

            //Create Case
            
            c.recordTypeId = recTypeCase;
            c.Product_Type__c = 'Event Management';
            c.Status = 'Open';
            c.Minutesoncase__c = 30; 
            c.OwnerId = u.Id; 
            c.Subject='test';      
            insert c;
            caseId = c.Id;
           
            List<String> ptypelist = new List<String>();
            ptypelist.add('CSN - Planner');
            ptypelist.add('CSN - Supplier');
            ptypelist.add('eMarketing');
            ptypelist.add('Event Blue');
            ptypelist.add('OnArrival');
            ptypelist.add('Surveys');
            ptypelist.add('CrowdCompass');
            //ptypelist.add('CrowdTorch Ticketing');
            ptypelist.add('EMI');
            ptypelist.add('SpeedRFP');
            List<Case> caseList = new List<Case>();
            
            for(Integer i=0;i<ptypelist.size();i++){
                Case c1 = new Case();
                c1.recordTypeId = recTypeCase1;
                c1.Product_Type__c = ptypelist[i];
                c1.Status = 'Open';
                c1.OwnerId = u.Id;
                c1.Request_Type__c='Escalation';
                c1.Subject= 'Test';
                caseList.add(c1);
            }
            insert caseList;
            
            
            
            //System.assertEquals(0,[SELECT Minutesoncase__C FROM Case where ID =: caseId].Minutesoncase__c);            
           // System.assertEquals(30,[SELECT Id, Total_Time_Spent__c FROM Agent_Time_Spent__c where Case__c =: c.Id AND Agent__c =: u.Id].Total_Time_Spent__c);
           // System.assertEquals(30,[SELECT Total_Time_Spent__c FROM Case WHERE Id =: c.Id].Total_Time_Spent__c);
            
            //Update "Minutes on Case"
            CaseTriggerHandler.isRun = true;
            c.Minutesoncase__c = 15 ;
            update c;
            //Test.stopTest();
           // System.assertEquals(45,[SELECT Id, Total_Time_Spent__c FROM Agent_Time_Spent__c where Case__c =: c.Id AND Agent__c =: u.Id].Total_Time_Spent__c);
          //  System.assertEquals(45,[SELECT Total_Time_Spent__c FROM Case WHERE Id =: c.Id].Total_Time_Spent__c);
            
        }
        
        System.runAs(u2){
            
            CaseTriggerHandler.isRun = true;
            //Case cTest = [SELECT Id, Minutesoncase__c FROM Case where Id=:caseId];
            Case cTest = new Case(Id=caseId);
            cTest.Minutesoncase__c =15 ;
            cTest.OwnerId=u2.Id;
            Test.startTest();
            update cTest;
            
            
          //  System.assertEquals(0,[SELECT Minutesoncase__C FROM Case where ID =: cTest.Id].Minutesoncase__c);
          //  System.assertEquals(15,[SELECT Id, Total_Time_Spent__c FROM Agent_Time_Spent__c where Case__c =: cTest.Id AND Agent__c =: u2.Id].Total_Time_Spent__c);            
          //  System.assertEquals(60,[SELECT Total_Time_Spent__c FROM Case WHERE Id =: caseId].Total_Time_Spent__c);

            CaseTriggerHandler.isRun = true;
            //Update "Minutes on Case"
            cTest.MinutesonCase__c = 60;
            update cTest;

          //  System.assertEquals(0,[SELECT Minutesoncase__C FROM Case where ID =: cTest.Id].Minutesoncase__c);
          //  System.assertEquals(75,[SELECT Id, Total_Time_Spent__c FROM Agent_Time_Spent__c where Case__c =: cTest.Id AND Agent__c =: u2.Id].Total_Time_Spent__c);            
          //  System.assertEquals(120,[SELECT Total_Time_Spent__c FROM Case WHERE Id =: caseId].Total_Time_Spent__c);
            
        }
        
        delete c;
        undelete c;
        //create task for mobile app for apple oid
         System.runAs(u){
                
                instofAcc = new Account();
                RecordType rtType = [SELECT r.SobjectType, r.DeveloperName,r.IsActive FROM RecordType r WHERE SobjectType='Account' And DeveloperName='Biz_Ac' And IsActive=true];
                instofAcc.Name = 'Test';
                instofAcc.Supplier_Type__c = 'Venue';
                instofAcc.Venue_Type__c = 'CVB';
                instofAcc.RecordTypeId = rtType.id;
                insert instofAcc;
                
                /*instOfCon.LastName = 'Test';
                instOfCon.AccountId = instofAcc.Id;
                instOfCon.Creation_Source_System__c = 'ROL Test';
                insert instOfCon;*/
                
                mc.Name = 'Test Card';
                mc.Apple_OID__c = 'appcj25xPSHbE';
                mc.Primary_Contact__c = instOfCon.Id;
                mc.App_Name__c = 'test app';
                mc.App_Links__c = 'https://www.google.com';
                insert mc;
                
                c2.recordTypeId = recTypeCase2;
                c2.Product_Type__c = 'CrowdCompass';
                c2.Status = 'Open';
                c2.OwnerId = u.Id;
                c2.Subject = 'The status for your app, ConExpo (815133222), is now Ready for Sale.';
                c2.Description = 'Dear CrowdCompass, Inc.,  The following app has been approved and the app status has changed to Ready for Sale:   App Name: ConExpo  App Version Number: 1.10  App Type: iOS App App SKU: appcj25xPSHbE App Apple ID:815133222';
                insert c2;
                
                //Contact Priority - Last RM Case
                    c3.recordTypeId = recTypeCase3;
                    c3.ContactID = instOfCon.Id;
                    c3.Product_Type__c = 'CrowdCompass';
                    c3.Client_Proficiency_Level__c = 'Expert';
                    c3.Status = 'Open';
                    c3.OwnerId = u.Id;
                    c3.Subject = 'Test case for Case Priority';
                    c3.Description = 'this is a test case for case priority';
                    c3.Client_Proficiency_Level__c = 'Basic';
                    insert c3;
                    
                    
                    c3.SuppliedEmail = 'pbhateja@cvent.com';
                    update c3;
                //Contact Priority - Last RM Case
          
        }
        
        
        Test.stopTest();
        //create task for mobile app for apple oid
        
    }
    
    static testMethod void PopulateRequesterDueDateTest(){
        
       
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
        
        
        //Case Segeration Test Class
        
        //Insert Account record..........
        instofAcc.Name = 'TestCaseSegeration';
        instofAcc.Supplier_Type__c = 'Venue';
        instofAcc.Venue_Type__c = 'CVB';
        insert instofAcc;

        //Insert AccountTeamMeber Record...........
        instofAccMember.AccountId = instofAcc.Id;
        instofAccMember.TeamMemberRole = 'Strategic Account Consultant';
        instofAccMember.UserId = UserInfo.GetUserId();
        insert instofAccMember;
        
        //Insert Case Record..............
        Case caseObj = new Case();
        caseObj.recordTypeId = caseRecordTypeId ;
        //caseObj.Product_Type__c = 'Event Tool';
        caseObj.Status = 'Open';
        caseObj.Minutesoncase__c = 30; 
        caseObj.AccountId=instofAcc.Id;
        caseObj.subject='[HRTools][## ISHLP0183003 ##] Salesforce Account Request';
        caseObj.Origin ='Email';       
        caseObj.description='Please create Salesforce account for the following new hire by 2/12/2018 :';
        insert caseObj;
        
        caseObj = new Case();
        caseObj.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('GDPR Request').getRecordTypeId();
        //caseObj.Product_Type__c = 'Event Tool';
        caseObj.Status = 'Open';
        caseObj.Origin = 'Web2Case';
        caseObj.Minutesoncase__c = 30; 
        caseObj.AccountId=instofAcc.Id;
        caseObj.Type = 'Request for access';
        caseObj.Developer_Use_GDPR__c = 'WebToCase-GDPR';
        caseObj.subject='[HRTools][## ISHLP0183003 ##] Salesforce Account Request';
        caseObj.description='Please create Salesforce account for the following new hire by 2/12/2018 :';
        insert caseObj;
        
        caseObj.Status = 'Open – Approved';
        update caseObj;
        
        caseObj.Is_GDPR__c = true;
        update caseObj;
        
        delete caseObj;
        undelete caseObj;
        
    }
    static testMethod void GDPRTest(){
instofAcc.Name = 'TestCaseSegeration';
instofAcc.Supplier_Type__c = 'Venue';
instofAcc.Venue_Type__c = 'CVB';
insert instofAcc;

Case caseObj = new Case();
caseObj = new Case();
caseObj.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('GDPR Request').getRecordTypeId();
//caseObj.Product_Type__c = 'Event Tool';
caseObj.Status = 'Open';
caseObj.Origin = 'Web2Case';
caseObj.Minutesoncase__c = 30; 
caseObj.AccountId=instofAcc.Id;
caseObj.Type = 'Do Not Call';
caseObj.Developer_Use_GDPR__c = 'WebToCase-GDPR';
caseObj.subject='[HRTools][## ISHLP0183003 ##] Salesforce Account Request';
caseObj.description='Please create Salesforce account for the following new hire by 2/12/2018 :';
insert caseObj;

Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 

User u2 = new User(Alias = 'testUX1', Email='syd@torg.com', 
        EmailEncodingKey='UTF-8',FirstName='First', LastName='Testing1', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='yy@torg.com');
        
        
BillingCase__c bc = new BillingCase__c ();
bc.Billing_Account_Manager__c = 'First Testing1';
bc.CustomersAccount__c = instofAcc.id;
insert bc;

Case caseObj1 = new Case();
caseObj1 = new Case();
caseObj1.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('GDPR Request').getRecordTypeId();
//caseObj.Product_Type__c = 'Event Tool';
caseObj1.Status = 'Open';
caseObj1.Origin = 'Web2Case';
caseObj1.Minutesoncase__c = 30; 
caseObj1.AccountId=instofAcc.Id;
caseObj1.Type = 'Do Not Call';
caseObj1.Developer_Use_GDPR__c = 'WebToCase-GDPR';
caseObj1.subject='Your recent Invoice: TestCaseSegeration';
caseObj1.subject='Your recent Invoice: TestCaseSegeration';
caseObj1.SuppliedName='Test Udita';
caseObj1.SuppliedEmail='invoices@cvent.com';
caseObj1.description='Please create Salesforce account for the following new hire by 2/12/2018 :';
insert caseObj1;


}
    
    
   
    
}