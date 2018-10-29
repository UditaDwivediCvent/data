public class ControllerBuyerRoleCreation{
  public id AccId{get;set;}
  public id contactId{get;set;}
  public string name{get;set;}
  public list<contact> conList{get;set;}
  public list<Contact_Role__c> conRoleList{get;set;}
  
  public ControllerBuyerRoleCreation(ApexPages.StandardController stdController){
    this.contactId = ApexPages.currentPage().getParameters().get('ID');
    conList = new list<contact>();
    conList = [select id,name,DateTime_TeamMember__c, AccountId,Account.name from contact where id =:this.contactId];  
    AccId = conList[0].AccountId;
    conRoleList = new list<Contact_Role__c>();
    conRoleList =[select id,name from Contact_Role__c where Account_Buyer_Role__c =: AccId  and Contact__c =: this.contactId and RecordType.Name='Buyer Role'];
 }   
 public PageReference callNo() {
  conList[0].DateTime_TeamMember__c = system.today();
  update conList;
  PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
    pageRef.setRedirect(true);
  return pageRef;
 }
}