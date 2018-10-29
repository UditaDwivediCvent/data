/*Author: Sandeep Kumar
* Date: 20 Mar 2017
* Description: EB Project Auto Assignemnt Workflow. 
* Class is reponsible for sending an email containing Survey link to Contact asscoiated with EB Project. 
* Test Class : EBSurveyNotificationEmail_Test
*/
global without sharing class EBSurveyNotificationEmail {
    public static Messaging.SingleEmailMessage mail;        
    public static List<Messaging.SingleEmailMessage> mailList;
    public final String emailTemplateForNewOwnersId = Label.EB_Project_Auto_Assignment_Notification_Template_ID;
    public static final String emailTemplateForCaseLevelEscalationId = Label.EB_Project_Case_Level_Escalation_Email_Template_ID;
    public final String emailTemplateForDuplicateSurveyId = Label.EB_Project_Duplicate_Link_Usage_Notification_Id;
    public static final String emailTemplateExpressId = Label.EB_Project_Express_Request_Template_ID;
    public static final String emailTemplateScopeId = Label.EB_Project_Scope_Request_Template_ID;
    public static final String emailTemplateFlexConversionID = Label.EB_Project_Flex_Conversion_Template_ID;
    public static final String emailTemplateForScopeRequestSurveySubmission = Label.EB_Project_Scope_Request_Created_ID;
    public static final String emailTemplateForRushRequestSurveySubmission = Label.EB_Project_Rush_Request_Created_Id;    
    public static final String emailTemplateForEBSBProjectOwnerChangeEmail = Label.EB_SB_Project_Owner_Change_Email_Notification;
    public static final String oweaId = Label.EB_Project_Org_Wide_Address_Id;
    
    webservice static void sendCustomEmail(Id ebId){
        // Get an EmailTemplate that would be used for sending emails.
        Id emailTemplateIdExpress = Id.valueOf(emailTemplateExpressId);
        Id emailTemplateIdScope = Id.valueOf(emailTemplateScopeId);
        Id emailTemplateIdFlexConversion = Id.valueOf(emailTemplateFlexConversionID);
        
        // New instance of a single email message List
        mailList = new List<Messaging.SingleEmailMessage>(); 
        mail = new Messaging.SingleEmailMessage();
        
        // Get the EB Project for preparing email.
        EB_SB_Builder__c ebProject = [Select Id,Opportunity__c,Opportunity__r.Event_Planner_Email__c,Opportunity__r.Event_Planner_Name__c,Survey_Sent__c,Project_Type_del__c,Contact__c From EB_SB_Builder__c Where Id =:ebId];        
        // Do not send form to customer for Enterprise and Event QuaterBack Project
        // Last Modified By : Sandeep Kumar
        if(ebproject.Project_Type_del__c != 'Enterprise Project' && ebproject.Project_Type_del__c != 'Event Quarterback Project'){
            if(ebproject.Project_Type_del__c == 'Event Builder - Express'){
                // The email template ID used for the email Express event requests.
                mail.setTemplateId(emailTemplateIdExpress);
            }else if(ebproject.Project_Type_del__c == 'Flex Conversion'){
                // The email template ID used for the email Express event requests.
                mail.setTemplateId(emailTemplateIdFlexConversion);
            }else{
                // The email template ID used for the email scope event requests.
                mail.setTemplateId(emailTemplateIdScope);
            }
            
            List<String> sendTo = new List<String>();
            // Who you are sending the email to
            if(ebProject.Opportunity__c != null && ebProject.Opportunity__r.Event_Planner_Email__c != null && ebProject.Opportunity__r.Event_Planner_Name__c != null){
                sendTo.add(ebProject.Opportunity__r.Event_Planner_Email__c);        
                mail.setToAddresses(sendTo); 
                mail.setTargetObjectId(ebProject.Contact__c);
                mail.setTreatTargetObjectAsRecipient(false);
            }else{
                mail.setTargetObjectId(ebProject.Contact__c);
            }                
            mail.setReplyTo('EventBuilder@cvent.com');
            mail.setWhatId(ebProject.Id);
            // Set the Org Wide Email Addresses
            mail.setOrgWideEmailAddressId(Id.valueOf(oweaId));
            mail.setSaveAsActivity(false); 
            mailList.add(mail);        
            if(!mailList.isEmpty()){
                Messaging.sendEmail(mailList);
                if(!ebProject.Survey_Sent__c)
                    ebProject.Survey_Sent__c = true;
                ebProject.Survey_Sent_By__c = 'Email has been already sent by '+userInfo.getName()+' on '+System.Today().Format()+'.';
                update ebProject;
            }   
        }
    } 
    
    // Sends an email to new Case Owner.
    public void sendEmailToNewCaseOwner(Id newInternalSurveyId) {
        system.debug('Inside sendEmailToNewCaseOwner'+newInternalSurveyId);
        // Fetch the EB survey records.
        List<Internal_Survey_for_EB__c> InternalSurveyForEBObj = [Select Id,Case__r.OwnerId,Name,Account__r.AM_Event__c,Survey_Type__c from Internal_Survey_for_EB__c where Id=:newInternalSurveyId  LIMIT 1];
        // Get an EmailTemplate that would be used for sending emails to newly assigned owners for Scope Request.
        Id emailTemplateIdScopeCaseNotification = Id.valueOf(emailTemplateForScopeRequestSurveySubmission);
        // Get an EmailTemplate that would be used for sending emails to newly assigned owners for Rush Request.
        Id emailTemplateIdRushCaseNotification = Id.valueOf(emailTemplateForRushRequestSurveySubmission);
        
        // New instance of a single email message List
        mailList = new List<Messaging.SingleEmailMessage>(); 
        // (Optional) Set list of people who should be CC'ed
        List<String> ccTo = new List<String>();
        // Set this address to EB Automation email service.
        ccTo.add('CSEBmgrs@cvent.com');    
        // Set this address to EB Automation email service to attach the email information with case..
        ccTo.add('EBSurveyAutomation@cvent.com'); 
        // Who you are sending the email to     
        List<String> sendTo = new List<String>();        
        // New instance of a single email message Object       
        mail = new Messaging.SingleEmailMessage();        
        if(InternalSurveyForEBObj[0].Survey_Type__c == 'Scope Request'){
            // Who you are sending the email to
            mail.setTargetObjectId(InternalSurveyForEBObj[0].Case__r.OwnerId);
            // Add AM-Event in cc, so that he is aware about the request.
            ccTo.add(UserInfo.getUserEmail());
            // Scope Request template ID used for the email
            mail.setTemplateId(emailTemplateIdScopeCaseNotification);
        }else{
            // Who you are sending the email to
            mail.setTargetObjectId(Userinfo.getUserId());
            // Rush Request template ID used for the email
            mail.setTemplateId(emailTemplateIdRushCaseNotification);
        }        
        // Set what Id to populate merge fields in email template.         
        mail.setWhatId(InternalSurveyForEBObj[0].Id);        
        // Set CCAddresses
        mail.setCcAddresses(ccTo);
        // Set the Org Wide Email Addresses
        mail.setOrgWideEmailAddressId(Id.valueOf(oweaId));
        mail.setSaveAsActivity(false); 
        mailList.add(mail);
        if(!mailList.isEmpty()){
            Messaging.sendEmail(mailList);
        }
    }   
    
    // Sends an email to new EB Project Owner.
    public void sendEbProjectAssignmentEmail(List<EB_SB_Builder__c> EBProjectList){
        // Get an EmailTemplate that would be used for sending emails to newly assigned owners.
        Id emailTemplateIdNewOwner = Id.valueOf(emailTemplateForNewOwnersId);
        // New instance of a single email message List
        mailList = new List<Messaging.SingleEmailMessage>(); 
        // (Optional) Set list of people who should be CC'ed
        List<String> ccTo = new List<String>();
        ccTo.add('CSEBmgrs@cvent.com');
        
        for(EB_SB_Builder__c eBProjObj : EBProjectList){
            // New instance of a single email message Object       
            mail = new Messaging.SingleEmailMessage();
            // Who you are sending the email to
            mail.setTargetObjectId(eBProjObj.OwnerId);
            // The email template ID used for the email
            mail.setTemplateId(emailTemplateIdNewOwner);
            // Set what Id to populate merge fields in email template.         
            mail.setWhatId(eBProjObj.Id);
            // Set CCAddresses
            mail.setCcAddresses(ccTo);
            mail.setReplyTo('EventBuilder@cvent.com');
            // Set the Org Wide Email Addresses
            mail.setOrgWideEmailAddressId(Id.valueOf(oweaId));
            mail.setSaveAsActivity(false); 
            mailList.add(mail);
        }        
        if(!mailList.isEmpty()){
            Messaging.sendEmail(mailList);
        }
    }
    
    // Sends an email to Event Builder Management.
    public static void sendCaseLevelEscalationEmail(List<Case> caseList){
        // Get an EmailTemplate that would be used for sending emails to newly assigned owners.
        Id caseLevelEscalationEmailTemplateId = Id.valueOf(emailTemplateForCaseLevelEscalationId);
        // New instance of a single email message List
        mailList = new List<Messaging.SingleEmailMessage>(); 
        // Set list of people who should be CC'ed
        List<String> ccTo = new List<String>();
        ccTo.add('CSEBmgrs@cvent.com'); 
        
        for(Case caseObj : caseList){
            system.debug('------caseObj------'+caseObj);
            // New instance of a single email message Object       
            mail = new Messaging.SingleEmailMessage();
            // Who you are sending the email to
            mail.setTargetObjectId(caseObj.OwnerId);
            // The email template ID used for the email
            mail.setTemplateId(caseLevelEscalationEmailTemplateId);
            // Set what Id to populate merge fields in email template.         
            mail.setWhatId(caseObj.Id);
            mail.setReplyTo('EventBuilder@cvent.com');
            // Set the Org Wide Email Addresses
            mail.setOrgWideEmailAddressId(Id.valueOf(oweaId));
            // Set CCAddresses
            mail.setCcAddresses(ccTo);
            mail.setSaveAsActivity(false); 
            // Add email to Case List.
            mailList.add(mail);
        }        
        if(!mailList.isEmpty()){
            Messaging.sendEmail(mailList);
        }
    }
    
    // Sends an email to Event Builder Management.
    public static void sendEBSBProjectOwnerChangeEmail(Map<Id,Id> accIdToOwnerIdMap,Map<Id,List<String>> accIdToUserEmailMap,Map<Id,EB_SB_Builder__c> accIdToEBSBProjMap){
        // Get an EmailTemplate that would be used for sending emails to newly assigned owners.
        Id ownerChangeEmailTemplateId = Id.valueOf(emailTemplateForEBSBProjectOwnerChangeEmail);
        // New instance of a single email message List
        mailList = new List<Messaging.SingleEmailMessage>(); 
        // Set list of people who should be CC'ed
        List<String> ccTo = new List<String>();        
        system.debug('------accId------'+accIdToOwnerIdMap);
        for(Id accId : accIdToUserEmailMap.keySet()){
            system.debug('------accId------'+accIdToUserEmailMap.get(accId));
            // New instance of a single email message Object       
            mail = new Messaging.SingleEmailMessage();
            // Who you are sending the email to
            mail.setTargetObjectId(accIdToOwnerIdMap.get(accId));
            // The email template ID used for the email
            mail.setTemplateId(ownerChangeEmailTemplateId);
            // Set what Id to populate merge fields in email template. 
            if(accIdToEBSBProjMap.containsKey(accId))        
                mail.setWhatId(accIdToEBSBProjMap.get(accId).Id);
            mail.setReplyTo('EventBuilder@cvent.com');
            // Set the Org Wide Email Addresses
            mail.setOrgWideEmailAddressId(Id.valueOf(oweaId));
            // Set CCAddresses
            ccTo.clear();
            //ccTo.add('CSEBmgrs@cvent.com'); 
            if(accIdToUserEmailMap.containsKey(accId))
                ccTo.addAll(accIdToUserEmailMap.get(accId));
            mail.setCcAddresses(ccTo);
            mail.setSaveAsActivity(false); 
            // Add email to Case List.
            mailList.add(mail);
        }       
        system.debug('mailList===>>>>>'+mailList.size());
        
        if(!mailList.isEmpty()){
            system.debug('mailList===>>>>>'+mailList);
            Messaging.sendEmail(mailList);
        }
    }
    
    // Sends an email to EB Leadership for informing them about the same link usage for filling survey.
    public void sendEbProjectDuplicateLinkUsageInfo(EB_SB_Builder__c EBProject){
        // Get an EmailTemplate that would be used for sending emails to newly assigned owners.
        Id emailTemplateIdForDuplicateSurvey = Id.valueOf(emailTemplateForDuplicateSurveyId);
        // New instance of a single email message List
        mailList = new List<Messaging.SingleEmailMessage>(); 
        // Set list of people who should be CC'ed
        List<String> ccTo = new List<String>();
        ccTo.add('CSEBmgrs@cvent.com');        
        // New instance of a single email message Object       
        mail = new Messaging.SingleEmailMessage();
        // Who you are sending the email to
        mail.setTargetObjectId(UserInfo.getUserId());
        // Do to send email to current project owner.
        mail.setTreatTargetObjectAsRecipient(false);
        // The email template ID used for the email
        mail.setTemplateId(emailTemplateIdForDuplicateSurvey);
        // Set what Id to populate merge fields in email template.         
        mail.setWhatId(EBProject.Id);
        // Set CCAddresses
        mail.setCcAddresses(ccTo);
        mail.setReplyTo('EventBuilder@cvent.com');
        // Set the Org Wide Email Addresses
        mail.setOrgWideEmailAddressId(Id.valueOf(oweaId));
        mail.setSaveAsActivity(false); 
        mailList.add(mail);
        if(!mailList.isEmpty()){
            Messaging.sendEmail(mailList);
        }
    }    
}