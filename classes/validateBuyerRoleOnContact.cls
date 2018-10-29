//Written by udita to validate the contact role if not validated for the contact... This is a vf page on contact layout named "validateBuyerRole"
public class validateBuyerRoleOnContact{
  public id accountId; 
  public list<Contact_Role__c >currentRecordConRole{get; set;}  
    public validateBuyerRoleOnContact(ApexPages.StandardController controller) {
        contact con =[select AccountId from contact where id = :ApexPages.currentPage().getParameters().get('id')];
        accountId = con.AccountId;
        currentRecordConRole = [select id,Contact_Validated__c,Account_Buyer_Role__c from Contact_Role__c where Contact__c = :ApexPages.currentPage().getParameters().get('id') and Contact_Validated__c =false and Account_Buyer_Role__c = :accountId ];
    }
  public PageReference validateContact() {
    /*if(currentRecordConRole.size() > 0){
        for(Contact_Role__c cr : currentRecordConRole){
           cr.Contact_Validated_Date__c = system.now();
        }
        update currentRecordConRole;
      }*/
   // PageReference contactPage =  new Pagereference ('/'+currentRecordConRole[0].id+'?'+'/e');           
  //  contactPage.setRedirect(true);
    return null;
   }
}