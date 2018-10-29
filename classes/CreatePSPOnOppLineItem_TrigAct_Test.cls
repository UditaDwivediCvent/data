/**
* Author : Sandeep Kumar
* Date : 12 April, 2017
* Description : It tests below mentioned classes
* 1) CreatePSPOnOppLineItemInsertion_TrigAct
* 2) EBProjectUpdatePendingHrsForCompletion
* 3) EBProjectAssignmentRollup_TrigAct
*/
@isTest(seeAllData= true)
public class CreatePSPOnOppLineItem_TrigAct_Test {    
    private static Opportunity opp;
    private static Account acc,acc1; 
    private static Contact con;
    private static Professional_Services_Project__c PSP;
    private static User testUser;
    private static List<User> userList;
    private static List<EB_Agent_Profile__c> eBAgentProfileList;
    private static List<PricebookEntry> pbeList;
    private static User depUser = [Select Id, ProfileId from User where Name = 'CRM Deployment User'];
    private static Id userProfieId = UserProfileUtil.getProfileIDByName('Customer Care Rep - Product Consultant EB Team');    
    
    public static void setupData() {
        userList = new List<User>();
        // Create Salesforce Users for which will be assigned to EB Agent Profile later.
        User usr1 = TestUtil.createUser(userProfieId);
        usr1.username= 'CreatePSPOnOppLineItem_TrigAct_Test@test.com';
        userList.add(usr1);
        User usr2 = TestUtil.createUser(userProfieId);
        usr2.username= 'CreatePSPOnOppLineItem_TrigAct_Test2@test.com';
        userList.add(usr2);
        User usr3 = TestUtil.createUser(userProfieId);
        usr3.username= 'CreatePSPOnOppLineItem_TrigAct_Test3@test.com';
        userList.add(usr3);
        User usr4 = TestUtil.createUser(userProfieId);
        usr4.username= 'CreatePSPOnOppLineItem_TrigAct_Test4@test.com';
        userList.add(usr4);
        User usr5 = TestUtil.createUser(userProfieId);
        usr5.username= 'CreatePSPOnOppLineItem_TrigAct_Test5@test.com';
        userList.add(usr5);
        User usr6 = TestUtil.createUser(userProfieId);
        usr6.username= 'CreatePSPOnOppLineItem_TrigAct_Test6@test.com';
        userList.add(usr6);
        User usr7 = TestUtil.createUser(userProfieId);
        usr7.username= 'CreatePSPOnOppLineItem_TrigAct_Test7@test.com';
        userList.add(usr7);
        
        insert userList;  
        
        eBAgentProfileList = new List<EB_Agent_Profile__c>();
        // Create EB Agent Profile Records.   
        EB_Agent_Profile__c EBAgentProfile1 = TestUtil.createEBAgentProfile('Profile 1',userList[0].Id,'Low - 1');
        eBAgentProfileList.add(EBAgentProfile1);
        EB_Agent_Profile__c EBAgentProfile2 = TestUtil.createEBAgentProfile('Profile 2',userList[1].Id,'Med - 2');
        eBAgentProfileList.add(EBAgentProfile2);
        EB_Agent_Profile__c EBAgentProfile3 = TestUtil.createEBAgentProfile('Profile 3',userList[2].Id,'Top - 3');
        eBAgentProfileList.add(EBAgentProfile3);
        EB_Agent_Profile__c EBAgentProfile4 = TestUtil.createEBAgentProfile('Profile 4',userList[3].Id,'ARA - Inactive');
        eBAgentProfileList.add(EBAgentProfile4);
        EB_Agent_Profile__c EBAgentProfile5 = TestUtil.createEBAgentProfile('Profile 5',userList[4].Id,'ARA - Active');
        eBAgentProfileList.add(EBAgentProfile5);
        EB_Agent_Profile__c EBAgentProfile6 = TestUtil.createEBAgentProfile('Profile 6',userList[5].Id,'Enterprise Project1');
        eBAgentProfileList.add(EBAgentProfile6);
        EB_Agent_Profile__c EBAgentProfile7 = TestUtil.createEBAgentProfile('Profile 7',userList[6].Id,'Event Quarterback Project');        
        eBAgentProfileList.add(EBAgentProfile7);        
        insert eBAgentProfileList;          
        
        // Create Account Record.
        acc1 = TestUtil.createAccount('EB Account 2', 'Biz_Ac');
        insert acc1;
        
        // Create Contact Record.
        con = TestUtil.createContact(acc.id);
        insert con;
        
        // Create Product Record.
        List<Product2> products =  TestUtil.createProducts(new List<String>{'Event Builder(s) - Complex with Mobile','Event Builder(s) - Complex','Event Builder(s) - Medium','  Event Builder(s) - Advanced + Event Quarterback','Event Builder(s) - Express'});
        insert products;
        
        pbeList = new List<PricebookEntry>();        
        PricebookEntry pbe1 =  TestUtil.createPricebookEntry(products[0],200);
        pbeList.add(pbe1);
        PricebookEntry pbe2 =  TestUtil.createPricebookEntry(products[1],400);
        pbeList.add(pbe2);
        PricebookEntry pbe3 =  TestUtil.createPricebookEntry(products[2],200);
        pbeList.add(pbe3);                
        insert pbeList;   
        
        Opportunity o1 = TestUtil.createOpportunity('testOpp','Event','Bid Phase');
        o1.Contact_Associated__c = con.Id;
        o1.AccountId = acc.Id;
        o1.Event_Planner_Name__c = 'test User';
        o1.Event_Planner_Email__c = 'testuser@cvent.com';
        o1.Contract_Implemented__c = false;
        o1.CloseDate = Date.today().addDays(80);
        insert o1;
        
        OpportunityLineItem oli1 = TestUtil.createOpportunityLineItems(o1,pbe1);
        OpportunityLineItem oli2 = TestUtil.createOpportunityLineItems(o1,pbe2);
        OpportunityLineItem oli3 = TestUtil.createOpportunityLineItems(o1,pbe3);
        
        insert new List <OpportunityLineItem> {oli1,oli2,oli3};
            
            opp = [select id, amount from opportunity where id = :o1.id];
    }
    // Creates new PSP record in Salesforce.
    static testMethod void createNewEBSBProjectsOnOppClosure(){
        System.runAs(depUser){
            // Create Account Record.
            acc = TestUtil.createAccount('EB Account', 'Biz_Ac');
            insert acc;           
            // Call SetupData Method
            setupData();
            system.debug('====SOQL 1======'+LIMITS.getLimitQueries());
            
            Test.startTest();            
            opp.StageName = 'Closed Won';
            opp.Contract_Implemented__c = true;
            opp.Contract_Number_New__c = '123456';
            update opp;
            Test.stopTest();  
        }      
    }
    
    // create new PSP and EBSB Project for ARA Account
    static testMethod void createEBSBProjectsOnOppClosure(){
        System.runAs(depUser){
            // Create Account Record.
            acc = TestUtil.createAccount('EB Account 1', 'Biz_Ac');
            acc.Active_ARA__c = true;
            insert acc;
            
            ARA__c araObj = new ARA__c();
            araObj.Account__c =acc.Id;
            araObj.Status__c = 'Open';
            insert araObj;
            
            // Create PSP record.
            PSP = new Professional_Services_Project__c();
            PSP.Account__c = acc.Id;
            PSP.of_EB__c = 2;
            insert PSP;       
            // Call SetupData Method
            setupData();
            Test.startTest();            
            opp.StageName = 'Closed Won';
            opp.Contract_Number_New__c = '123456';
            opp.Contract_Implemented__c = false;
            update opp;
            Test.stopTest();  
        }      
    }   
    
    // Updates exisitng PSP record in Salesforce.
    static testMethod void updateExistingEBSBProjectsOnOppClosure(){
        System.runAs(depUser){
            // Create Account Record.
            acc = TestUtil.createAccount('EB Account 1', 'Biz_Ac');
            acc.Active_ARA__c = true;
            insert acc;
            
            ARA__c araObj = new ARA__c();
            araObj.Account__c =acc.Id;
            araObj.Status__c = 'Open';
            insert araObj;
            
            // Create PSP record.
            PSP = new Professional_Services_Project__c();
            PSP.Account__c = acc.Id;
            PSP.of_EB__c = 2;
            insert PSP;       
            // Call SetupData Method
            setupData();
            Test.startTest();            
            opp.StageName = 'Closed Won';
            opp.Contract_Number_New__c = '123456';
            opp.Contract_Implemented__c = true;
            update opp;
            Test.stopTest();  
        }      
    }     
}