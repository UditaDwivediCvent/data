public class UserTriggerHandler{

// ===============================
// AUTHOR     : Shanu Aggarwal    
// CREATED DATE     : 02/03/2016
// PURPOSE     :  To handle user trigger methods
// TEST CLASS :   UserTriggerHandler_Test
// SPECIAL NOTES:
// ===============================
// Change History:
// HSR : 30th Jan 2018 : Removing Package License for Inactive User
// HSR : 30th Jan 2018 : Updating fields for Inactive User
// ===============================
    
    
    //Before Insert
    public void OnBeforeInsert( List<User> newValues ){
      List<User> litmosUserList = new List<User>();
      //fetch all the users with profile 'Cvent Customer Community User'....
      Profile profileRec = [SELECT Id FROM Profile WHERE Name = 'Cvent Customer Community User'];
      for(user u : newValues){
         if(u.ProfileId==profileRec.Id){
             litmosUserList.add(u);
         }
       }  
       System.debug('litmosUserList********'+litmosUserList);
       System.debug('litmosUserList********'+litmosUserList.size());
       if(litmosUserList.size() > 0 && Label.IsLitmosIntegrationActive=='True'){
            String litmosUserListJSONParsed = JSON.serialize(litmosUserList);//User list paresed into JSON as you cannot pass List<sObject> in future methods
            //LitmosServiceClass.syncCommunityUserInLitmos(litmosUserListJSONParsed);
            LitmosServiceClass.syncCommunityUserInLitmos_Clone(litmosUserList);
        }
    }
    
    public void OnAfterInsert( Map<Id,User> newMap){ 
    }
    
    //Before Update
    public void OnBeforeUpdate( Map<Id,User> newMap , Map<Id,User> oldMap ){
        /*HSR : 30th Jan 2018 : Updating fields for Inactive User */
        if(Label.IsRemoveLicensePackage=='True')
            updateInactiveuserFields(newMap , oldMap);
            
          /* udita: for marking user GDPR */
        User oldUserValue;
        For(User userObj : newMap.values())
        {  
            oldUserValue = oldMap.get(userObj.Id);
            if(userObj.Is_GDPR__c && userObj.Is_GDPR__c != oldUserValue.Is_GDPR__c)
            {
            userObj.FirstName = 'GDPR First Name';
            userObj.LastName = 'GDPR Last Name';
            userObj.Email = 'GDPR@GDPR.com';
            userObj.Phone = '';
            userObj.UserName= 'GDPR@GDPR.com'+Math.Random();
            userObj.MobilePhone = '';
            userObj.Title= 'GDPR';
            }
            
        }
       /*GDPR code ends*/  
    }
    //After Update    
    public void OnAfterUpdate( Map<Id,User> newMap , Map<Id,User> oldMap ){
           
        Set<ID> userIds = new Set<ID>();
        
        for( User u : [ Select Id, UserRole.Name, Title From User Where ID IN: newMap.values() and isActive=true ] ){
            userIds.add(u.Id);
        }
        if(userIds.size()>0 && System.IsBatch() == false && System.isFuture() == false) //System.isFuture() == false added by udita for executing GDPRCentralRepositoryHandler class
            CreateHistoryForExistingUser(userIds);
        /*HSR : 30th Jan 2018 : Removing Package License for Inactive User */
        if(Label.IsRemoveLicensePackage=='True')
            removePackageLicense(newMap,oldMap);
            
        //Udita : Code for assigning team to litmos user's
       
       set<string> litmusUserId = new set<string>();
       set<Id> UserIdSet = new set<Id>();
       for(user u : newMap.values()){
           if(u.Litmos__LitmosUserId__c != null && u.Litmos__LitmosUserId__c != oldMap.get(u.id).Litmos__LitmosUserId__c){
               litmusUserId.add(u.Litmos__LitmosUserId__c);
               UserIdSet.add(u.Id);
           }
      } 
      System.debug('litmusUserId*****'+litmusUserId);       
      System.debug('UserIdSet****'+UserIdSet);       
      litmusUserId.remove(null);
      if(litmusUserId.size() > 0 && UserIdSet.size()>0 && Label.IsLitmosIntegrationActive=='True'){
         LitmosServiceClass.assignPermissionSet(UserIdSet);
         LitmosServiceClass.assignTeamToLitmosUser(litmusUserId,UserIdSet);
      }  
      // code ends  
    }
    
    
       /* METHODS */
    
    //Method to Insert Quota History If Existing User Role/Title/EffectiveDate is changed
    @future(Callout=true)
    public static void CreateHistoryForExistingUser(Set<Id> uIds){
    
        List<Quota_User_History__c> qHistoryUpdateList = new List<Quota_User_History__c>();
        Map<Id,Quota_User_History__c> qHistoryMap = new Map<Id,Quota_User_History__c>();
        
        //Getting Quota User History current record from updating user
        for( Quota_User_History__c q : [ Select Id , Is_Current__c, User__c, Role__c ,  Title__c  From Quota_User_History__c Where User__c IN: uIds and Is_Current__c= True ]){
            qHistoryMap.put(q.User__c, q);  
        }
        
        
        for( User u : [ Select UserRole.Name, Title From User Where ID IN: uIds ] ){
            
            Quota_User_History__c qUserExist = qHistoryMap.Get(u.Id);
            
            //if updating user is exist in Quota User History table 
            if( qUserExist!=null ){
                 qUserExist.Role__c = u.UserRole.Name ;
                 qUserExist.Title__c =  u.Title ;
                 qHistoryUpdateList.Add(qUserExist);
            }
            
            system.debug('******* qHistoryUpdateList ***** ' + qHistoryUpdateList);
            if(qHistoryUpdateList.size()>0)
            Update qHistoryUpdateList;
        }
        
    }
    
    /*HSR : 30th Jan 2018 : Updating fields for Inactive User */
    public static void updateInactiveuserFields(Map<Id,User> newMap , Map<Id,User> oldMap){
        User oldUserValue;
        For(User userObj : newMap.values())
        {
            oldUserValue = oldMap.get(userObj.Id);
            if(!userObj.IsActive && userObj.IsActive!=oldUserValue.IsActive)
            {
                userObj.UserPermissionsAvantgoUser            = false;    
                userObj.UserPermissionsCallCenterAutoLogin    = false;
                userObj.UserPermissionsChatterAnswersUser     = false;
                userObj.UserPermissionsInteractionUser        = false;
                userObj.UserPermissionsJigsawProspectingUser  = false;
                userObj.UserPermissionsKnowledgeUser          = false;
                userObj.UserPermissionsLiveAgentUser          = false;
                userObj.UserPermissionsMarketingUser          = false;
                userObj.UserPermissionsMobileUser             = false;
                userObj.UserPermissionsOfflineUser            = false;
                userObj.UserPermissionsSFContentUser          = false;
                userObj.UserPermissionsSupportUser            = false;
                userObj.UserPermissionsWorkDotComUserFeature  = false;
            }
        }
    }
    /*HSR : 30th Jan 2018 : Removing Package License for Inactive User */
    public static void removePackageLicense(Map<Id,User> newMap , Map<Id,User> oldMap){
        List<User> listOfInactiveUser=new List<User>();   //  create list to update user instead of update Inactiveuser as if we update Inactiveuser ,it will not reflect any change.
        User oldUserValue;
        For(User userObj : newMap.values())
        {
            oldUserValue = oldMap.get(userObj.Id);
            if(!userObj.IsActive && userObj.IsActive!=oldUserValue.IsActive)
            {
                listOfInactiveUser.add(userObj);
            }
        }
        //Delete Assigned Licenses for Managed Packages
        if(listOfInactiveUser.size()>0){
            List<UserPackageLicense> assignedLicenseList = [ Select Id From UserPackageLicense Where UserId IN: listOfInactiveUser ];
            if(assignedLicenseList.size()>0)
                delete assignedLicenseList;
        }
    }
}