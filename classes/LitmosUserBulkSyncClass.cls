/* ===============================
AUTHOR     :     Hemant Rana
CREATED DATE   : 22 Sep 2018
PURPOSE     :    This will help to upload the excel sheet with community user email id which will then make them sync with Litmos.
TEST CLASS :     LitmosUserBulkSyncClassTest
============================= 
*/
public class LitmosUserBulkSyncClass{
public Blob csvFileBody{get;set;}
public string csvAsString{get;set;}
public String[] csvFileLines{get;set;}
public Set<String> emailSet{get;set;}
public Set<String> emailSetV{get;set;}
public Map<String,Boolean> emailVsGDPRMap{get;set;}
public string contentType { get; set; }


  public LitmosUserBulkSyncClass(){
    contentType = 'text/html';
    csvFileLines = new String[]{};
    emailSet = New Set<String>(); 
    emailSetV = New Set<String>(); 
    emailVsGDPRMap = New Map<String,Boolean>();
  }
  
  public void compareRecords(){
       try{
           contentType = 'application/vnd.ms-excel#RecordsNotSynced.csv';
           csvAsString = csvFileBody.toString();
           csvFileLines = csvAsString.split('\n'); 
            
           for(Integer i=1;i<csvFileLines.size();i++){
               string[] csvRecordData = csvFileLines[i].split(',');
                
               for(string s : csvRecordData){
                 emailSet.add(s.trim());  
               }
           }
           
           For(String ss : emailSet){
                 emailSetV.add(ss.trim());
           }
           System.debug('emailSetV**********'+emailSetV);
           if(emailSetV.size()>0){
               List<User> userObjList = new List<User>();
               List<Litmos_Integration_Console__c> litmosIntegtaionConsoleObjList = new List<Litmos_Integration_Console__c>();
               Litmos_Integration_Console__c litmosIntegtaionConsoleObj = new Litmos_Integration_Console__c();
               For(User userObj : [SELECT Email,Id,Litmos__Sync_Litmos__c,ShowLitmosTab__c FROM User WHERE Email IN : emailSetV AND ProfileId = '00eo00000016QNc' AND IsActive = TRUE AND IsPortalEnabled = TRUE AND Litmos__LitmosUserId__c = null])
               {
                   //Updating user record for Litmos Syncing....
                   userObj.Litmos__Sync_Litmos__c = TRUE;
                   userObj.ShowLitmosTab__c = TRUE;
                   userObjList.add(userObj);
                   
                   //Creating records in the Integartion Console........
                   litmosIntegtaionConsoleObj = new Litmos_Integration_Console__c();
                   litmosIntegtaionConsoleObj.Litmos_Bulk_User_Email__c = userObj.Email;
                   litmosIntegtaionConsoleObj.Litmos_Bulk_User_Id__c= userObj.Id;
                   litmosIntegtaionConsoleObj.IsUploadedFromLitmosUserBulkSync__c= TRUE;
                   litmosIntegtaionConsoleObjList.add(litmosIntegtaionConsoleObj);
                   
                   //Creating list of email that doesn't found in the Salesforce Org.....
                   if(emailSetV.contains(userObj.Email))
                   {
                       emailSetV.remove(userObj.Email);
                   }
               }  
               System.debug('userObjList*****'+userObjList.size());
               //if(userObjList.size()>0)
                   //update userObjList;        
               System.debug('litmosIntegtaionConsoleObjList*****'+litmosIntegtaionConsoleObjList.size());
               if(litmosIntegtaionConsoleObjList.size()>0)
                   insert litmosIntegtaionConsoleObjList;
           }
        }
        catch (Exception e)
        {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importing data Please make sure input csv file is correct');
            ApexPages.addMessage(errorMessage);
        }  
  }
}