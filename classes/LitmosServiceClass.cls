/*
**************
Author : HSR
Created Date : 07/08/2018
Description : As soon as the Community users will be created it will get it synced with the Litmos on the basis of some conditions and attach to a specific Teams.
**************
*/
public class LitmosServiceClass{
    public static void syncCommunityUserInLitmos_Clone(List<User> userList){
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> accountIdCompareSet = new Set<Id>();
        List<Opportunity> oppLineList = new List<Opportunity>();
        Litmos_Integration_Console__c licObject;
        List<Litmos_Integration_Console__c> licObjectList = new List<Litmos_Integration_Console__c> ();
        For(User userRec : userList)
        {
            if(userRec.Account_Id_Dev__c!=null)
                accountIdSet.add(userRec.Account_Id_Dev__c);
        }
        accountIdSet.remove(null);
        System.debug('accountIdSet********'+accountIdSet);
        if(accountIdSet.size()>0)
        {
            //fetching the data from report Current Event Cloud Client_for CS..........   
            if(!Test.isRunningTest()){
                For(Opportunity oppRec : [select id,Account.Account_18_digit_id__c,(select id from OpportunityLineItems where Product2.Product_Group__c ='Event Cloud' and Product2.Product_Family__c ='Event' and
                                                                     (Product2.Name ='Professional License - Event Management' or Product2.Name ='Enterprise License' or 
                                                                      Product2.Name ='Enterprise License - Event Management' or Product2.Name ='Professional License' or Product2.Name ='Maintenance Fee') limit 1 ) 
                           from Opportunity where AccountId IN:accountIdSet AND Opportunity_Start_Date__c <= Today and Opp_End_Date__c > today ORDER BY CreatedDate DESC LIMIT 40000])
               {
                   if(oppRec.OpportunityLineItems.size() > 0)
                    accountIdCompareSet.add(oppRec.Account.Account_18_digit_id__c);
               }
            }
            else{
                For(Opportunity oppRec : [select id,Account.Account_18_digit_id__c,(select id from OpportunityLineItems limit 1) from  Opportunity LIMIT 1])
                {
                    accountIdCompareSet.add(oppRec.Account.Account_18_digit_id__c);
                }
              
            }   
        }
        
        if(accountIdCompareSet.size()>0)
        {
            For(User userRec : userList)
            {
                if(accountIdCompareSet.contains(userRec.Account_Id_Dev__c))
                {
                    userRec.Litmos__Sync_Litmos__c = true;
                   // userRec.ShowLitmosTab__c=true;  // commented by udita
                     //Inserting  Litmos Console Object to keep track...............
                    licObject = new Litmos_Integration_Console__c();
                    licObject.User_Id__c = 'User Checked true';
                    licObjectList.add(licObject);
                }
                else{
                     //Inserting  Litmos Console Object to keep track...............
                    licObject = new Litmos_Integration_Console__c();
                    licObject.User_Id__c = 'No User Check'+userRec.Account_Id_Dev__c;
                    licObjectList.add(licObject);
                }
            }
            System.debug('licObjectList******'+licObjectList);
            System.debug('licdsfObject******'+licObjectList.size());
            if(!test.isRunningTest() && licObjectList.size()>0){
                insert licObjectList;
            }
        }
    }
    public static void assignPermissionSet(set<Id> UserIdSet){

        //Assign Permission Set to this user....
        List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
        PermissionSet permissionSetRec = [SELECT Id FROM PermissionSet WHERE Name = 'Litmos_Login_Access' LIMIT 1];
        For(PermissionSetAssignment PSA : [SELECT AssigneeId,Id FROM PermissionSetAssignment WHERE Id IN : UserIdSet]){
            UserIdSet.remove(PSA.AssigneeId);
        }
        if(UserIdSet.size()>0){
            For(Id userId : userIdSet){
                PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = permissionSetRec.Id, AssigneeId = userId);
                permissionSetList.add(psa);
            }
            System.debug('permissionSetList************'+permissionSetList);
            if(permissionSetList.size() > 0){
                try{
                    Database.insert (permissionSetList);
                }
                catch(Exception ex){
                    System.debug('Exception Track'+ex);
                    }
                }
        } 
    }
    @future(Callout=true)
    public static void assignTeamToLitmosUser(set<string> litmusUserId,set<Id> UserIdSet,set<id>accIdSet){  
        MAP<ID,MAP<string,List<Mobile_Card__c>>> mobileCardVsRecType= new MAP<ID,MAP<string,List<Mobile_Card__c>>>() ;
        list<user> userList = new list<user>();
        list<Litmos_Integration_Console__c > litmosIntegrationLst = new list<Litmos_Integration_Console__c >();
        String teamsId1;
        String teamsId2;
        String teamsId3;
         for(Mobile_Card__c mob : [select id,Contract_Account_New__c,RecordType.name from Mobile_Card__c where Contract_Account_New__c  in: accIdSet and (RecordType.name ='Mobile - Onboarding Standard' or  RecordType.name='Mobile - Onboarding Lite')]){
              if(!mobileCardVsRecType.containsKey(mob.Contract_Account_New__c)){
                   mobileCardVsRecType.put(mob.Contract_Account_New__c,new map<string,List<Mobile_Card__c>>());
                 }
              if(!mobileCardVsRecType.get(mob.Contract_Account_New__c).containsKey(mob.RecordType.name)){
                mobileCardVsRecType.get(mob.Contract_Account_New__c).put(mob.RecordType.name,new List<Mobile_Card__c>());
              }
              mobileCardVsRecType.get(mob.Contract_Account_New__c).get(mob.RecordType.name).add(mob);
         }     
        system.debug('----mobileCardVsRecType'+mobileCardVsRecType);   
        System.debug('Inside Future Method');
        
        userList = [select id,Litmos__LitmosUserId__c,Account_Id_Dev__c from user where id in : UserIdSet];
        for( user u : userList){
          String APIKey = Label.Litmos_API_Key;
          if(mobileCardVsRecType.containsKey(u.Account_Id_Dev__c)){
            if(mobileCardVsRecType.get(u.Account_Id_Dev__c).size() > 1){
              if(mobileCardVsRecType.get(u.Account_Id_Dev__c).containsKey('Mobile - Onboarding Lite')){
                 teamsId1 = '927545';
              }
              if(mobileCardVsRecType.get(u.Account_Id_Dev__c).containsKey('Mobile - Onboarding Standard')){
                 teamsId2 = '927548';
              }
            }        
            else{
                 teamsId3 = Label.Litmos_Teams_Id;
            }   
          }
          else{
                 teamsId3 = Label.Litmos_Teams_Id;
          }
        system.debug('*****teamsId1 '+teamsId1);
        system.debug('*****teamsId2 '+teamsId2);
        system.debug('*****teamsId3 '+teamsId3);  
        String bodyValue = '<Users>';
        bodyValue = bodyValue + '<User><Id>'+u.Litmos__LitmosUserId__c +'</Id></User>';
        bodyValue = bodyValue + '</Users>';
        
        /****** Creating Litmos console object *****/
        Litmos_Integration_Console__c licObject = new Litmos_Integration_Console__c();
        licObject.JSON_User_Id__c = JSON.serialize(u.Litmos__LitmosUserId__c);
        licObject.Litmos_Integration_Body__c = bodyValue;
        
        if(teamsId1 != null){
           String endpoint = 'https://api.litmos.com/v1.svc/teams/'+teamsId1+'/users?apikey='+APIKey+'&source=Cvent';
           Httprequest req =  new Httprequest();
           req.setEndpoint(endpoint);
           req.setBody(bodyValue);
           req.setHeader('Content-Type','application/xml');
           req.setMethod('POST');
           Http http = new Http();
           HTTPResponse res = new HTTPResponse();
           if(!test.isRunningTest()){
                res = http.send(req);
                system.debug(res.getStatusCode());
                system.debug(res.getStatus());
           }
           System.debug('res************'+res);
           //Litmos console object 
           licObject.Success_Error_Result_Log__c = JSON.serialize(res.getStatusCode() +' //1 '+res.getStatus());
        }
        if(teamsId2 != null){
           String endpoint2 = 'https://api.litmos.com/v1.svc/teams/'+teamsId2+'/users?apikey='+APIKey+'&source=Cvent';
           Httprequest req1 =  new Httprequest();
           req1.setEndpoint(endpoint2);
           req1.setBody(bodyValue);
           req1.setHeader('Content-Type','application/xml');
           req1.setMethod('POST');
           Http http1 = new Http();
           HTTPResponse res1 = new HTTPResponse();
           if(!test.isRunningTest()){
                res1 = http1.send(req1);
                system.debug(res1.getStatusCode());
                system.debug(res1.getStatus());
           }
           System.debug('res1************'+res1);
           //Litmos console object 
           licObject.Success_Error_Result_Log__c = licObject.Success_Error_Result_Log__c + JSON.serialize(res1.getStatusCode() +' //2 '+res1.getStatus());
        }
       /* if(teamsId3 != null){
           String endpoint3 = 'https://api.litmos.com/v1.svc/teams/'+teamsId3+'/users?apikey='+APIKey+'&source=Cvent';
           Httprequest req2 =  new Httprequest();
           req2.setEndpoint(endpoint3);
           req2.setBody(bodyValue);
           req2.setHeader('Content-Type','application/xml');
           req2.setMethod('POST');
           Http http2 = new Http();
           HTTPResponse res2 = new HTTPResponse();
           if(!test.isRunningTest()){
                res2 = http2.send(req2);
                system.debug(res2.getStatusCode());
                system.debug(res2.getStatus());
           }
           System.debug('res2************'+res2);
           //Litmos console object 
           licObject.Success_Error_Result_Log__c = licObject.Success_Error_Result_Log__c +  JSON.serialize(res2.getStatusCode() +' //3 '+res2.getStatus());
        }     */  
        //Inseting the result in the Litmos Integration Console Object......
                
        licObject.Integrated_User_Count__c = litmusUserId.size();      
        litmosIntegrationLst.add(licObject);
      }  
       if(!test.isRunningTest() && litmosIntegrationLst.size() > 0){
            insert litmosIntegrationLst;
        }       
    }
    
}