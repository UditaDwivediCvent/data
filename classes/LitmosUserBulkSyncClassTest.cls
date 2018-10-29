@istest
public class LitmosUserBulkSyncClassTest{
    // this method is for class : LitmosUserBulkSyncClass
    public static String[] csvFileLines;
    public static Blob csvFileBody;

    public static testMethod void LitmosUserBulkSyncMethod(){
        User userObj = [SELECT Email,Id,Litmos__Sync_Litmos__c,ShowLitmosTab__c FROM User WHERE IsActive = TRUE AND IsPortalEnabled = TRUE AND Litmos__Litmos_Activated__c = null LIMIT 1];
        String str = 'EmailId \n '+userObj.email; 
        csvFileBody = Blob.valueOf(str);
        String csvAsString = csvFileBody.toString();
        csvFileLines = csvAsString.split('\n');
        
        LitmosUserBulkSyncClass scrub = new LitmosUserBulkSyncClass();
        scrub.csvFileBody = csvFileBody;
        scrub.compareRecords();

    }
}