trigger updateSurveyDateOnEBSB on EB_SB_Builder__c (after update) {
    Map<Id,EB_SB_Builder__c> ebsbMap = new Map<Id,EB_SB_Builder__c>();
    List<Contact> contactList = new List<Contact>();
    List<Contact> updateContacts = new List<Contact>();
    
    /*Map<Id,Mobile_Card__c> testCase = new Map<Id,Mobile_Card__c>();
    Map<Id,User> emailCase = new Map<Id,User>();
    Id profileId=userinfo.getProfileId();
    String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
    Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosById();*/
    
    
    for(EB_SB_Builder__c cs : Trigger.new){
        if(cs.Contact__c!=null && cs.Survey_Invitation_Sent__c!=null && (cs.Survey_Invitation_Sent__c!=System.Trigger.oldMap.get(cs.id).Survey_Invitation_Sent__c)){
            ebsbMap.put(cs.Contact__c,cs);
        }
    }
    if(ebsbMap.size()>0){
        contactList = [Select Profile_Name__c,Last_Experiential_Survey_Invitation__c from Contact where id in : ebsbMap.keySet()];
    }     
    for(Contact c : contactList){
        c.Last_Experiential_Survey_Invitation__c = ebsbMap.get(c.id).Survey_Invitation_Sent__c;
        updateContacts.add(c);
    }
    
    if(updateContacts.size()>0)
        update updateContacts;
}