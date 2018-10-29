trigger updateSurveyDateOnMobileApp on Mobile_Card__c (after update) {
    Map<Id,Mobile_Card__c> mobMap = new Map<Id,Mobile_Card__c>();
    List<Contact> contactList = new List<Contact>();
    List<Contact> updateContacts = new List<Contact>();
    
    /*Map<Id,Mobile_Card__c> testCase = new Map<Id,Mobile_Card__c>();
    Map<Id,User> emailCase = new Map<Id,User>();
    Id profileId=userinfo.getProfileId();
    String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
    Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosById();*/
    
    for(Mobile_Card__c cs : Trigger.new){
        if(cs.Primary_Contact__c!=null && cs.Survey_Invitation_Sent__c!=null && (cs.Survey_Invitation_Sent__c!=System.Trigger.oldMap.get(cs.id).Survey_Invitation_Sent__c)){
            mobMap.put(cs.Primary_Contact__c,cs);
        }
    }
    if(mobMap.size()>0){
        contactList = [Select Profile_Name__c,Last_Experiential_Survey_Invitation__c from Contact where id in : mobMap.keySet()];
    }    
    for(Contact c : contactList){
        c.Last_Experiential_Survey_Invitation__c = mobMap.get(c.id).Survey_Invitation_Sent__c;
        updateContacts.add(c);
    }
    
    if(updateContacts.size()>0)
        update updateContacts;
}