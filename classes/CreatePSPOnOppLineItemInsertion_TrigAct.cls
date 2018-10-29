/***
* Author : Sandeep Kumar
* Date : 18 May, 2017
* Description : CreatePSPOnOppLineItemInsertion_TrigAct class fullfills below functionalities,
* 1) Creates EB SB Project whenever Event Build Opportunity is implemented in Salesforce. 
* 2) Check for PSP ID for current year and if this doesn't exist, creates new add all the projects to it.
* 3) Sents EB Form to Opportunity Contact or Event Planner.
* Test Class - CreatePSPOnOppLineItem_TrigAct_Test 
*****************************************************************************************
* Last Modified By : Sandeep Kumar (Dated: 22 August, 2017)
* Previously this piece of code was called whenever opportunityLineItem were inserted in Salesforce. 
* As per new CPQ process in place this code is called from OpportunityAfter trigger. It will still full fill the previous process by creating opportunities.
*****************************************************************************************
* Last Modified By : Sandeep Kumar (Dated: 02 November, 2017)
* Added addition check to fire automation trigger only one time per opportunity.
* This enhancement was done to avoid duplicate EB SB Project creation as the finance team was toggliing Contract Implemented checkbox several times.
****/
public without sharing class CreatePSPOnOppLineItemInsertion_TrigAct extends TriggerAction{    
    public Integer currentYear;
    public String baseUrl;
    public Set<Id> oppIdsToProcess;            
    public Set<Id> accIdSet;
    public Set<Id> newPSPAccountSet;
    public Set<Id> newEBAccountSet;
    public Map<Id,Integer> accIdToEBCountMap;
    public Map<Id,Opportunity> oppIdToOppMap;
    public Messaging.SingleEmailMessage mail; 
    public List<Messaging.SingleEmailMessage> mailList;
    public Map<String,EBProjectStageToPendingHrsSetting__c> NameToHrsPendingMap; 
    public Map<String,EB_Project_Products_Mapping__c> prodNameToProdMappingMap;
    public List<Professional_Services_Project__c> PSPToBeInsertedList;
    public List<Professional_Services_Project__c> PSPToBeUpdatedList;
    public List<EB_SB_Builder__c> EBSBToBeInsertedList;
    public List<EB_SB_Builder__c> EBToUpdateList;
    public Map<Id,List<OpportunityLineItem>> oppIdToOppLineItemsMap;
    public Map<Id,List<Opportunity>> accIdToOpptsMap;
    public Map<Id,Boolean> accIdToARAFlagMap;
    public Map<Id,Map<Integer,Professional_Services_Project__c>> accIdToPSPsMap;
    public Map<String,Integer> productNameToEBCountMap;
    public Map<String,Id> productNameToOppLineItemId;
    public final String oweaId = Label.EB_Project_Org_Wide_Address_Id;
    public final static Id eventBuilderLeadersQueueId = Label.Event_Builder_Leaders_Queue_Id;
    
    public CreatePSPOnOppLineItemInsertion_TrigAct(){
        // Call super to set batch variables & context
        super();
        currentYear = System.today().year();
        accIdSet = new Set<Id>();
        oppIdsToProcess = new Set<Id>(); 
        accIdToEBCountMap = new Map<Id,Integer>();
        newEBAccountSet = new Set<Id>();
        newPSPAccountSet = new Set<Id>();
        productNameToOppLineItemId = new Map<String,Id>();
        oppIdToOppMap = new Map<Id,Opportunity>();
        EBSBToBeInsertedList = new List<EB_SB_Builder__c>();
        EBToUpdateList = new List<EB_SB_Builder__c>();
        accIdToARAFlagMap = new Map<Id,Boolean>();
        accIdToOpptsMap = new Map<Id,List<Opportunity>>();    
        oppIdToOppLineItemsMap = new Map<Id,List<OpportunityLineItem>>();
        prodNameToProdMappingMap = new Map<String,EB_Project_Products_Mapping__c>();
        accIdToPSPsMap = new Map<Id,Map<Integer,Professional_Services_Project__c>>(); 
        productNameToEBCountMap = new Map<String,Integer>();
    }
    
    public override Boolean shouldRun(){ 
        // Turn on the EBSB Automation Triggered Flag so that it should run only once.
        if(this.isUpdate() && this.isBefore()){
            for (Opportunity newOpp: (List<Opportunity>)this.triggerMap.values()){ 
                Opportunity oldOpp = (Opportunity)this.triggerOldMap.get(newOpp.Id);
                if(!newOpp.EBSB_Automation_Triggered_Dev__c && oldOpp.Contract_Implemented__c != newOpp.Contract_Implemented__c && oldOpp.Contract_Implemented__c == true)
                    newOpp.EBSB_Automation_Triggered_Dev__c = true;
            }               
        } 
        
        if(this.isUpdate() && this.isAfter() && !this.hasRun()){ 
            // Check Opportunities and execute the EBSB Automation process if below critrias are met.
            for (Opportunity newOpp: (List<Opportunity>)this.triggerMap.values()){ 
                Opportunity oldOpp = (Opportunity)this.triggerOldMap.get(newOpp.Id);
                if(!newOpp.EBSB_Automation_Triggered_Dev__c && newOpp.StageName == 'Closed Won' && oldOpp.Contract_Implemented__c != newOpp.Contract_Implemented__c && newOpp.Contract_Implemented__c != null && newOpp.Contract_Implemented__c){
                    oppIdsToProcess.add(newOpp.Id);
                }               
            } 
            
            List<OpportunityLineItem> oppLineItemList;
            for(OpportunityLineItem newItem : [Select Id, Product2.Name,Quantity,OpportunityId from OpportunityLineItem where OpportunityId IN :oppIdsToProcess]){
                if(newItem.Product2.Name.contains('Event Builder') && newItem.Product2.Name != 'Event Builder Package' && newItem.Quantity != null){
                    // Stores the Product Name to OpportunityLineItem Id.
                    productNameToOppLineItemId.put(newItem.Product2.Name, newItem.Id);
                    // Stores the prod name and project count.
                    productNameToEBCountMap.put(newItem.Product2.Name,Integer.ValueOf(newItem.Quantity));                        
                    //Instantiate List
                    oppLineItemList = new List<OpportunityLineItem>();                    
                    // Prepare Opportunity Id to List of Opp Line Items.
                    if(oppIdToOppLineItemsMap.containsKey(newItem.OpportunityId)){
                        oppLineItemList = oppIdToOppLineItemsMap.get(newItem.OpportunityId);
                        oppLineItemList.add(newItem);
                        oppIdToOppLineItemsMap.put(newItem.OpportunityId,oppLineItemList);
                    }else{
                        oppLineItemList.add(newItem);
                        oppIdToOppLineItemsMap.put(newItem.OpportunityId,oppLineItemList);
                    }
                }
            }
        }
        return !productNameToEBCountMap.isEmpty();       
    }
    
    public override void doAction(){
        Professional_Services_Project__c PSPRec;
        PSPToBeInsertedList = new List<Professional_Services_Project__c>();
        PSPToBeUpdatedList = new List<Professional_Services_Project__c>(); 
        NameToHrsPendingMap = new Map<String,EBProjectStageToPendingHrsSetting__c>();    
        
        List<Opportunity> oppList;     
        for(Opportunity opp : (List<Opportunity>)this.triggerMap.values()){
            if(opp.CloseDate.year() == currentYear){
                accIdSet.add(opp.AccountId);
                oppIdToOppMap.put(opp.Id, opp);                    
                //Instantiate List
                oppList = new List<Opportunity>();            
                // Prepare Opportunity Id to List of Opp Line Items.
                if(accIdToOpptsMap.containsKey(opp.AccountId)){
                    oppList = accIdToOpptsMap.get(opp.AccountId);
                    oppList.add(opp);
                    accIdToOpptsMap.put(opp.AccountId, oppList);
                }else{
                    oppList.add(opp);
                    accIdToOpptsMap.put(opp.AccountId, oppList);
                }
            }
        }
        // Check if the associated account is ARA account.
        for(Account acc : [Select Id,Active_ARA__c,(Select Id,Status__c from ARAs__r) from Account where Id IN :accIdSet]){
            if(acc.ARAs__r != null && acc.ARAs__r.Size() > 0 ){                    
                // Prepare Opportunity Id to List of Opp Line Items.
                if(acc.Active_ARA__c){
                    accIdToARAFlagMap.put(acc.Id,true);    
                }else{
                    accIdToARAFlagMap.put(acc.Id,false);  
                }
            }
        }
        
        // Collection Declaration
        Map<Integer,Professional_Services_Project__c> currentYearToPSPMap;        
        for(Professional_Services_Project__c PSP : [Select Id,Account__c,PSP_Year__c,of_EB__c,Contact__c,Event_Builder__c,Survey_Builder__c from Professional_Services_Project__c where Account__c IN :accIdSet]){
            // Instantiate Map
            currentYearToPSPMap = new Map<Integer,Professional_Services_Project__c>();
            if(accIdToPSPsMap.containsKey(PSP.Account__c)){
                currentYearToPSPMap = accIdToPSPsMap.get(PSP.Account__c);
                currentYearToPSPMap.put(Integer.valueOf(PSP.PSP_Year__c), PSP);
                accIdToPSPsMap.put(PSP.Account__c, currentYearToPSPMap); 
            }else{
                // Prepare a Map with Year as a Key.
                currentYearToPSPMap.put(Integer.valueOf(PSP.PSP_Year__c), PSP);
                accIdToPSPsMap.put(PSP.Account__c, currentYearToPSPMap);
            }
        }
        
        for(Id accId : accIdSet){
            //Create new PSP record check.
            if(accIdToPSPsMap.isEmpty() || (accIdToPSPsMap != null && accIdToPSPsMap.get(accId) != null && !accIdToPSPsMap.get(accId).containsKey(currentYear))){
                newPSPAccountSet.add(accId);
            }else{
                //Create new EBSB record and increment the count. 
                newEBAccountSet.add(accId);
            }                
        } 
        
        // Get the product mapping to populate the project type and Complexity. 
        for(EB_Project_Products_Mapping__c prodMapping : [Select Id,Name,EB_Project_Type__c,EB_Project_Complexity__c from EB_Project_Products_Mapping__c]){
            prodNameToProdMappingMap.put(prodMapping.Name, prodMapping);
        }
        // Get the Default pending Hours from the custom setting.
        for(EBProjectStageToPendingHrsSetting__c rec :EBProjectStageToPendingHrsSetting__c.getAll().Values()){
            NameToHrsPendingMap.put(rec.Name, rec);
        }      
        // Calculate EB Count for PSP Records.
        for(Id accId : accIdSet){
            Integer ofEB = 0;       
            for(Opportunity opp: accIdToOpptsMap.get(accId)){
                for(OpportunityLineItem oppLineItem : oppIdToOppLineItemsMap.get(opp.Id)){
                    if(oppLineItem.Quantity != null){
                        ofEB += Integer.valueOf(oppLineItem.Quantity);
                    }                    
                }
            }
            accIdToEBCountMap.put(accId, ofEB);
        } 
        
        // Create a list for inserting new PSP Records with EB Count & Account name.
        for(Id accId : newPSPAccountSet){
            PSPRec = new Professional_Services_Project__c();
            PSPRec.Account__c = accId;
            PSPRec.of_EB__c = accIdToEBCountMap.get(accId);
            PSPToBeInsertedList.add(PSPRec);
        }
        
        if(!PSPToBeInsertedList.isEmpty()){
            insert PSPToBeInsertedList;
            // Call method to create new EB Project Records.
            CreateNewEBProject(PSPToBeInsertedList);
        }
        
        // Updates existing PSP record with new EB count
        for(Id accId : newEBAccountSet){
            if(accIdToPSPsMap != null && accIdToPSPsMap.get(accId) != null && accIdToPSPsMap.get(accId).containsKey(currentYear)){
                if(accIdToPSPsMap.get(accId).get(currentYear).of_EB__c != null){
                    accIdToPSPsMap.get(accId).get(currentYear).of_EB__c += accIdToEBCountMap.get(accId);
                    PSPToBeUpdatedList.add(accIdToPSPsMap.get(accId).get(currentYear));
                }else{
                    accIdToPSPsMap.get(accId).get(currentYear).of_EB__c = accIdToEBCountMap.get(accId);
                    PSPToBeUpdatedList.add(accIdToPSPsMap.get(accId).get(currentYear));
                }                
            }            
        }     
        if(!PSPToBeUpdatedList.isEmpty()){
            update PSPToBeUpdatedList;
            // Call method to create new EB Project Records.
            CreateNewEBProject(PSPToBeUpdatedList);
        }
    }
    
    EB_SB_Builder__c EBSBRec;
    public void CreateNewEBProject(List<Professional_Services_Project__c> newEBProjects){        
        for(Professional_Services_Project__c PSP :newEBProjects){
            for(String prodName :productNameToEBCountMap.keySet()){
                for(Integer i=0; i<Integer.valueOf(productNameToEBCountMap.get(prodName)); i++){
                    EBSBRec = new EB_SB_Builder__c();
                    EBSBRec.PSP_ID__c = PSP.Id;
                    EBSBRec.Contact__c = accIdToOpptsMap.get(PSP.Account__c)[0].Contact_Associated__c;
                    EBSBRec.Opportunity__c = accIdToOpptsMap.get(PSP.Account__c)[0].Id;
                    EBSBRec.AccountCustom__c = PSP.Account__c;                 
                    EBSBRec.Project__c = 'Event Builder';
                    EBSBRec.OpportunityLineItemID__c = productNameToOppLineItemId.get(prodName);
                    EBSBRec.Project_Status_del__c = 'Yet To Start';
                    if(accIdToARAFlagMap.containsKey(PSP.Account__c)){
                        if(accIdToARAFlagMap.get(PSP.Account__c)){
                            EBSBRec.Project_Type_del__c = 'ARA - Active';
                        }else{
                            EBSBRec.Project_Type_del__c = 'ARA - Inactive';   
                        }
                    }else{
                        EBSBRec.Project_Type_del__c = prodNameToProdMappingMap.get(prodName).EB_Project_Type__c;                        
                    }
                    EBSBRec.Project_Stage__c = 'Information Received';
                    EBSBRec.Event_Title__c = '';
                    EBSBRec.Project_Complexity__c = prodNameToProdMappingMap.get(prodName).EB_Project_Complexity__c;                   
                    if(EBSBRec.Project_Complexity__c == '1-Simple' && NameToHrsPendingMap != null && NameToHrsPendingMap.containsKey(EBSBRec.Project_Stage__c)){
                        EBSBRec.Hrs_Pending_for_Completion__c = NameToHrsPendingMap.get(EBSBRec.Project_Stage__c).SimplePendingHrs__c;
                    }else if(EBSBRec.Project_Complexity__c == '2-Medium' && NameToHrsPendingMap != null && NameToHrsPendingMap.containsKey(EBSBRec.Project_Stage__c)){
                        EBSBRec.Hrs_Pending_for_Completion__c = NameToHrsPendingMap.get(EBSBRec.Project_Stage__c).MediumPendingHrs__c;
                    }else if(EBSBRec.Project_Complexity__c == '3-Advanced' && NameToHrsPendingMap != null && NameToHrsPendingMap.containsKey(EBSBRec.Project_Stage__c)){
                        EBSBRec.Hrs_Pending_for_Completion__c = NameToHrsPendingMap.get(EBSBRec.Project_Stage__c).AdvancedPendingHrs__c;
                    }else if(EBSBRec.Project_Complexity__c == '4-Complex' && NameToHrsPendingMap != null && NameToHrsPendingMap.containsKey(EBSBRec.Project_Stage__c)){
                        EBSBRec.Hrs_Pending_for_Completion__c = NameToHrsPendingMap.get(EBSBRec.Project_Stage__c).ComplexPendingHrs__c;
                    }   
                    EBSBToBeInsertedList.add(EBSBRec);
                }
            }
        }  
        if(!EBSBToBeInsertedList.isEmpty()){
            insert EBSBToBeInsertedList;
            sendEmail(EBSBToBeInsertedList);
            // Serialize the list of BigMachines_User_Management__c objects.
            String EBProjectListString = JSON.serialize(EBSBToBeInsertedList);
            assignToEBLeadership(EBProjectListString);
            this.markRun();
        }
    }  
    
    Boolean sendExpressEmail = false;
    Boolean sendScopeEmail = false;
    Boolean expressEmailSent = false;
    Boolean scopeEmailSent = false;
    Integer sendScopeEmailLimit = 0;
    Integer sendExpressEmailLimit = 0;        
    
    public void sendEmail(List<EB_SB_Builder__c> EBProjectList){
        for(EB_SB_Builder__c ebproject : EBProjectList){
            if(ebproject.Project_Type_del__c != 'Enterprise Project' && ebproject.Project_Type_del__c != 'Event Quarterback Project'){
                if(ebproject.Project_Type_del__c == 'Event Builder - Express'){
                    sendExpressEmail = true;                
                }else{
                    sendScopeEmail = true;                
                }               
                if(sendExpressEmail && !expressEmailSent){
                    EBSurveyNotificationEmail.sendCustomEmail(ebproject.Id);
                    expressEmailSent = true;                
                }else if(sendScopeEmail && !scopeEmailSent){
                    EBSurveyNotificationEmail.sendCustomEmail(ebproject.Id);
                    scopeEmailSent = true;
                }    
            }            
        }     
    }
    
    public static void assignToEBLeadership(String eBProjectsString){
        // Deserialize the list of EB_SB_Builder__c from the JSON string.
        List<EB_SB_Builder__c> EBProjectList = (List<EB_SB_Builder__c>)JSON.deserialize(eBProjectsString, List<EB_SB_Builder__c>.class);
        // List Declartion and instantiation.              
        List<EB_SB_Builder__c> updatedEBOwnerList = new List<EB_SB_Builder__c>();            
        // Assign projects to Event Builder Leaders queue.
        for(EB_SB_Builder__c ebproject : EBProjectList){
            ebproject.OwnerId = eventBuilderLeadersQueueId;
            updatedEBOwnerList.add(ebproject); 
        }    
        
        // Assign to Queue if their is no available user found.
        if(!updatedEBOwnerList.isEmpty()){
            update updatedEBOwnerList;
        }
    }
}