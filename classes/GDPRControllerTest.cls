@istest
public class GDPRControllerTest{

    static testmethod void runtest(){
        
        GDPRProductSetting__c setting = new GDPRProductSetting__c();
        setting.Name = 'Abstract Management';
        setting.Product__c = 'Abstract Management';
        setting.GDPR_Form_Field_Label__c  = 'Account Number';
        insert setting;
        
        GDPRController controller = new GDPRController();

        //get initialized case from controller
        Case cs = controller.c;
        
        cs.Submitter_Name__c = 'Test User';
        cs.Submitter_Email__c = 'user@user.com';
        controller.fName = 'Test2';
        controller.lName = 'User';
        cs.Requester_s_Email__c = 'user@user.com';
        cs.GDPR_Type__c = 'Right of Access (Data Retrieval)';
        cs.GDPR_Submitted_Date__c = system.today();
        cs.Products_Affected_Dev__c = 'Abstract Management';
        controller.showDescription = 'Yes';
        cs.Description = 'Yes';
        controller.agree = true;
        
        
        
        
        //put case information back to the c instance of controller
        controller.c = cs;
        controller.GetProducts();
        
        //put account number
        controller.selectedProdMap.put('Abstract Management',new GDPRController.ProductBoxWrapper('Abstract Management Account Number','464465464',true));
        controller.submitRequest();
        
        //throw exception 1 (agree checkbox false)
        controller.agree = false;
        controller.submitRequest();
        
        //throw exception 2 ( account number missing)
        controller.selectedProdMap.put('Abstract Management',new GDPRController.ProductBoxWrapper('Abstract Management Account Number',null,true));
        controller.fName = null;
        cs.Submitter_Email__c = 'xyz';
        controller.submitRequest();
     
        
        
    
    }

}