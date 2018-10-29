@isTest(seeAllData=true)
private class TestEBSBTrigger
{
    static testMethod void testpreventEBProjdelete(){
           
           Profile p = [select id from profile where name='Standard User'];
           User u = new User(alias = 'standt', email='standarduser@testorg.com',
                             emailencodingkey='UTF-8', lastname='Testing', 
                             languagelocalekey='en_US',localesidkey='en_US',
                             profileid = p.Id,timezonesidkey='America/Los_Angeles',
                             username='teststandarduser66464@testorg.com');
   
   
           System.runAs(u){
                EB_SB_Builder__c eb = new EB_SB_Builder__c();
              
                eb.Project__c='Event Builder';
                eb.Project_Status__c='Completed';
                eb.Project_Type_del__c='Demo Event';
                eb.Project_Complexity__c = '1-Simple';
                eb.Event_Code__c = '1111';
               insert eb;
                 try{
                      {
                      delete eb;
                       }
                 }catch(Exception ex){
                        Boolean Message = false;          
                        if(ex.getMessage().contains('You are not authorised to delete this Project ID')){
                             Message = true;      
                        }else{
                             Message = false;      
                        }
                        system.debug('########Message : '+ Message);
                        
                        System.AssertEquals(Message, false);
                 }
        }
  }


}