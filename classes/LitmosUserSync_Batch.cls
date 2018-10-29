/**@author Hemant Rana
Batch Class for Syncing Litmos User with Salesforce in bulk.....
Version 1.0
Date: 23rd Sep 2018
*/
global class LitmosUserSync_Batch implements Database.Batchable<sObject>,Database.Stateful{
    global String query;
    global Set<Id> accIdSet;
    global List<User> userList;
    global integer syncCount =0;
    global Database.querylocator start(Database.BatchableContext BC){
        if(test.isRunningTest())
        {
            query = 'SELECT Id,Account.Account_18_digit_id__c,(SELECT Id FROM OpportunityLineItems) FROM Opportunity LIMIT 1';
        }
        else{
            query = 'select id,Account.Account_18_digit_id__c,(select id from OpportunityLineItems where Product2.Product_Group__c =\''+'Event Cloud'+'\''+' and Product2.Product_Family__c =\''+'Event'+'\''+' and (Product2.Name ='+'\''+'Professional License - Event Management'+'\''+' or Product2.Name ='+'\''+'Enterprise License'+'\''+' or Product2.Name ='+'\''+'Enterprise License - Event Management'+'\''+' or Product2.Name =\''+'Professional License'+'\''+' or Product2.Name =\''+'Maintenance Fee'+'\''+') limit 1 ) from Opportunity where Opportunity_Start_Date__c <= Today and Opp_End_Date__c > today';
        }
        System.debug('query===>'+query); 
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        accIdSet = new Set<Id>();
        userList = new List<User>();
        for(Opportunity oli : scope){
            if(oli.OpportunityLineItems.size() > 0){                  
                accIdSet.add(oli.Account.Account_18_digit_id__c);  
            }      
        } 
        if(accIdSet.size()>0){
            For(User userRec : [SELECT Email,Id,Litmos__Sync_Litmos__c,ShowLitmosTab__c FROM User WHERE Account_Id_Dev__c IN : accIdSet AND ProfileId = '00eo00000016QNc' AND IsActive = TRUE AND IsPortalEnabled = TRUE AND Litmos__LitmosUserId__c = null AND Litmos__Deactivate_From_Litmos__c = FALSE])
            {
                userRec.Litmos__Sync_Litmos__c = TRUE;
                userRec.ShowLitmosTab__c= TRUE;
                userList.add(userRec);
            }
            if(userList.size()>0)
                Database.update(userList);
            syncCount = syncCount+ userList.size();
        }
    }
    global void finish(Database.BatchableContext BC){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
        String[] toAddresses = new String[] {'hrana@cvent.com'};  
        mail.setToAddresses(toAddresses);  
        mail.setSubject('Litmos Sync completed');  
        //mail.setPlainTextBody('The batch Apex job processed ' + a.JobItemsProcessed);
        String body='Total Number of User Synced:'+syncCount;
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        /*
        Send an email notification about Batch Completion.
        */
    }
}