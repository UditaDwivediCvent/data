trigger updateSurveyDate on Case (after update) {
    
    /* Skip execution if this user is setup to exempt triggers. This helps in one time data load as well */
    if(!BypassTriggerUtility.isTriggerEnabledForThisUserOrProfileId(UserInfo.getUserId())){
            return;
    } 


    Map<Id,Case> caseMap = new Map<Id,Case>();
    List<Contact> contactList = new List<Contact>();
    List<Contact> updateContacts = new List<Contact>();
    Map<Id,Case> testCase = new Map<Id,Case>();
    Map<Id,User> emailCase = new Map<Id,User>();
    //Id profileId=userinfo.getProfileId();
    //String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
    Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosById();
    for(Case cs : Trigger.new){
        if(cs.ContactID!=null && cs.Survey_Invitation_Sent__c!=null && (cs.Survey_Invitation_Sent__c!=System.Trigger.oldMap.get(cs.id).Survey_Invitation_Sent__c) && cs.Status=='Closed'){
            caseMap.put(cs.ContactId,cs);
        }
         if(cs.ContactID!=null && cs.RM_Experiential_Survey_Invitation_Sent__c!=null && (cs.RM_Experiential_Survey_Invitation_Sent__c!=System.Trigger.oldMap.get(cs.id).RM_Experiential_Survey_Invitation_Sent__c) && cs.Status=='Closed'){
            caseMap.put(cs.ContactId,cs);
        }
    }
    if(caseMap.size()>0){
        contactList = [Select Last_Transactional_Survey_Invitation__c,Profile_Name__c,Last_Experiential_Survey_Invitation__c,Last_RM_Experiential_Survey_Invitation__c from Contact where id in : caseMap.keySet()];
    }    
    for(Contact c : contactList){
        if(rtMap.get(caseMap.get(c.id).RecordTypeId).getName()=='Client Management (Global)'){
            c.Last_Experiential_Survey_Invitation__c = caseMap.get(c.id).Survey_Invitation_Sent__c;
            c.Last_RM_Experiential_Survey_Invitation__c = caseMap.get(c.id).RM_Experiential_Survey_Invitation_Sent__c;}
        else
            c.Last_Transactional_Survey_Invitation__c = caseMap.get(c.id).Survey_Invitation_Sent__c;
        updateContacts.add(c);
    }
    
    if(updateContacts.size()>0)
        update updateContacts;
}