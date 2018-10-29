@isTest
Public Class UserTriggerHandler_Test{
// ===============================
// AUTHOR     : Shanu Aggarwal    
// CREATED DATE     : 02/03/2016
// PURPOSE     :  To Test Handler
// TRIGGER :     UserTrigger
// CLASS : UserTriggerHandler
// SPECIAL NOTES:
// ===============================
// Change History:
// HSR : 30th Jan 2018 : Added test method for "updateInactiveuserFields"/"removePackageLicense" method in "UserTriggerHandler"
//==================================
    @testsetup
    public static void createUserHistory(){
    //Inserting Quota Type
    Quota__c qType = new Quota__c();
    qType.Name = 'NBB Quota';
    qType.Comments__c = 'Test Comments';
    
    Insert qType;
    
    Quota_User_History__c qHistory = new Quota_User_History__c();
    qHistory.Effective_Date__c =  Date.Today();
    qHistory.Is_Current__c = true;
                    
    qHistory.User__c = UserInfo.getUserId(); 
    qHistory.Title__c = 'Salesforce Developer';
    qHistory.Role__c =  'Sales Dev';
    
    insert qHistory;
    }
    public static testmethod void BeforeUpdateTest(){
        
        User u = [ Select Title from User Where Id =:UserInfo.getUserId()];
        u.Title= 'Sr. Salesforce Developer' ;
        Update u;
    }
    //Test method for "removePackageLicense" & "updateInactiveuserFields" methods
    public static testmethod void removePackageLicenseTest(){
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        //Fetching User from the TestUtil Class......
        User userRec = TestUtil.createUser(profileId);
        insert userRec;
        //Deactivating User....
        userRec.IsActive = False;
        update userRec;
    }
}