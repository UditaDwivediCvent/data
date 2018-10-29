@isTest
public class testUpdateCSATrigger{
    private static testMethod void testUpdateCsat(){
    
    
        PSA_Custom_Trigger_Settings__c cts = new PSA_Custom_Trigger_Settings__c(Name = 'Default');
        insert cts;
        
        PSA_Chatter_Settings__c cs = new PSA_Chatter_Settings__c(Name = 'Default', Pending_Completion_Message__c = 'Test Message');
        insert cs;      
    
        Case c = new Case(Status='Open',subject='Test');
        insert c;
        
        
        Survey_Q__c s = new Survey_Q__c(Name = 'test',Case__c = c.id);
        insert s;
    }
    
    private static testMethod void testUpdateMobileAppSurvey(){
    
    
        PSA_Custom_Trigger_Settings__c cts = new PSA_Custom_Trigger_Settings__c(Name = 'Default');
        insert cts;
        
        PSA_Chatter_Settings__c cs = new PSA_Chatter_Settings__c(Name = 'Default', Pending_Completion_Message__c = 'Test Message');
        insert cs;      
    
        Mobile_Card__c mc = new Mobile_Card__c();
        mc.Name = 'Test 1';
        mc.App_Name__c = 'Test App'; 
        insert mc;
        
        
        Survey_Q__c s = new Survey_Q__c(Name = 'test 2',MobileApp__c = mc.id);
        insert s;
    }
    
    
        
}