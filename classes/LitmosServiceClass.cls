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
                    userRec.ShowLitmosTab__c=true;
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
    public static void assignTeamToLitmosUser(set<string> litmusUserId,set<Id> UserIdSet){  
        System.debug('Inside Future Method');
        
        String teamsId = Label.Litmos_Teams_Id;
        String APIKey = Label.Litmos_API_Key;
        String bodyValue = '<Users>';
        String endpoint = 'https://api.litmos.com/v1.svc/teams/'+teamsId+'/users?apikey='+APIKey+'&source=Cvent';
        for(string litmosId : litmusUserId){
            bodyValue = bodyValue + '<User><Id>'+litmosId+'</Id></User>';
        }
        bodyValue = bodyValue + '</Users>';
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
        //Inseting the result in the Litmos Integration Console Object......
        
        Litmos_Integration_Console__c licObject = new Litmos_Integration_Console__c();
        
        licObject.JSON_User_Id__c = JSON.serialize(litmusUserId);
        licObject.Litmos_Integration_Body__c = bodyValue;
        licObject.Success_Error_Result_Log__c = JSON.serialize(res.getStatusCode() +' // '+res.getStatus());
        licObject.Integrated_User_Count__c = litmusUserId.size();
        if(!test.isRunningTest()){
        
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
    }
}