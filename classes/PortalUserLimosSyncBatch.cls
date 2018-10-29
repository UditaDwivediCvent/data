/**=====================================================================
    * Cvent
    * Name: PortalUserLimosSyncBatch
    * Description: Batch Class for Syncing Portal User with Litmos
    * Created Date: [11/23/2017]
    * Created By: Hemant Rana
    * 
    * Date Modified                Modified By                  Description of the update
    * [MON DD, YYYY]               [FirstName LastName]         [Short description for changes]
**======================================================================
*/
global class PortalUserLimosSyncBatch implements Database.Batchable<sObject>,Database.Stateful{
    
    List<User> userObjUpdate;
    Id litmosPermissionSetId;
    List<PermissionSetAssignment>  permissionAssignList;
    PermissionSetAssignment psa;
    Integer userSynced;
    String query;
    global PortalUserLimosSyncBatch(){
        userSynced = 0;
        litmosPermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Litmos_Login_Access' LIMIT 1].Id;
    }
    global Database.querylocator start(Database.BatchableContext BC){
        if(!Test.isRunningTest())
            query = 'SELECT Id,Litmos__Sync_Litmos__c FROM User WHERE IsActive = TRUE AND IsPortalEnabled = TRUE AND Profile_Name__c = '+'\''+'Cvent Customer Community User'+'\''+' AND Litmos__Litmos_Activated__c = FALSE AND Litmos__Sync_Litmos__c = FALSE';// LIMIT 10
        else
            query = 'SELECT Id,Litmos__Sync_Litmos__c FROM User WHERE IsActive = TRUE AND IsPortalEnabled = TRUE AND Profile_Name__c = '+'\''+'Cvent Customer Community User'+'\''+' AND Litmos__Litmos_Activated__c = FALSE AND Litmos__Sync_Litmos__c = FALSE LIMIT 10';
        System.debug('query***************'+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<User> scope){
        userObjUpdate = new List<User>();
        permissionAssignList = new List<PermissionSetAssignment>();
        For(User userRec : scope)
        {
            userRec.Litmos__Sync_Litmos__c = TRUE;
            userObjUpdate.add(userRec);
            
            psa = new PermissionSetAssignment(PermissionSetId = litmosPermissionSetId, AssigneeId = userRec.Id);
            permissionAssignList.add(psa);
        }
        Database.SaveResult[] userObjList = Database.update(userObjUpdate, false);
        Database.SaveResult[] permissionAssignListInsert = Database.insert(permissionAssignList, false);
        userSynced = userSynced + userObjList.size();
    }
    global void finish(Database.BatchableContext BC){
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Name , ExtendedStatus  from AsyncApexJob where Id = :BC.getJobId()]; 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
        String[] toAddresses = new String[] {a.CreatedBy.Email,'hrana@cvent.com'};  
        mail.setToAddresses(toAddresses);  
        mail.setSubject('Portal User Litmos Sync Status: ' + a.Status);
        String body='<span style='+'\''+'color:#1F497D; font-size:11.0pt;font-family:"Calibri",sans-serif;'+'\''+'><b>Hi '+a.CreatedBy.Name+',  </b></br></br>Total <b>'+userSynced+'</b> Portal User has been synced with Litmos.</br></br><b>Total Batch Processed:</b> '+a.JobItemsProcessed+'</span></br><span style='+'\''+'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#000000'+'\''+'><b></br>Thanks,</br>'+'Salesforce'+'<o:p></o:p></b></span>';
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}