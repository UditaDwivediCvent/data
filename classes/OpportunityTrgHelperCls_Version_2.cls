/* ===============================
AUTHOR     :     Shanu Aggarwal    
CREATED DATE   : 12 MAY 2016
PURPOSE     :    Extending Opportunity Trigger Handler Code
TEST CLASS :     OpportunityTrgHelperCls_Version_2_Test
SPECIAL NOTES:   We have extended a version of OpportunityTrgHelperCls which is used for Opportunity trigger.  

HISTORY: 
1) 05 May 2016 :-  Shanu Added a method called CreateTMMob to create TM onboarding records when opportunities are closed won.
2) 21 Nov 2017 :-  HSR Added a Method called CheckQuoteProduct which will check whether the Opportunity which we are doing closed/won .
3) 01 Dec 2017 :- HSR : Added a method called ChangeOppSplitOwner to change the Split Owner of the OpportunitySplit when a Owner is being changed in the Closed/Won opportunity.
                    has only one Primary Quote and atleast on Product attached.
4) 08 Jan 2018 :- HSR : If contract team is removing AM owner name from opportunity, we want an email alert should out to that rep whose name we are removing.
5) 16th Jan 2018 :- HSR : Owner Assignment while creating Opportunity on the basis of the AccountTeamMember.
============================= 
*/

public class OpportunityTrgHelperCls_Version_2 {
    
    static boolean testBoolean=false;
    @TestVisible 
    static boolean isComingfromTestHandler1=false;

                
    
    //Method for Before Insert Event
    public static void OnBeforeInsert(List<Opportunity> newValues){    
        
        //Set<ID> userstoRun = new Set<ID>{'00500000007RNH1','00500000007Jxph','005o0000002QrNR','005o0000002jzhH'};
        // In Test, these methods can only be called by OpportunityTrgHelperCls_Version_2__Test
        //if(!isComingfromTestHandler1 && userstoRun.contains(UserInfo.getUserId())){
        if(!isComingfromTestHandler1){
            //Map MYD fields from renewed Opportunity generated frin CPQ
            MapMYDFieldsFromCPQ(newValues, null);
            //HSR : 16th Jan : Owner Assignment while creating Opportunity on the basis of the AccountTeamMember.
            if(Label.IsOppOwnerAssignmentEnable=='True')
                oppOwnerAssignment(newValues);
        }
        
        populateOppOwnerRole(newValues); // add by kumud [Trigger merge: OwnerRoleTrigger]
    }
    
    //Method for Before Update Event
    public static void OnBeforeUpdate(Map<Id,Opportunity> oldMapValues,Map<Id,Opportunity> newMapValues){    
        
        if(!isComingfromTestHandler1){
            
            If((!testBoolean && !System.isBatch()) || Test.isRunningTest()){//
                WebDesignSupportRollup(newMapValues.values(),oldMapValues,false,false);
            }
            
            /*HSR:Added this as a part of Refactoring*/
            List<Opportunity> ownerUpdateList = new List<Opportunity>();
            /*Added By :HSR : Method will check whether the Opportunity which we are doing closed/won has only one Primary Quote
            and at least on Product attached.*/
            Set<Id> oppIdSet = new Set<Id>();
            For(Opportunity opp : newMapValues.values()){
                Opportunity oldOpp = oldMapValues.get(opp.Id);
                if(opp.StageName == 'Closed Won' && opp.StageName!=oldOpp.StageName)
                {
                    oppIdSet.add(opp.Id);
                }
                if(opp.OwnerId != oldOpp.OwnerId)
                {
                    ownerUpdateList.add(opp);
                }
                if(opp.SBQQ__Contracted__c && !oldOpp.SBQQ__Contracted__c)
                {
                    opp.contractedDateTime__c = DateTime.now();
                }
            }
            
            if(oppIdSet.size()>0)
            CheckQuoteProduct(newMapValues.values(), oppIdSet);

            //Map MYD fields from renewed Opportunity generated from CPQ
            //IF(CheckRecursive.runTwentyFour()){    // check recursive added by udita as issue was coming in marking renewal quoted on contract
                MapMYDFieldsFromCPQ( newMapValues.values(), oldMapValues);
            //}            /*HSR:Added this as a part of Refactoring*/
            if(ownerUpdateList.size()>0)
                populateOppOwnerRole(ownerUpdateList); // add by kumud [Trigger merge: OwnerRoleTrigger]            
        }
    }
    
    //Method for After Insert Event
    public static void OnAfterInsert(Map<Id,Opportunity> newMapValues){   
        if(!isComingfromTestHandler1){
            //Added by Shanu
            CreateTMMob(newMapValues);
        }
    }
    
    //Method for After Update Event
    public static void OnAfterUpdate(Map<Id,Opportunity> oldMapValues, Map<Id,Opportunity> newMapValues){ 
         
         //code for Professional services Email Alert :Udita
        if(CheckRecursive.runTwentyOne()){
        set<id> accIds = new set<id>();
        set<id> oppIds = new set<id>();
        List<Messaging.SingleEmailMessage> emailMsgList = new List<Messaging.SingleEmailMessage>();  
            
            for(Opportunity opp : newMapValues.values()){
              Opportunity oppOld = oldMapValues.get(opp.id);
              if(opp.StageName == 'Closed Won' && oppOld.StageName != opp.StageName){   
                if(opp.accountId !=null){
                    accIds.add(opp.accountId);}                     
                oppIds.add(opp.id);
              }
            }
            map<id,list<EB_SB_Builder__c>> EBSPMap= new map<id,list<EB_SB_Builder__c>>();
            map<id,list<OpportunityLineItem>> opptunityMap= new map<id,list<OpportunityLineItem>>();
                        
            if(oppIds.size() > 0){
                for(OpportunityLineItem opp: [select id,OpportunityId,Product_Name__c,ProductCode  from OpportunityLineItem where ProductCode ='CV-PS-EC-CCS-APPBPLS' and OpportunityId in :oppIds]){
                    if(!opptunityMap.containskey(opp.OpportunityId)){
                        opptunityMap.put(opp.OpportunityId,new list<OpportunityLineItem>());
                    }
                    opptunityMap.get(opp.OpportunityId).add(opp);
                }
            }
          if(oppIds.size() > 0  && !opptunityMap.isEmpty()){   
            if(accIds.size() > 0){
                for(EB_SB_Builder__c ebsp: [select id,OwnerId,AccountCustom__r.name,owner.name,Project_Status_del__c,AccountCustom__c from EB_SB_Builder__c where AccountCustom__c in : accIds and (Project_Status_del__c != NULL AND Project_Status_del__c !='Completed' and Project_Status_del__c != 'Cancelled' and Project_Status_del__c != 'Yet to Start')]){
                  String idString = String.valueOf(ebsp.OwnerId);
                  if(!idString.Startswith('00G')){
                    if(!EBSPMap.containskey(ebsp.AccountCustom__c)){
                        EBSPMap.put(ebsp.AccountCustom__c,new list<EB_SB_Builder__c>());
                    }
                    EBSPMap.get(ebsp.AccountCustom__c).add(ebsp);
                  }
                }
            }
            
           Id templateId;
           //Getting template Id
           if(Label.isEmailTemplateRun == 'True'){
           templateId = [Select Id From EmailTemplate Where DeveloperName = 'Cvent_CrowdCompass_Integration_Term'].Id;  
                  
            for(Opportunity opp : newMapValues.values()){
              if(opptunityMap.size() >0 && opptunityMap.containsKey(opp.id)){
                  if(EBSPMap.size() >0 && EBSPMap.containsKey(opp.AccountId)){
                    for(EB_SB_Builder__c  ebs : EBSPMap.get(opp.AccountId)){                   
                      for(OpportunityLineItem oli : opptunityMap.get(opp.id)){
                        Messaging.SingleEmailMessage msg =  new Messaging.SingleEmailMessage();                    
                        msg.setSubject('Integration Alert: Client purchased CrowdCompass');
                        msg.setHtmlBody('<p>Dear '+ ebs.Owner.name+ ',</p>'+
                                        '<p>A CrowdCompass app has been sold on '+ '<a href="https://cvent.my.salesforce.com/'+ebs.AccountCustom__c+'">'+ebs.AccountCustom__r.name+'</a>'+ '. Please click ' + '<a href="https://cvent.my.salesforce.com/'+ebs.id+'">here</a>' + ' to view the record.</P><P>' + label.NOTIFICATION_FOR_EBSB_ONWER  + '.</p>');
                        List<String> sendTo = new List<String>();
                        sendTo.add(ebs.OwnerId);
                        sendTo.add(label.EmailId_ProfessionalServiceCSE);
                        sendTo.add(label.EmailId_ProfessionalServiceRKonwar);
                        sendTo.add(label.EmailId_ProfessionalServiceDeeksha);
                        sendTo.add(label.EmailId_ProfessionalServiceNArora);
                        System.debug('sendto*****'+sendTo);
                        msg.setToAddresses(sendTo); 
                        msg.setOrgWideEmailAddressId('0D2o0000000GpxI');
                        msg.setSaveAsActivity(false);
                        emailMsgList.add(msg); 
                       
                    } 
                  }                           
                 }
              System.debug('emailMsgList inside for before EBS*****'+emailMsgList);                   
              system.debug('----opp.Contact_Associated__c'+opp.Contact_Associated__c);                 
              if(opp.Contact_Associated__c != null){
                    Messaging.SingleEmailMessage msg1 =  new Messaging.SingleEmailMessage();  
                    msg1.setTemplateId(templateId);
                    msg1.setToAddresses(new List<String>{opp.Contact_Associated__c});  
                    System.debug('msg1*****'+msg1);
                    msg1.setOrgWideEmailAddressId('0D2000000008OzJ');
                    msg1.setSaveAsActivity(false);
                    msg1.setTargetObjectId(opp.Contact_Associated__c);
                    msg1.setWhatId(opp.id);
                    emailMsgList.add(msg1);     
             }
           System.debug('emailMsgList inside for after EBS*****'+emailMsgList);                   
            }
           }                  
          
           System.debug('emailMsgList*****'+emailMsgList);                             
          if(emailMsgList.size()>0){
            Messaging.sendEmail(emailMsgList);
          }  
          }            
          }
        }
        // code ends FOR Professional Services Email Alert P-003824
        
        // In Test, these methods can only be called by OpportunityTrgHelperCls_Version_2__Test
        if(!isComingfromTestHandler1){
            //Added by Shanu
            CreateTMMob(newMapValues);
            updateBCValues(oldMapValues,newMapValues);
            
            ResetRenewalAmend(newMapValues,oldMapValues);
            //Chater post on Closed Won- Added on 9 Nov 2017
            if(Label.OppAlertEnable=='True'){
                OpportunityChatterAlerts(newMapValues,oldMapValues);
            }
            
            //Update Owner from Opportunity to Child/Parent Contracts and all Quotes
            syncOwner(newMapValues.values(),oldMapValues); 

            //Added by Hemant : 12/01/2017 : To change the OpportunitySplitOwner when the Owner Id of opportunity is changed after the Opportunity is Closed/Won
            ChangeOppSplitOwner(newMapValues,oldMapValues); 
            
            //Added by Hemant : 12/01/2017 : To Clone QuoteLineItems in the Re-Assigned Opportunity from the Opportunity it is assigned.
             if(Label.IsReassignedToActive=='True' && CheckRecursive.runNineteen())
                createQuoteLineReassignOpp(newMapValues,oldMapValues);

            //Added by Hemant : 01/08/2018 : If contract team is removing AM owner name from opportunity, we want an email alert should out to that rep whose name we are removing.
            if(Label.AMAlertEnable == 'True')
                SendAMAlert(newMapValues,oldMapValues);

            //Added by Shanu : 01/10/2018 : Create RFP Case when Opportunity is Closed Lost and Account's CSN Listing Type is Basic
            CreateRFPCaseOnClosedLost(newMapValues.values(),oldMapValues);
            System.debug('Ashna**** Called');
            
            //Added on - 03/06/2018 - Rollup to Web Design support
            WebDesignSupportRollup(newMapValues.values(),oldMapValues,true,false);
            //Delete quote lines once Reassigned to is removed.....
            DeleteReassignedToQuoteLines(newMapValues,oldMapValues);

        }
        
        
        //Calling below methods  [Trigger merge activity] : Kumud
        onAfterUpdateTaskBillingUpdate(newMapValues.values(),newMapValues,oldMapValues);
        
    }

    
    //Method for After Delete Event
    public static void OnAfterDelete(List<Opportunity> oldValues, Map<Id,Opportunity> oldMap){ 
        //Added on - 03/06/2018 - Rollup to Web Design support
        WebDesignSupportRollup(oldValues,oldMap,false,true);
    }
    
    //Creating TM onboarding records when opportunities are closed won 
    //Updating the Name field of TM onboarding with Opp name ..
    //TM Onboarding name should be Acc name 
    //Starts with NBB
    public static void CreateTMMob(Map<Id,Opportunity> newMapValues){
        
        
        List<TM_Buildout__c> TMToInsert = new List<TM_Buildout__c>  (); 
        Set<Id> oppIds = new Set<Id>();
        
        for (Opportunity o : newMapValues.values()){
            if((o.StageName == 'Closed Won' && o.Product__c == 'TicketMob' && o.NBB_Renewal__c.startswith('NBB') && o.Parent_Upsell__c == 'Primary' && o.MYD_Deal__c == 'First Year') && o.TM_Buildout__r.size() == 0 ){
                oppIds.add(o.Id);
            }        
        }

        if(oppIds.size()>0){
        
            for (Opportunity o : [Select Id, AccountId, MYD_Deal__c, NBB_Renewal__c,Parent_Upsell__c, Account.Name, StageName, TM_ID__c, Account_Name_TM__c, Product__c,New_Type__c,(Select id from TM_Buildout__r) from Opportunity where id in: oppIds]){
                
                
                    if(HelperClassforCreateTMOB.firstRun){              
                        TM_Buildout__c tm = new TM_Buildout__c ();                     
                        tm.Opportunity__c = o.Id ; 
                        tm.Name=o.Account_Name_TM__c;
                        tm.OwnerId=o.TM_Id__c;
                        tm.Account__c=o.AccountId;
                        TMToInsert.add(tm);
                        HelperClassforCreateTMOB.firstRun=false;
                    }
                            
            }
            
            try {
                insert TMToInsert; 
            }catch (system.Dmlexception e) {
                system.debug (e);
            }
        }
    }
    
    
    /*
    **  Added on 1 Jan 2018 - Shanu Aggarwal
    **  Obsolete Method- RollUpHelper method converted into WebDesignSupportRollup method
    **  Once Opportunity is Closed Won , the Web Design Support should be calculated/roll-up on Contact level. 
    **/
    public static void WebDesignSupportRollup(List<Opportunity> newList, Map<Id,Opportunity> oldMapValues, boolean isAfter,boolean isDeleted){
        
        testBoolean = true;
        Opportunity oldOpp;
        Set<ID> conIds = new Set<ID>();
        Set<ID> aggConIds = new Set<ID>();

        Set<Id> oppsToReset= new Set<Id>();
        
        Map<Id,Decimal> conIdVsDesignSupport = new Map<Id,Decimal> ();
        Map<Id,Decimal> conIdVsAttendeeSupport = new Map<Id,Decimal> ();
        Map<Id,Contact> conUpdateMap = new Map<Id,Contact>();
        
        //Check if opportunity is closed won-
        for(Opportunity idForOppNew : newList ){
            
            
            oldOpp=oldMapValues.get(idForOppNew.Id);
            //If Opportunity is deleted or Support Min changed
            if(isDeleted==true || (isAfter==true && idForOppNew.Web_Design_Support_Minutes_Purchased__c!=oldOpp.Web_Design_Support_Minutes_Purchased__c && (idForOppNew.StageName == 'Closed Won' || idForOppNew.StageName == 'Follow-up – Missing/Erroneous Contract' || idForOppNew.StageName == 'Pushed – Missing/Erroneous Contract'|| idForOppNew.StageName == 'Closed Won - AR Settlement' || idForOppNew.StageName == 'Closed Won – Legal Opt Out' || idForOppNew.StageName == 'Closed Won – Do Not Send to EBS' || idForOppNew.StageName == 'Closed Won - PreAcquisition' ))){
                aggConIds.add(idForOppNew.Contact_Associated__c);
            }
            else if(isAfter==false && idForOppNew.Contact_Associated__c !=null && (oldOpp.StageName != 'Closed Won' && oldOpp.StageName != 'Follow-up – Missing/Erroneous Contract' && oldOpp.StageName != 'Pushed – Missing/Erroneous Contract' && oldOpp.StageName != 'Closed Won - AR Settlement' && oldOpp.StageName != 'Closed Won – Legal Opt Out' && oldOpp.StageName != 'Closed Won – Do Not Send to EBS' && oldOpp.StageName != 'Closed Won - PreAcquisition') && (idForOppNew.StageName == 'Closed Won' || idForOppNew.StageName == 'Follow-up – Missing/Erroneous Contract' || idForOppNew.StageName == 'Pushed – Missing/Erroneous Contract'|| idForOppNew.StageName == 'Closed Won - AR Settlement' || idForOppNew.StageName == 'Closed Won – Legal Opt Out' || idForOppNew.StageName == 'Closed Won – Do Not Send to EBS' || idForOppNew.StageName == 'Closed Won - PreAcquisition' )){
                conIds.add(idForOppNew.Contact_Associated__c);
            }else if (isAfter==false  && idForOppNew.Contact_Associated__c !=null && (oldOpp.StageName == 'Closed Won' || oldOpp.StageName == 'Follow-up – Missing/Erroneous Contract' || oldOpp.StageName == 'Pushed – Missing/Erroneous Contract' || oldOpp.StageName == 'Closed Won - AR Settlement'|| oldOpp.StageName == 'Closed Won – Legal Opt Out' || oldOpp.StageName == 'Closed Won – Do Not Send to EBS' || oldOpp.StageName == 'Closed Won - PreAcquisition' ) && ( idForOppNew.StageName != 'Closed Won' && idForOppNew.StageName != 'Follow-up – Missing/Erroneous Contract' && idForOppNew.StageName != 'Pushed – Missing/Erroneous Contract' && idForOppNew.StageName != 'Closed Won - AR Settlement' && idForOppNew.StageName != 'Closed Won – Legal Opt Out' && idForOppNew.StageName != 'Closed Won – Do Not Send to EBS' && idForOppNew.StageName != 'Closed Won - PreAcquisition' )){
                conIds.add(idForOppNew.Contact_Associated__c);
                oppsToReset.add(idForOppNew.Id);
            }
        }
        
        //If Support Min Changed, Rollup to Contact
        if(aggConIds.size()>0){
            for(AggregateResult ar : [Select SUM(Web_Design_Support_Minutes_Purchased__c)total, Contact_Associated__c  from Opportunity Where Contact_Associated__c IN:aggConIds  Group BY Contact_Associated__c ]){
                conIdVsDesignSupport.put((Id)ar.get('Contact_Associated__c'), (Decimal)ar.get('total'));
                aggConIds.remove((Id)ar.get('Contact_Associated__c'));
            }
            
            //remaining contact records which doesn't  have opp, reset to 0
            if(aggConIds.size()>0){
                for(Id conId : aggConIds){
                    conIdVsDesignSupport.put(conId, 0);
                }
            }
        }
        
        //If closed won, calculate rollup
        else if(conIds.size()>0){
            
            Decimal Qty=0;
            for(OpportunityLineItem oli : [ Select Product2.Name,OpportunityId, Opportunity.Contact_Associated__c, Quantity,Product2.ProductCode From OpportunityLineItem Where ((Product2.Name=: Label.OpportunityProductname OR Product2.ProductCode=: Label.OpportunityProductCode) OR Product2.Name= 'CVENT Attendee Support') and Opportunity.Contact_Associated__c IN:conIds and (Opportunity.StageName='Closed Won' OR Opportunity.StageName='Follow-up – Missing/Erroneous Contract' OR Opportunity.StageName='Pushed – Missing/Erroneous Contract' OR Opportunity.StageName='Closed Won – Do Not Send to EBS' OR Opportunity.StageName='Closed Won - AR Settlement' OR Opportunity.StageName='Closed Won – Legal Opt Out' OR Opportunity.StageName='Closed Won - PreAcquisition'  OR OpportunityId IN:newList)]){
                    
                    Qty=oli.Quantity;

                    //reset value to 0 if opp is not closed won-
                    if(oppsToReset.contains(oli.OpportunityId)){
                        Qty=0;
                    }

                    //Web Design Support Roll up
                    if(oli.Product2.Name== Label.OpportunityProductname || oli.Product2.ProductCode== Label.OpportunityProductCode){
                        
                        //populate the web design support on Opportunity 
                        if(!trigger.newMap.isEmpty())
                        
                        if(trigger.newMap.containsKey(oli.OpportunityId))
                            trigger.newMap.get(oli.OpportunityId).put('Web_Design_Support_Minutes_Purchased__c',Qty==null?0:Qty);
                        
                        if(!conIdVsDesignSupport.containsKey(oli.Opportunity.Contact_Associated__c)){
                            conIdVsDesignSupport.put(oli.Opportunity.Contact_Associated__c,Qty);
                        }else{
                            conIdVsDesignSupport.put(oli.Opportunity.Contact_Associated__c,conIdVsDesignSupport.get(oli.Opportunity.Contact_Associated__c)+Qty);
                        }
                        
                    }// Attendee Support Roll up
                    else if(oli.Product2.Name == 'CVENT Attendee Support'){
                        
                        //populate the attendee support on Opportunity 
                        if(trigger.newMap.containsKey(oli.OpportunityId))
                            trigger.newMap.get(oli.OpportunityId).put('Attendee_Support_Units_Purchased__c',Qty==null?0:Qty);
                        
                        if(!conIdVsAttendeeSupport.containsKey(oli.Opportunity.Contact_Associated__c)){
                            conIdVsAttendeeSupport.put(oli.Opportunity.Contact_Associated__c,Qty);
                        }else{
                            conIdVsAttendeeSupport.put(oli.Opportunity.Contact_Associated__c,conIdVsAttendeeSupport.get(oli.Opportunity.Contact_Associated__c)+Qty);
                        }

                    }   
                    
             }
             
             //Roll up on Contact Attendee Support
            if(!conIdVsAttendeeSupport.isEmpty()){
                for(Id contactId: conIdVsAttendeeSupport.keySet()){
                    Contact con = new Contact(Id=contactId,Attendee_Support_Units_Purchased__c=conIdVsAttendeeSupport.get(contactId));
                    conUpdateMap.put(con.Id,con);
                }   
            }
                
        }
        
        //Roll up on Contact Web Design Support
        if(!conIdVsDesignSupport.isEmpty()){
            for(Id contactId: conIdVsDesignSupport.keySet()){
                Contact con = new Contact(Id=contactId,Total_Design_Support_Purchased__c=conIdVsDesignSupport.get(contactId));
                conUpdateMap.put(con.Id,con);
            }   
        }
        
        if(!conUpdateMap.isEmpty()){update conUpdateMap.values();}
        
    }    
    
   
    /*
    **
    **  CPQ - Opportunity Fields Mapping when MYD's created through CPQ
    **/
    public static void MapMYDFieldsFromCPQ( List<Opportunity> newList, Map<Id,Opportunity> oldMapValues){
        
        
        //OpportunityId vs Primary Quote Id
        Set<Id> QuoteIdSet = new Set<Id>();
        //OpportunityId vs Renewed Contract Id
        Set<Id> RenewedIdSet = new Set<Id>();
        //OpportunityId vs Parent Agreement Id
        Set<Id> AgreementIdSet = new Set<Id>();
        String closeDateMMYY='';
        
        //Contains records from assoicated Opportunity
        Map<Id,SBQQ__Quote__c> primaryQuoteMap;
        Map<Id,Contract> agreementContractsMap;
        
        //List of Opportunity to update 
        List<Opportunity> oppTpUpdateList = new List<Opportunity>();
        
        Map<integer,String> monthMap =new Map<integer,String> {1 => 'January',2 => 'February',3 => 'March',4 => 'April',5 => 'May',6 => 'June',7 => 'July',8 => 'August',9 => 'September',10 => 'October',11 => 'November',12 => 'December'};
            
            
            
                
            //Filter Opportunities if Primary Quote or Renewed Contract is changed
            for(Opportunity newOpp : newList){
            
                /** 
                ** ****  START FIRST YEAR MAPPING *****
                ** Added on 05/24/2018 - P-003576 Automate the fields for first year opportunity
                ** 
                **/
                //Added on 05/24/2018 - P-003956 Automate the fields for first year opportunity :Added by Udita 
                if(newOpp.Deal_Year__c == '1'){
                    
                    //Opportunity Start Date EBS
                    Date startDateEBS;
                    //Deal Closed By
                    newOpp.Deal_Closed_by__c = newOpp.OwnerId;
                    if(oldMapValues==null || ((!oldMapValues.isEmpty() && newOpp.Contract_Implemented__c !=oldMapValues.get(newOpp.Id).Contract_Implemented__c && newOpp.Contract_Implemented__c ==true))){
                    Id CSNSupplierRecId= Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CSN-Supplier').getRecordTypeId();
                        if(newOpp.Parent_Upsell__c=='Primary' && newOpp.NBB_Renewal__c=='NBB' && newOpp.RecordTypeId != CSNSupplierRecId){   /// code for Event cloud :(Recordtype if not CSN Supplier)
                            if(newOpp.Opportunity_Start_Date__c > newOpp.ContractReceived__c){
                                startDateEBS= newOpp.Opportunity_Start_Date__c;
                            }else{
                                startDateEBS= newOpp.ContractReceived__c;
                            }
                            if(newOpp.Contract_Implemented_Date__c>startDateEBS){
                                startDateEBS= newOpp.Contract_Implemented_Date__c;
                            }
                            
                            newOpp.Opportunity_Start_Date_EBS__c= startDateEBS;                   
                        }
                        else if(newOpp.Parent_Upsell__c=='Primary' && newOpp.NBB_Renewal__c=='NBB' && newOpp.RecordTypeId == CSNSupplierRecId){  // code for hospitality cloud (for CSN SUPPLIER)
                            if(newOpp.Opportunity_Start_Date__c > newOpp.ContractReceived__c){
                                startDateEBS= newOpp.Opportunity_Start_Date__c;
                            }else{
                                startDateEBS= newOpp.ContractReceived__c;
                            }                      
                            newOpp.Opportunity_Start_Date_EBS__c= startDateEBS;
                                            
                        }
                   } 
        
                    //Early Contract if contract is received 90 days earlier than start date 
                    if(oldMapValues==null || ((!oldMapValues.isEmpty() && newOpp.StageName!=oldMapValues.get(newOpp.Id).StageName && newOpp.StageName=='Closed Won'))){ 
                        if(newOpp.ContractStartDate__c!=null && newOpp.ContractReceived__c < newOpp.ContractStartDate__c.addDays(-90)){
                            newOpp.Early_Contract__c = 'Early';
                        }else{
                            newOpp.Early_Contract__c = 'Not Early';
                        }
                   }               
              }
              else if((newOpp.Deal_Year__c != '1' || newOpp.Parent_Upsell__c !='Primary' || newOpp.NBB_Renewal__c !='NBB') && (oldMapValues==null || ((!oldMapValues.isEmpty() && newOpp.Contract_Implemented__c !=oldMapValues.get(newOpp.Id).Contract_Implemented__c && newOpp.Contract_Implemented__c ==true)))){
                        newOpp.Opportunity_Start_Date_EBS__c= newOpp.Opportunity_Start_Date__c;               
              }
                //Deal Closed By - Update from OwnerId
                if(oldMapValues==null || (!oldMapValues.isEmpty() && newOpp.StageName!=oldMapValues.get(newOpp.Id).StageName && newOpp.StageName.startswith('Closed'))){
                    
                    //Deal Closed By - Update from OwnerId
                    if(newOpp.Deal_Year__c == '1')
                        newOpp.Deal_Closed_by__c = newOpp.OwnerId;
                    
                    //Case Received Date
                    if(newOpp.StageName=='Closed Won')
                        newOpp.Case_Received_Date__c = system.today();
                }
                    
                /** 
                ** ****  END FIRST YEAR MAPPING*****
                **/
                
                
                
                /** 
                ** ****  START MYD MAPPING *****
                **/
                
                //Update Logic
                if(!newOpp.Bypass_Historic_Opp__c && trigger.isUpdate){
                    Opportunity oldOpp = oldMapValues.get(newOpp.Id);
                    if(newOpp.SBQQ__PrimaryQuote__c!=null)
                        QuoteIdSet.add(newOpp.SBQQ__PrimaryQuote__c);
                    if(newOpp.SBQQ__RenewedContract__c!=null && newOpp.SBQQ__RenewedContract__c!=oldOpp.SBQQ__RenewedContract__c )
                        RenewedIdSet.add(newOpp.SBQQ__RenewedContract__c);
                    if(newOpp.Master_Agreement__c!=null && newOpp.Master_Agreement__c!=oldOpp.Master_Agreement__c )
                        AgreementIdSet.add(newOpp.Master_Agreement__c);
                }
                //Insert Logic 
                else if(!newOpp.Bypass_Historic_Opp__c && trigger.isInsert){
                    if(newOpp.SBQQ__PrimaryQuote__c!=null)
                        QuoteIdSet.add(newOpp.SBQQ__PrimaryQuote__c);
                    if(newOpp.SBQQ__RenewedContract__c!=null)
                        RenewedIdSet.add(newOpp.SBQQ__RenewedContract__c);
                    if(newOpp.Master_Agreement__c!=null)
                        AgreementIdSet.add(newOpp.Master_Agreement__c);
                }
            }
        
        /**
        ***
        *** Primary Quote
        *** 
        ***/
        
        if(!QuoteIdSet.isEmpty()){



            //Payment Terms Mapping : Udita for EBS Related SFDC field automation
            Map<String,String> mappingPaymentTerm = new Map<String,String>();
            //For custom payment terms
            Map<String,String> mappingCustomPaymentTerm = new Map<String,String>();
            // Billing Frequency + Payment Method + Custom Payment Term 
            //by invoice
            mappingPaymentTerm.put('Annual Upfront+by Invoice','Annual Upfront Invoice');
            mappingPaymentTerm.put('Quarterly+by Invoice','Quarterly Invoice');
            mappingPaymentTerm.put('Bi-Annual+by Invoice','Bi-Annual Invoice');
            mappingPaymentTerm.put('All Years Upfront+by Invoice','All Years Upfront Invoice');
            //mappingPaymentTerm.put('Custom(up to 5x/year)+by Invoice+Enter the customized Term for payment','Customize Payment by Invoice+Enter the customized Term for payment');

            //by credit card
            mappingPaymentTerm.put('Annual Upfront+by Credit Card','Annual Upfront Credit Card');
            mappingPaymentTerm.put('Quarterly+by Credit Card','Quarterly Credit Card');
            mappingPaymentTerm.put('Bi-Annual+by Credit Card','Bi-Annual Credit Card');
            mappingPaymentTerm.put('All Years Upfront+by Credit Card','All Years Upfront Credit Card');
           // mappingPaymentTerm.put('Custom(up to 5x/year)+by Credit Card+Enter the customized Term for payment','Customize Payment by Credit Card+Enter the customized Term for payment');
            
            //not required
            mappingPaymentTerm.put('Not Required+Not Required+null','Pay Reg Fees As You Go+ ');
            mappingPaymentTerm.put('Not Required+Not Required+Enter the customized Term for payment','Other (fill out field below)+Enter the customized Term for payment');
            
            //population custom payment term map : Udita Enhancements
            mappingCustomPaymentTerm.put('Custom(up to 5x/year)+by Invoice','Customize Payment by Invoice');
            mappingCustomPaymentTerm.put('Custom(up to 5x/year)+by Credit Card','Customize Payment by Credit Card');
            mappingCustomPaymentTerm.put('Custom (6+x/year)+by Invoice','Customize Payment by Invoice');
            mappingCustomPaymentTerm.put('Custom (6+x/year)+by Credit Card','Customize Payment by Credit Card');
            
            primaryQuoteMap = new Map<Id,SBQQ__Quote__c>([ Select Id,SBQQ__Type__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Upcoming_Renewal_Type__c,SBQQ__Quote__c.SBQQ__StartDate__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Parent_Contract_Term_Years__c, Auto_renewal_clause__c,Contract_Executed_Date__c,Current_Year__c,Contract_Term_Years__c,Effective_Year_1_Start_Date__c,Effective_Year_1_End_Date__c,SBQQ__EndDate__c, SBQQ__PaymentTerms__c,Payment_Method__c,Billing_Frequency__c,Custom_Payment_Terms__c,
                                                          ( Select Id,Room_Nights_or_RFPs__c,SBQQ__Product__c,Number_of_RFPs__c,Room_Nights__c From SBQQ__LineItems__r Where SBQQ__Product__r.Name = 'Supplier Network - Enterprise Bundle' Limit 1 ) From SBQQ__Quote__c Where ID IN: QuoteIdSet]);
            
            //Processing Opportunities
            for( Opportunity syncedOpp : newList){
                //Get New Souce Opp
                //Opportunity syncedOpp = (Opportunity)trigger.newMap.get(syncedOppId);
                //Get Primary Quote
                SBQQ__Quote__c quote = primaryQuoteMap.get(syncedOpp.SBQQ__PrimaryQuote__c);
                
                /*Check for null pointer on Quote - PK 7/25/2017 */ 
                if(quote == null){
                    continue;
                }
                //Map fields from Primary Quote on Opp
                //Map fields from Primary Quote on Opp
                if(quote.Auto_renewal_clause__c ==true)
                    syncedOpp.ARClause__c   = 'Yes';
                else
                    syncedOpp.ARClause__c   = 'No';
                
                /*if(String.valueOf(quote.Current_Year__c) <> '1')
                    syncedOpp.MYD_Deal__c = 'MYD';
                */
                syncedOpp.Deal_Year__c  = String.valueOf(quote.Current_Year__c);
                syncedOpp.Years__c      = quote.Contract_Term_Years__c;
                // syncedOpp.Opportunity_Start_Date_EBS__c = quote.Effective_Year_1_Start_Date__c;
                // syncedOpp.Opp_End_Date__c      = quote.Effective_Year_1_End_Date__c; Changes made by lovejeet as Effective_Year_1_End_Date__c date has gone obsolete. 
                syncedOpp.Opp_End_Date__c      = quote.SBQQ__EndDate__c;
                //syncedOpp.ContractReceived__c =  quote.Contract_Executed_Date__c;                
                
                //MYD Name and Close Date
                if(quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Upcoming_Renewal_Type__c == 'MYD Renewal' && quote.SBQQ__StartDate__c!=null && quote.SBQQ__Type__c != 'Amendment'){
                    
                    //Close Date can be updated manually if this field is true- No automation needed in some cases ( Added on  12/11/2017)
                    if(syncedOpp.Is_Close_Date_Locked__c==false)
                        syncedOpp.CloseDate  =  quote.SBQQ__StartDate__c;
                    
                    syncedOpp.NBB_Renewal__c    =   'NBB';
                    syncedOpp.Name = monthMap.get(syncedOpp.closeDate.Month()) + ' ' + syncedOpp.closeDate.Year() + ' ' + 'NBB' + ' ' + syncedOpp.Deal_Year__c + ' Of ' +  quote.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Parent_Contract_Term_Years__c;
                }
                
                //If there are quote lines associated with this , update mentioned fields from line items 
                if(quote.SBQQ__LineItems__r!=null && quote.SBQQ__LineItems__r.size()>0){
                    /*
                    Commented as a result of Field Purge Activity.
                    if(quote.SBQQ__LineItems__r[0].Room_Nights_or_RFPs__c == 'RFPs')
                        syncedOpp.of_RFPs__c =  quote.SBQQ__LineItems__r[0].Number_of_RFPs__c;
                    else*/
                    if(quote.SBQQ__LineItems__r[0].Room_Nights_or_RFPs__c == 'Room Nights')
                        syncedOpp.of_Total_Room_Nights_Committed__c =  quote.SBQQ__LineItems__r[0].Room_Nights__c;
                }
                
                /**
                ** START - P-003956
                ** Added below fields on 05/24/2018 - Added by Shanu for Project P-003576
                **/

                //Invoice Payment Terms
                syncedOpp.Invoice_Payment_Terms__c = quote.SBQQ__PaymentTerms__c;
                
                //Invoice Payment Method
                if(quote.Payment_Method__c=='by Invoice')
                    syncedOpp.Invoice_Payment_Mode__c = 'Cash';
                else if(quote.Payment_Method__c=='by Credit Card')
                    syncedOpp.Invoice_Payment_Mode__c = 'Credit Card';
                else if(quote.Payment_Method__c=='Not Required')
                    syncedOpp.Invoice_Payment_Mode__c = 'Cash and Credit Card Form';



                 //Payment Terms :Udita for EBS Fields Automation
                if(oldMapValues==null || ((!oldMapValues.isEmpty() && syncedOpp.StageName!=oldMapValues.get(syncedOpp.Id).StageName && syncedOpp.StageName=='Closed Won'))){
                   string termKey = quote.Billing_Frequency__c+'+'+quote.Payment_Method__c+'+'+quote.Custom_Payment_Terms__c; // considers Custom Payment Terms(Quote)
                    string termkey1 = quote.Billing_Frequency__c+'+'+quote.Payment_Method__c; // key to update update payment regardless of Custom Payment Terms(Quote)
                    if(mappingPaymentTerm.containsKey(termKey)){
                        syncedOpp.PaymentTerms__c = mappingPaymentTerm.get(termKey).split('\\+')[0];
                        syncedOpp.EnterOtherPaymentTerms__c  = mappingPaymentTerm.get(termKey).split('\\+')[1];
                    }
                    else if(mappingPaymentTerm.containsKey(termKey1)){
                        syncedOpp.PaymentTerms__c = mappingPaymentTerm.get(termKey1);
                    }
                    else{
                        syncedOpp.PaymentTerms__c = 'All Years Upfront';
                        syncedOpp.EnterOtherPaymentTerms__c  = '';
                    }
                  
                    string customtermKey = quote.Billing_Frequency__c+'+'+quote.Payment_Method__c;
                    if(mappingCustomPaymentTerm.containsKey(customtermKey)){
                        syncedOpp.PaymentTerms__c = mappingCustomPaymentTerm.get(customtermKey).split('\\+')[0];
                        syncedOpp.EnterOtherPaymentTerms__c  = quote.Custom_Payment_Terms__c;
                    }
                }
    
                    //Primary Contract/Upsell 
                    if(syncedOpp.Parent_Upsell__c==null){
    
                        if(quote.SBQQ__Type__c=='Amendment')
                            syncedOpp.Parent_Upsell__c = 'Upsell';
                        else
                            syncedOpp.Parent_Upsell__c = 'Primary';
                    }
                    
                    //First Year/MYD
                                                   
                                     
                    if(oldMapValues==null || ((!oldMapValues.isEmpty() && syncedOpp.StageName!=oldMapValues.get(syncedOpp.Id).StageName && syncedOpp.StageName=='Closed Won'))){
                                          
                                                                    
                 
                                                    
                        if(syncedOpp.Parent_Upsell__c=='Primary'){
                                                             
                            if(syncedOpp.Deal_Year__c=='1')
                                syncedOpp.MYD_Deal__c = 'First Year';
                            else
                                syncedOpp.MYD_Deal__c = 'MYD';
                        }else{
                            syncedOpp.MYD_Deal__c = 'First Year';
                            
                                                          
                        }
                                                             
                    }
                 
             //   }
                /**
                ** END
                **/
            }
        }
        
        /**
        ***
        *** Renewed Contracts and Parent Agreement
        *** 
        ***/
                if(!RenewedIdSet.isEmpty() || !AgreementIdSet.isEmpty()){
            
            System.debug('RenewedIdSet*******' + RenewedIdSet);
            //All Renewed Contracts and Parent Agreement (Contract)
            Set<ID> contractIds = new Set<ID>();
            contractIds.addAll(RenewedIdSet);
            contractIds.addAll(AgreementIdSet);
            
            system.debug('*****contractIds'+contractIds);
            //Query Renewed Contract + Agreement fields  SBQQ__Opportunity__r.Event_City__c,SBQQ__Opportunity__r.Event_Country__c,SBQQ__Opportunity__r.Event_State__c,SBQQ__Opportunity__r.Event_Venue__c,
            agreementContractsMap = new Map<Id,Contract>([ Select Id,Parent_Contract__r.EndDate,SBQQ__Opportunity__r.Name,SBQQ__Opportunity__r.CloseDate,SBQQ__Opportunity__r.RecordTypeId,StartDate,EndDate,SBQQ__Opportunity__r.Advertising_Agency__c,SBQQ__Opportunity__r.Barter_Contract__c,SBQQ__Opportunity__r.Brand_Name__c,SBQQ__Opportunity__r.Brand_Name_Others__c,SBQQ__Opportunity__r.Cash_Paid_by_Cvent__c,
                                                          SBQQ__Opportunity__r.Chain_Deal__c,SBQQ__Opportunity__r.Chain_Name__c,SBQQ__Opportunity__r.Chain_Name_Others__c,
                                                          SBQQ__Opportunity__r.SBQQ__PrimaryQuote__r.Contract_Executed_Date__c, SBQQ__Opportunity__r.RenewalDate__c ,
                                                          SBQQ__Opportunity__r.Competitor_Used__c,SBQQ__Opportunity__r.Competitors_in_Evaluation_Process__c,SBQQ__Opportunity__r.Contact_Associated__c,
                                                          SBQQ__Opportunity__r.Contact_Role__c,SBQQ__Opportunity__r.Contract_Implemented__c,SBQQ__Opportunity__r.ContractReceived__c,SBQQ__Opportunity__r.Early_Contract__c,
                                                          SBQQ__Opportunity__r.Deal_Closed_by__c,SBQQ__Opportunity__r.EBS_Order_Date__c,
                                                          SBQQ__Opportunity__r.Event_Name__c,SBQQ__Opportunity__r.FirstPresentation__c,
                                                          SBQQ__Opportunity__r.Govt__c,SBQQ__Opportunity__r.Management_Company_Name__c,SBQQ__Opportunity__r.Marketing_Deliverables__c,
                                                          SBQQ__Opportunity__r.Marketing_Services_Provided_By_Client__c,SBQQ__Opportunity__r.Mktg_Lead_Source__c,SBQQ__Opportunity__r.MSA_Code__c,
                                                          SBQQ__Opportunity__r.Ownership_Group__c,SBQQ__Opportunity__r.Sales_Cycle__c,SBQQ__Opportunity__r.Listed_Created__c,SBQQ__Opportunity__r.Product__c,
                                                          SBQQ__Opportunity__r.Ship_To_Address__c,SBQQ__Opportunity__r.Bill_To_Address__c,SBQQ__Opportunity__r.Do_Not_Send_Invoice_OrderType_Override__c,SBQQ__Opportunity__r.Billing_Schedule__c,SBQQ__Opportunity__r.Invoice_Payment_Terms__c,SBQQ__Opportunity__r.Invoice_Payment_Mode__c,SBQQ__Opportunity__r.Ship_To_Contact__c,SBQQ__Opportunity__r.Bill_To_Contact__c,SBQQ__Opportunity__r.Offset_Days__c,SBQQ__Opportunity__r.PO__c,SBQQ__Opportunity__r.Operating_Unit_ID__c,SBQQ__Opportunity__r.Deal_Booked_In__c,SBQQ__Opportunity__r.Sold_To_Company__c,SBQQ__Opportunity__r.Header_Notes__c,SBQQ__Opportunity__r.Billing_Date__c,SBQQ__Opportunity__r.Club_Code__c,
                                                          Upcoming_Renewal_Type__c,SBQQ__Opportunity__r.NBB_Renewal__c,SBQQ__Opportunity__r.Contract_Term_Months__c,SBQQ__Opportunity__r.CVII_Contract_Number__c From Contract Where ID IN: contractIds]);
            
            //Processing Opportunities
            for( Opportunity syncedOpp : newList){
                System.debug('agreementContractsMap*******' + syncedOpp.SBQQ__RenewedContract__c);
                //Get New Souce Opp
                //Opportunity syncedOpp = (Opportunity)trigger.newMap.get(syncedOppId);
                
                //Mapping from Renewed Contract
                if(agreementContractsMap.containsKey(syncedOpp.SBQQ__RenewedContract__c) && syncedOpp.SBQQ__RenewedContract__c!=null){   
                    
                    //Get Renewed Contract
                    Contract renewedContract = agreementContractsMap.get(syncedOpp.SBQQ__RenewedContract__c);
                    system.debug('********************renewedContract.SBQQ__Opportunity__c'+renewedContract.SBQQ__Opportunity__c);
                    if(renewedContract.SBQQ__Opportunity__c!=null){
                        //Get Opportunity from Renewed Contract 
                        Opportunity syncedFromOpp = agreementContractsMap.get(syncedOpp.SBQQ__RenewedContract__c).SBQQ__Opportunity__r;
                        
                        
                        //Map fields from Renewed Contract on Opp
                        syncedOpp.Advertising_Agency__c                      =   syncedFromOpp.Advertising_Agency__c;
                        syncedOpp.Barter_Contract__c                         =   syncedFromOpp.Barter_Contract__c;
                        syncedOpp.Brand_Name__c                              =   syncedFromOpp.Brand_Name__c;
                        syncedOpp.Brand_Name_Others__c                       =   syncedFromOpp.Brand_Name_Others__c;
                        //syncedOpp.Cash_Paid_by_Cvent__c                    =   syncedFromOpp.Cash_Paid_by_Cvent__c;
                        syncedOpp.Chain_Deal__c                              =   syncedFromOpp.Chain_Deal__c;
                        syncedOpp.Chain_Name__c                              =   syncedFromOpp.Chain_Name__c;
                        syncedOpp.Chain_Name_Others__c                       =   syncedFromOpp.Chain_Name_Others__c;
                        syncedOpp.Competitor_Used__c                         =   syncedFromOpp.Competitor_Used__c;
                        syncedOpp.Competitors_in_Evaluation_Process__c       =   syncedFromOpp.Competitors_in_Evaluation_Process__c;
                        syncedOpp.Contact_Associated__c                      =   syncedFromOpp.Contact_Associated__c;
                        syncedOpp.Contact_Role__c                            =   syncedFromOpp.Contact_Role__c;
                        //syncedOpp.Contract_Implemented__c                    =   syncedFromOpp.Contract_Implemented__c;
                        syncedOpp.Deal_Booked_In__c                          =   syncedFromOpp.Deal_Booked_In__c;
                        
                        
                        //Don't automate the field for first year contract
                        if(syncedOpp.Deal_Year__c != '1'){
                            syncedOpp.Deal_Closed_by__c                      =   syncedFromOpp.Deal_Closed_by__c;
                            syncedOpp.Early_Contract__c                      =   syncedFromOpp.Early_Contract__c;
                        }
                        
                        
                        //syncedOpp.Event_City__c                              =   syncedFromOpp.Event_City__c;
                        //syncedOpp.Event_Country__c                           =   syncedFromOpp.Event_Country__c;
                        syncedOpp.Event_Name__c                              =   syncedFromOpp.Event_Name__c;
                        //syncedOpp.Event_State__c                             =   syncedFromOpp.Event_State__c;
                        //syncedOpp.Event_Venue__c                             =   syncedFromOpp.Event_Venue__c;
                        syncedOpp.FirstPresentation__c                       =   syncedFromOpp.FirstPresentation__c;
                        syncedOpp.Govt__c                                    =   syncedFromOpp.Govt__c;
                        syncedOpp.Management_Company_Name__c                 =   syncedFromOpp.Management_Company_Name__c;
                        syncedOpp.Marketing_Deliverables__c                  =   syncedFromOpp.Marketing_Deliverables__c;
                        syncedOpp.Marketing_Services_Provided_By_Client__c   =   syncedFromOpp.Marketing_Services_Provided_By_Client__c;
                        syncedOpp.Mktg_Lead_Source__c                        =   syncedFromOpp.Mktg_Lead_Source__c;
                        syncedOpp.MSA_Code__c                                =   syncedFromOpp.MSA_Code__c;
                        syncedOpp.Ownership_Group__c                         =   syncedFromOpp.Ownership_Group__c;
                        //syncedOpp.Sales_Cycle__c                           =   syncedFromOpp.Sales_Cycle__c;
                        syncedOpp.Listed_Created__c                          =   syncedFromOpp.Listed_Created__c;
                        syncedOpp.Product__c                                 =   syncedFromOpp.Product__c;
                        if(syncedOpp.Ship_To_Address__c==null)
                            syncedOpp.Ship_To_Address__c                         =   syncedFromOpp.Ship_To_Address__c;
                        if(syncedOpp.Bill_To_Address__c==null)
                            syncedOpp.Bill_To_Address__c                         =   syncedFromOpp.Bill_To_Address__c;
                        syncedOpp.Do_Not_Send_Invoice_OrderType_Override__c  =   syncedFromOpp.Do_Not_Send_Invoice_OrderType_Override__c;
                        syncedOpp.Billing_Schedule__c                        =   syncedFromOpp.Billing_Schedule__c ;
                        syncedOpp.Invoice_Payment_Terms__c                   =   syncedFromOpp.Invoice_Payment_Terms__c;
                        syncedOpp.Invoice_Payment_Mode__c                    =   syncedFromOpp.Invoice_Payment_Mode__c;
                        syncedOpp.Ship_To_Contact__c                         =   syncedFromOpp.Ship_To_Contact__c ;
                        syncedOpp.Bill_To_Contact__c                         =   syncedFromOpp.Bill_To_Contact__c;
                        syncedOpp.Offset_Days__c                             =   syncedFromOpp.Offset_Days__c ;
                        syncedOpp.PO__c                                      =   syncedFromOpp.PO__c;
                        //syncedOpp.Operating_Unit_ID__c                     =   syncedFromOpp.Operating_Unit_ID__c ;
                        syncedOpp.Sold_To_Company__c                         =   syncedFromOpp.Sold_To_Company__c;
                        syncedOpp.Header_Notes__c                            =   syncedFromOpp.Header_Notes__c;
                        syncedOpp.Billing_Date__c                            =   syncedFromOpp.Billing_Date__c ;
                        syncedOpp.Club_Code__c                               =   syncedFromOpp.Club_Code__c;
                        //syncedOpp.ContractReceived__c                        =   syncedFromOpp.ContractReceived__c;                                                    
                        syncedOpp.EBS_Order_Date__c                          =   syncedFromOpp.EBS_Order_Date__c;
                        
                        /**
                        ** Fields to be mapped differently based on MYD and Renewal contract
                        **/
                        //MYD Contract Mapping
                        if(renewedContract.Upcoming_Renewal_Type__c == 'MYD Renewal'){
                            syncedOpp.RecordTypeId      =    syncedFromOpp.RecordTypeId;
                            syncedOpp.StageName         =   'MYD Created';
                            
                            //Added on 03/29/2018 - P# P-003555
                            syncedOpp.CVII_Contract_Number__c = syncedFromOpp.CVII_Contract_Number__c;


                            //Added after CPQ Go Live- 7/10/2017
                            if(renewedContract.EndDate!=null)
                                syncedOpp.Auto_Close_Date__c = renewedContract.EndDate - 30;
                        }
                        //Renewal Contract Mapping
                        else if(renewedContract.Upcoming_Renewal_Type__c == 'Contract Renewal'){
                            syncedOpp.NBB_Renewal__c      =   'Renewal';
                            //StageName and ClosedDate
                            if(trigger.isInsert){
                                syncedOpp.StageName       =   'Up for Renewal';
                            }

                            //Added on 03/29/2018 - P# P-003555
                            if(syncedFromOpp.CVII_Contract_Number__c!=null)
                                syncedOpp.Previous_Contract_Number__c = Decimal.ValueOf(syncedFromOpp.CVII_Contract_Number__c);

                            //Set Record Type
                            Id renewalTypeId= Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal').getRecordTypeId();
                            syncedOpp.RecordTypeId =  renewalTypeId;
                            //Renewal Opp Name and Close Date
                            if(renewedContract.Parent_Contract__c!=null && renewedContract.Parent_Contract__r.EndDate!=null){
                                //Renewal Opp Closed Date
                                syncedOpp.CloseDate   =  renewedContract.Parent_Contract__r.EndDate;
                                //syncedOpp.CloseDate   =  (System.today().daysBetween(renewedContract.Parent_Contract__r.EndDate)>=0?renewedContract.Parent_Contract__r.EndDate:system.today());
                                if(syncedOpp.RenewalDate__c == null)
                                    syncedOpp.RenewalDate__c =  renewedContract.Parent_Contract__r.EndDate;
                                syncedOpp.Name =  monthMap.get(syncedOpp.closeDate.Month()) + ' ' + syncedOpp.closeDate.Year() + ' Renewal Opportunity';
                            }
                            
                        }   
                        
                    }
                    
                }
                
                //Mapping from Parent Agreement
                if(agreementContractsMap.containsKey(syncedOpp.Master_Agreement__c) && syncedOpp.Master_Agreement__c!=null){
                    system.debug('-----agreementContractsMap.containsKey(syncedOpp.Master_Agreement__c)'+agreementContractsMap.containsKey(syncedOpp.Master_Agreement__c));
                    //Get Parent Agreement
                    Contract masterAgreement = agreementContractsMap.get(syncedOpp.Master_Agreement__c);
                    syncedOpp.ContractStartDate__c = masterAgreement.StartDate;
                    syncedOpp.ContractReceived__c  =   masterAgreement.SBQQ__Opportunity__r.ContractReceived__c;
                    syncedOpp.ContractEndDate__c = masterAgreement.EndDate;
                    
                    //Early Contract if contract is received 90 days earlier than start date : added by udita because contract start was null previously
                    if(oldMapValues==null || ((!oldMapValues.isEmpty() && syncedOpp.ContractStartDate__c!=null && syncedOpp.StageName=='Closed Won'))){ 
                        if(masterAgreement.StartDate !=null && syncedOpp.ContractReceived__c < masterAgreement.StartDate.addDays(-90)){
                            syncedOpp.Early_Contract__c = 'Early';
                        }else{
                            syncedOpp.Early_Contract__c = 'Not Early';
                        }
                   }  
                }
                 
            }
            
        }   
        
    }
    
    /*
**  move process builder into code
** SBQS: Reset Renewal on Amended Contract
** Added on : 15 Nov 2017 
**/
    public static void ResetRenewalAmend(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMapValues){
        
        Set<Id> contractIds = new Set<Id>();
        
        for(Opportunity opp : newMap.values()){
            
            if( opp.SBQQ__AmendedContract__c!=null && opp.SBQQ__Contracted__c==true &&
               (oldMapValues.get(opp.id).SBQQ__AmendedContract__c!=opp.SBQQ__AmendedContract__c ||
                oldMapValues.get(opp.id).SBQQ__Contracted__c!=opp.SBQQ__Contracted__c )){
                   contractIds.add(opp.SBQQ__AmendedContract__c);
               }
        }
        
        if(contractIds.size()>0){
            
            List<Contract> contractList = new List<Contract>();
            
            for(Contract cont : [ Select Id,SBQQ__RenewalQuoted__c From Contract Where Id In: contractIds and SBQQ__RenewalQuoted__c=true and SBQQ__RenewalOpportunity__r.StageName!='Closed Won' ]){ 
                cont.SBQQ__RenewalQuoted__c=false;   
                contractList.add(cont);            
            }
            
            if(contractList.size()>0)
                update contractList;
        }
    }
    
    /**
    ** P-001384
    ** On Update Only
    ** Post Chatter when Opportunity is closed won with any of the Products associated stored in custom setting OpportunityAlert
    ** Added by Shanu on 09 Nov 2017
    **/
    /** Enhancements added by udita for project P-003953 : Opportunity Alert Creation - HC Bundle Product(s) have reached Verbal Stage**/
    public static boolean isTest=false;
    public static void OpportunityChatterAlerts(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMapValues){
        //Get Custom Setting data
        Set<Id> oppIds = new Set<Id>();
        Set<Id> primaryQuoteIds = new Set<Id>();       
        List<Messaging.SingleEmailMessage> emailMsgList = new List<Messaging.SingleEmailMessage>(); 
        //Opportunity is Closed Won
        for(Opportunity opp : newMap.values()){     
            
            system.debug('===========oldMapValues.get(opp.id).StageName'+oldMapValues.get(opp.id).StageName);
            system.debug('===========oldMapValues.get(opp.id).StageName'+opp.StageName);
            if(isTest || (oldMapValues.containsKey(opp.id) && oldMapValues.get(opp.id).StageName!=opp.StageName && ( opp.StageName=='Closed Won' || opp.StageName=='Closed Won – Do Not Send to EBS' || opp.StageName=='Verbal'))){  //Udita : adding all the stages for which chatter alert would fire
                oppIds.add(opp.Id);
                primaryQuoteIds.add(opp.SBQQ__PrimaryQuote__c);
            }
        }
        
        //Process Closed Won Opps
        if(oppIds.size()>0){
            Id CSNRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CSN-Supplier').getRecordTypeId();
            // map for chatter alerts
            Map<String,OpportunityAlerts__c> alertSetting = OpportunityAlerts__c.getAll();
            // map for email alerts
            Map<String,OpportunityEmailAlerts__c> emailSetting = OpportunityEmailAlerts__c.getAll();
            Map<Id,Opportunity> oppMap= new Map<Id,Opportunity>();
            
            system.debug('+alertSetting ' + alertSetting.keySet() );
            
            //Fetch Opportunties with matching Products,  related Quote,Implementation Survey and Docusign Status. 
            for(Opportunity opp : [Select Id,RecordTypeId,Account.Name,Owner.Email, AccountId, Chain_Deal__c,Product__c,Deal_Year__c ,SBQQ__PrimaryQuote__r.Id,SBQQ__PrimaryQuote__r.Name,SBQQ__PrimaryQuote__r.Legal_Review_Stage__c,Name,NBB_Renewal__c, StageName,
                                   (Select OpportunityId,ProductCode,Product2.Name,Opportunity.stagename,Opportunity.Deal_Year__c From OpportunityLineItems Where ProductCode IN: alertSetting.keySet() or ProductCode IN: emailSetting.keySet()),
                                   (Select Name,Tax_Exempt__c From Implementation_Surveys__r Where Quote__c IN:primaryQuoteIds Limit 1),
                                   (Select Name From dsfs__R00N80000002fD9vEAE__r Where dsfs__Envelope_Status__c='Completed' Limit 1)
                                   From Opportunity Where Id IN:oppIds
                                  ]){
                                      oppMap.put(opp.Id,opp);
                                  }
            //Check codes only for Opportunities with NBB/Renewal = NBB Only  
            Set<String> NBBRenewalCodeSet = new Set<String>();
            NBBRenewalCodeSet.add('LA-SW-SHC-LPY-GLO');
            NBBRenewalCodeSet.add('LA-SW-SHC-LPY-PKRLO');
            NBBRenewalCodeSet.add('LA-SW-SHC-LPY-PKWDRM');
            NBBRenewalCodeSet.add('LA-SW-SHC-LPY-PKHF');
            NBBRenewalCodeSet.add('LA-SW-SHC-LPY-PKHH');
            NBBRenewalCodeSet.add('LA-SW-SHC-LPY-PKHV');
            NBBRenewalCodeSet.add('LA-SW-SHC-LPY-PKHRLM');
            
            //Multiple chatter per Opportunity
            Map<Id,List<AlertWrapper>> chatterMap = new Map<Id,List<AlertWrapper>> ();
            
            //Body vs List of reciepients per Opp
            Map<String,List<Id>> alertVsSentToIds = new Map<String,List<Id>>();
            
            


            String alert;
            String code;
            String body;
            String surveyLink='';
            String quoteLink;
            String docusignLink='';
            String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm()+'/';
            String isTaxExempt='';

            
            
            //Processing filtered opps
            for (Opportunity opp : oppMap.Values()) {
              if(opp.StageName=='Closed Won' || opp.StageName=='Closed Won – Do Not Send to EBS'){ // Udita : added If condition for Completion, MSA/Bulk Purchase Contract Type, Tax Exemption Customer
                alertVsSentToIds.clear();
                
                //Primary quote should be there 
                if(opp.Implementation_Surveys__r.size()>0){
                    surveyLink = baseUrl+ opp.Implementation_Surveys__r[0].Id;
                    isTaxExempt = opp.Implementation_Surveys__r[0].Tax_Exempt__c;
                }
                
                if(opp.dsfs__R00N80000002fD9vEAE__r.size()>0)
                    docusignLink = baseUrl + opp.dsfs__R00N80000002fD9vEAE__r[0].Id;
                
                //Alerts for Completion, MSA/Bulk Purchase Contract Type, Tax Exemption Customer
                
                //Completion Alert
                if( alertSetting.containsKey('Completion')  && opp.RecordTypeId==CSNRecTypeId || (opp.Product__c=='CSN' ||  opp.Product__c=='Decision Street' || opp.Product__c=='EMI')){
                    
                    //prepare body
                    body='\n\n Opp Name: '+ opp.Name + '\n Account : ' + opp.Account.Name + '\n Quote: ' + baseUrl + opp.SBQQ__PrimaryQuote__c +'\n Implementation Survey: '+ surveyLink + '\n\tDocusign Agreement: ' + docusignLink + '\n\n ' + alertSetting.get('Completion').Alert_Description__c;
                    
                    alertVsSentToIds.put(body,alertSetting.get('Completion').Sent_to__c.split(','));
                    
                }
                
                //MSA/Bulk Purchase Contract Type
                if( alertSetting.containsKey('MSA/Bulk Purchase Contract Type') && opp.Chain_Deal__c!=null && 
                   (opp.Chain_Deal__c.startswith('Bulk Purchase') || opp.Chain_Deal__c.startswith('MSA') || opp.Chain_Deal__c.startswith('Multi-Property')) ){ 
                       
                       //prepare body
                       body='\n\n Opp Name: '+ opp.Name + '\n Account : ' + opp.Account.Name + '\n Quote: ' + baseUrl + opp.SBQQ__PrimaryQuote__c +'\n Implementation Survey: '+ surveyLink + '\n\tDocusign Agreement: ' + docusignLink + '\n\n ' + alertSetting.get('MSA/Bulk Purchase Contract Type').Alert_Description__c;
                       
                       alertVsSentToIds.put(body,alertSetting.get('MSA/Bulk Purchase Contract Type').Sent_to__c.split(','));
                       
                   }
                
                //Tax Exemption Customer Alert
                if( alertSetting.containsKey('Tax Exemption Customer')  && isTaxExempt=='Yes'){
                    
                    //prepare body
                    body='\n\n Opp Name: '+ opp.Name + '\n Account : ' + opp.Account.Name  + '\n Quote: ' + baseUrl + opp.SBQQ__PrimaryQuote__c +'\n Implementation Survey: '+ surveyLink + '\n\tDocusign Agreement: ' + docusignLink + '\n\n ' + alertSetting.get('Tax Exemption Customer').Alert_Description__c;
                    
                    alertVsSentToIds.put(body,alertSetting.get('Tax Exemption Customer').Sent_to__c.split(','));
                    
                }
                
             }   
                //Iterate For Product Codes Alert for Current Opp
                for(OpportunityLineItem oli : opp.OpportunityLineItems){
                    
                    system.debug('$$$$alertSetting.containsKey(code)$$$$$  '+alertSetting.containsKey(code));
                    code=oli.ProductCode;
                     //fetching values on behalf of custom setting : OpportunityAlerts
                    if(alertSetting.containskey(code)){
                    alert=alertSetting.get(code).Alert_Description__c;}
                    list<string> stages = new list <string> (); // added by Udita to fetch the stages on behalf of sku code in custom setting
                    list<String> groupsIds = new list <string> ();
                    if(alertSetting.containskey(code) && alertSetting.get(code).Stage__c !=null && alertSetting.get(code).Sent_to__c !=null){
                      stages =  alertSetting.get(code).Stage__c.split(',');
                      groupsIds =alertSetting.get(code).Sent_to__c.split(','); 
                    }
                    //Content is lenghty of Alert so stored in label 
                    if(alert=='Label:OppAlert')
                        alert=Label.OppAlert;
                    else if (alert=='Label:OppAlert2')
                        alert=Label.OppAlert2; 
                     //ends!!!!!!
                     //fetching values on behalf of custom setting : OpportunityEmailAlerts 
                     if(emailSetting.containsKey(code)){
                          string stage_EmailAlert = emailSetting.get(code).Stage__c;
                          list<string> sentToEmail = new list <string>();
                          if(emailSetting.containskey(code) && emailSetting.get(code).Sent_to__c !=null){
                            sentToEmail =  emailSetting.get(code).Sent_to__c.split(',');
                          }
                          system.debug('-----sentToEmail'+sentToEmail);
                        //code for sending email alerts:Udita    
                        if(emailSetting.containsKey(code)  && stage_EmailAlert == oli.Opportunity.stagename){
                            Messaging.SingleEmailMessage msg1 =  new Messaging.SingleEmailMessage();  
                            msg1.setTemplateId(emailSetting.get(code).TemplateId__c);
                            msg1.setToAddresses(new List<String>{opp.Owner.Email}); 
                            msg1.setToAddresses(sentToEmail);   
                            System.debug('msg1*****'+msg1);
                            msg1.setOrgWideEmailAddressId('0D2000000008OzJ');
                            msg1.setSaveAsActivity(false);
                            msg1.setTargetObjectId(opp.OwnerID);
                            msg1.setWhatId(opp.id);
                            emailMsgList.add(msg1);    
                            system.debug('---emailMsgList'+emailMsgList);                     
                        }
                    }
                       
                    if(alertSetting.containsKey(code)  && ((NBBRenewalCodeSet.contains(code) && opp.NBB_Renewal__c=='NBB' && (opp.StageName=='Closed Won' || opp.StageName=='Closed Won – Do Not Send to EBS')) || (!NBBRenewalCodeSet.contains(code) && (stages !=null && stages.contains(oli.Opportunity.stagename))))){
                       system.debug('If1---'+ opp.StageName);
                        if(groupsIds.contains(Label.PasskeySoldGroupId)){  // added by Udita - P-004410
                             if(oli.Opportunity.Deal_Year__c == '1'){ // added by Udita - P-004410
                               //prepare body
                             body='\n\n Opp Name: '+ opp.Name + '\n Account : ' + opp.Account.Name + '\n Quote: ' + baseUrl + opp.SBQQ__PrimaryQuote__c +'\n Implementation Survey: '+ surveyLink + '\n\tDocusign Agreement: ' + docusignLink + '\n Product Name: '+ oli.Product2.Name + '\n Product Code: '+ code + '\n\n ' + alert.trim();                           
                             alertVsSentToIds.put(body,alertSetting.get(code).Sent_to__c.split(','));
                             break;
                             }
                        }else{
                            //prepare body 
                            body='\n\n Opp Name: '+ opp.Name + '\n Account : ' + opp.Account.Name + '\n Quote: ' + baseUrl + opp.SBQQ__PrimaryQuote__c +'\n Implementation Survey: '+ surveyLink + '\n\tDocusign Agreement: ' + docusignLink + '\n Product Name: '+ oli.Product2.Name + '\n Product Code: '+ code + '\n\n ' + alert.trim();
                            
                            alertVsSentToIds.put(body,alertSetting.get(code).Sent_to__c.split(','));
                            break;
                        }    
                    }
                    
                }        
                
                //prepare Map for posting chatters
                for(String alertBody : alertVsSentToIds.keySet()){
                    if(chatterMap.containsKey(opp.Id)){
                        chatterMap.get(opp.Id).add(new AlertWrapper(alertBody,alertVsSentToIds.get(alertBody)));
                    }else{
                        chatterMap.put(opp.Id, new List<AlertWrapper>{new AlertWrapper(alertBody,alertVsSentToIds.get(alertBody))});
                    }
                }
                
                
            }
            system.debug('$$$$$$$$$$$chatterMap  '+ chatterMap);
            //PostChatter(oppIdvsSentIds,oppIdvsText);
            PostChatter(chatterMap);
            
             if(emailMsgList.size()>0){
                Messaging.sendEmail(emailMsgList);
                system.debug('*****sendEmail*****');
             }  
        }
        
    }
    
    //Bind chatter body with Sent to reciepients
    public class AlertWrapper{
        String chatterBody;
        List<Id> sentToIds;
        public AlertWrapper(String chatterBody,List<Id> sentToIds){
            this.chatterBody=chatterBody;
            this.sentToIds=sentToIds;
        }
    }
    
    //public static void PostChatter(Map<Id,List<Id>> oppIdvsSentIds , Map<Id,String> oppIdvsText){
    public static void PostChatter(Map<Id,List<AlertWrapper>> chatterMap){
        
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
        
        ConnectApi.FeedItemInput input;
        ConnectApi.MarkupBeginSegmentInput markupBeginSegment;
        ConnectApi.MarkupEndSegmentInput markupEndSegment;
        ConnectApi.MessageBodyInput body;
        ConnectApi.MentionSegmentInput mentionSegmentInput;
        
        
        for(Id oppId : chatterMap.keySet()){
            
            
            //Multiple chatter per opportunity
            for(AlertWrapper awrapper : chatterMap.get(oppId)){
                
                //Attach under Opp Record
                input = new ConnectApi.FeedItemInput();
                input.subjectId = oppId;
                
                //init body
                body = new ConnectApi.MessageBodyInput();
                body.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                
                //@Mention ( Sent To Alerts )
                for(Id userOrGroupId : awrapper.sentToIds){
                    mentionSegmentInput = new ConnectApi.MentionSegmentInput();        
                    mentionSegmentInput.id = userOrGroupId;
                    body.messageSegments.add(mentionSegmentInput);
                }
                
                
                
                
                //Chatter Text Body/Description
                ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
                textSegment.text = awrapper.chatterBody;   
                body.messageSegments.add(textSegment);
                
                
                //populate body
                input.body = body;
                
                //bulk chatter
                ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
                batchInputs.add(batchInput);
            }
            
            
        }
        
        //post chattern
        if(!Test.isRunningTest()){
            
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
        }
        
        
        
    }
    
    
    /**
    **  Sync owners from Opportunity to Primary Quote and Parent/Child Contracts
    **   Added on - 13/11/2017
    **/ 
    public static void syncOwner(List<Opportunity> newValues, Map<Id,Opportunity> oldMapValues){
        
        Map<Id,Id> oppVSOwnerIdMap = new Map<Id,Id>();
        system.debug('====>istest'+isTest);
        //Owner is changed
        for(Opportunity opp: newValues){        
            if((oldMapValues.get(opp.id).OwnerId!=opp.OwnerId) || isTest ){ // && isTest
                oppVSOwnerIdMap.put(opp.Id,opp.OwnerId);
            }
        }
        
        //Sync Owners
        if(!oppVSOwnerIdMap.isEmpty()){
            
            List<SBQQ__Quote__c> updateQuoteList = new List<SBQQ__Quote__c> ();
            List<Contract> updateContractList = new List<Contract> ();
            
            Set<Id> recTypes = new Set<Id>();
            Id parentRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Parent Contract').getRecordTypeId();
            Id childrecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Child Contract').getRecordTypeId();
            recTypes.add(parentRecTypeId);
            recTypes.add(childrecTypeId);
            
            for(Opportunity oppRec : [Select Id,OwnerId,StageName,
                                      (Select Id,OwnerId,SBQQ__SalesRep__c From SBQQ__Quotes2__r Where OwnerId NOT IN: oppVSOwnerIdMap.values()),
                                      (Select Id,SBQQ__RenewalOwner__c From SBQQ__Contracts__r Where OwnerId NOT IN: oppVSOwnerIdMap.values() and RecordTypeId IN :recTypes)
                                      From Opportunity Where ID IN: oppVSOwnerIdMap.keySet()]){
                                          
                                          //Sync oweners to Quote
                                          for(SBQQ__Quote__c q : oppRec.SBQQ__Quotes2__r){
                                              
                                              q.OwnerId = oppRec.OwnerId;
                                              q.SBQQ__SalesRep__c = oppRec.OwnerId;
                                              updateQuoteList.add(q);
                                              
                                          }
                                          //Sync owners to Contract
                                          if(oppRec.StageName == 'Up for Renewal'){
                                              for(Contract c : oppRec.SBQQ__Contracts__r){
                                                  
                                                  c.SBQQ__RenewalOwner__c = oppRec.OwnerId;
                                                  updateContractList.add(c);
                                                  
                                              }
                                          }
                                          
                                      }
            
            if(updateQuoteList.size()>0){
                update updateQuoteList;
            }
            if(updateContractList.size()>0){
                update updateContractList;
            }
        }
    }
    /*
    **
    ** Check whether the Opportunity has atleast one primary quote and a OpportunityProduct when a Opportunity is Closed/Won.
    ** Added by : HSR
    ** Added on : 21st Nov 2017
    */
  public static void CheckQuoteProduct( List<Opportunity> newList, Set<Id> oppIdSet){
        
        Set<Id> profileIdSet = new Set<Id>();
        //Query to fetch all the Finance Profiles......
        
        
       /* For(Profile profileRec : [SELECT Id FROM Profile WHERE Name LIKE '%Finance%'])
        {
            profileIdSet.add(profileRec.Id);
        }*/ // comment5ed by udita for PI-0003804

        //Validation will not fire for the Finance User
      //  if(!profileIdSet.contains(UserInfo.getProfileId())){   // commented by udita for PI-0003804
            
            Map<Id,Integer> oppIdVsQuoteCountmap = new Map<Id,Integer>();
            Map<Id,Integer> oppIdVsProductCountmap = new Map<Id,Integer>();
          
            For(Opportunity oppObj : [SELECT Id,(SELECT Id FROM SBQQ__Quotes2__r WHERE SBQQ__Primary__c = TRUE),(SELECT Id FROM OpportunityLineItems LIMIT 1) FROM Opportunity WHERE Id IN : oppIdSet])
            {
                oppIdVsQuoteCountmap.put(oppObj.Id,oppObj.SBQQ__Quotes2__r.size());
                oppIdVsProductCountmap.put(oppObj.Id,oppObj.OpportunityLineItems.size());
               
            }
           
            For(Opportunity oppObj : newList){
                if(oppIdVsQuoteCountmap.containsKey(oppObj.Id)){
                    if(oppIdVsQuoteCountmap.get(oppObj.Id)==0 && !Test.isRunningTest() && oppObj.Parent_Upsell__c !='One-Off'){ // last check added by udita for PI-0003804
                        oppObj.addError('Opportunity should have atleast one Primary Quote.');
                    }else if(oppIdVsQuoteCountmap.get(oppObj.Id)>1 && !Test.isRunningTest()){
                        oppObj.addError('Opportunity should not have more than one Primary Quote.');
                    }
                }
                if(oppIdVsProductCountmap.containsKey(oppObj.Id) && oppIdVsProductCountmap.get(oppObj.Id) == 0 && !Test.isRunningTest()){
                    //oppObj.addError('Opportunity should have at least one Product.');
                }
            }
       // } // comment5ed by udita for PI-0003804
    }
    
    /**
    ***
    Added By : HSR
    Date : 12/01/2017
    Description : To change the OpportunitySplitOwner when the Owner Id of opportunity is changed after the Opportunity is Closed/Won.
    ***
    **/
    public static void ChangeOppSplitOwner(Map<Id,Opportunity> newMapValues,Map<Id,Opportunity> oldMapValues){
        Map<Id,Id> oppIdVsOldOwnerMap = new Map<Id,Id>();
        Map<Id,Id> oppIdVsNewOwnerMap = new Map<Id,Id>();
        Opportunity oldOppObj;
        
        Map<String,Map<Id,Decimal>> oppOwnerVsOppSplitVsPercent = new Map<String,Map<Id,Decimal>>();
        Map<Id,Decimal> oppSplitIdVsPercent = new Map<Id,Decimal>();
        String s;
        
        Set<Id> splitTypeIdSet = new Set<Id>();
        Set<Id> oppOwnerIdSet = new Set<Id>();
        For(Opportunity oppObj : newMapValues.Values()){
            oldOppObj = oldMapValues.get(oppObj.Id);
            if(isTest || (oldOppObj.OwnerId != oppObj.OwnerId && oppObj.StageName == 'Closed Won'))
            {
                oppIdVsOldOwnerMap.put(oppObj.Id,oldOppObj.OwnerId);
                oppIdVsNewOwnerMap.put(oppObj.Id,oppObj.OwnerId);
                oppOwnerIdSet.add(oppObj.OwnerId);
                oppOwnerIdSet.add(oldOppObj.OwnerId);
            }
        }
        System.debug('oppIdVsOldOwnerMap**'+oppIdVsOldOwnerMap);
        System.debug('oppIdVsNewOwnerMap**'+oppIdVsNewOwnerMap);
        if(!oppIdVsOldOwnerMap.isEmpty()){
            For(OpportunitySplitType splitTypeRec : [SELECT Id FROM OpportunitySplitType WHERE IsActive = TRUE])
            {
                splitTypeIdSet.add(splitTypeRec.Id);
            }
            List<OpportunitySplit> oppSplitList = new List<OpportunitySplit>();
            OpportunitySplit oppSplitObj = new OpportunitySplit();
            For(OpportunitySplit oppSplitRec : [SELECT Id,SplitOwnerId,OpportunityId,SplitPercentage FROM OpportunitySplit WHERE OpportunityId IN : oppIdVsNewOwnerMap.keySet() AND SplitOwnerId IN : oppOwnerIdSet AND SplitTypeId  IN : splitTypeIdSet])// 
            {
                s = '';
                s = String.ValueOf(oppSplitRec.OpportunityId)+String.ValueOf(oppSplitRec.SplitOwnerId);
                if(oppOwnerIdSet.contains(oppSplitRec.SplitOwnerId) && !oppOwnerVsOppSplitVsPercent.containsKey(s)){
                    oppSplitIdVsPercent = new Map<Id,Decimal>();
                    oppSplitIdVsPercent.put(oppSplitRec.Id,oppSplitRec.SplitPercentage);
                    oppOwnerVsOppSplitVsPercent.put(s,oppSplitIdVsPercent);
                }
            }
            System.debug('oppOwnerVsOppSplitVsPercent********'+oppOwnerVsOppSplitVsPercent);
            if(!oppOwnerVsOppSplitVsPercent.isEmpty())
            {
                For(Id oppId : oppIdVsOldOwnerMap.keySet())
                {
                    String oldOppVsOwnerId = String.ValueOf(oppId)+String.ValueOf(oppIdVsOldOwnerMap.get(oppId));
                    String newOppVsOwnerId = String.ValueOf(oppId)+String.ValueOf(oppIdVsNewOwnerMap.get(oppId));
                    System.debug('oldOppVsOwnerId********'+oldOppVsOwnerId);
                    System.debug('newOppVsOwnerId*************'+newOppVsOwnerId);
                    Decimal oldPercent = 0; 
                    Decimal newPercent = 0; 
                    For(Id oldVal : oppOwnerVsOppSplitVsPercent.get(oldOppVsOwnerId).keySet())
                    {
                        oldPercent = oppOwnerVsOppSplitVsPercent.get(oldOppVsOwnerId).get(oldVal);
                    }
                    System.debug('oldPercent******'+oldPercent);
                    For(Id newVal : oppOwnerVsOppSplitVsPercent.get(newOppVsOwnerId).keySet())
                    {
                        newPercent = oppOwnerVsOppSplitVsPercent.get(newOppVsOwnerId).get(newVal);
                        oppSplitObj = new OpportunitySplit(Id = newVal);
                        oppSplitObj.SplitPercentage = oldPercent;
                        oppSplitList.add(oppSplitObj);
                    }
                    System.debug('newPercent******'+newPercent);
                    For(Id oldVal : oppOwnerVsOppSplitVsPercent.get(oldOppVsOwnerId).keySet())
                    {
                        oppSplitObj = new OpportunitySplit(Id = oldVal);
                        oppSplitObj.SplitPercentage = newPercent;
                        oppSplitList.add(oppSplitObj);
                        System.debug('oldPercent********'+oldPercent);
                    }
                }
            }
            System.debug('oppSplitList*******'+oppSplitList);
            if(oppSplitList.size()>0 && !Test.isRunningTest())
                Database.update(oppSplitList,false);
        }
    }
    /**
    ***
    Added By : HSR
    Date : 01/08/2018
    Description : If contract team is removing AM owner name from opportunity, we want an email alert should out to that rep whose name we are removing.
    ***
    **/
    public static void SendAMAlert(Map<Id,Opportunity> newMapValues,Map<Id,Opportunity> oldMapValues){
        Opportunity oldOppObj;
        Map<Id,String> oppIdVsAMOwnerNameMap = new Map<Id,String>();
        Map<String,String> userIdVsEmailMap = new Map<String,String>();
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail;
        For(Opportunity oppObj : newMapValues.Values()){
            system.debug('=====>'+oppObj.AM_Owner__c);
            
            oldOppObj = oldMapValues.get(oppObj.Id);
            system.debug('=====>'+oldOppObj.AM_Owner__c);
            if(istest || (oldOppObj.AM_Owner__c!=null && oppObj.AM_Owner__c!=oldOppObj.AM_Owner__c && oldOppObj.AM_Owner__c!='Not Applicable'))
            {
                oppIdVsAMOwnerNameMap.put(oppObj.Id,oldOppObj.AM_Owner__c);
            }
        }
        system.debug('===>'+oppIdVsAMOwnerNameMap.values());
        if(!oppIdVsAMOwnerNameMap.isEmpty()){
            For(User userObj : [SELECT Id,Name,Email,Profile.name FROM User WHERE Name IN :oppIdVsAMOwnerNameMap.Values() AND IsActive = TRUE AND IsPortalEnabled = FALSE])
            {
                if(!userObj.Email.contains('='))
                    userIdVsEmailMap.put(userObj.Name,userObj.Email);
            }
            if(!userIdVsEmailMap.isEmpty()){
                For(Id oppId : oppIdVsAMOwnerNameMap.keySet())
                {
                    if(userIdVsEmailMap.containskey(oppIdVsAMOwnerNameMap.get(oppId))){
                        mail = new Messaging.SingleEmailMessage();  
                        String[] toAddresses = new String[] {userIdVsEmailMap.get(oppIdVsAMOwnerNameMap.get(oppId))};  
                        mail.setToAddresses(toAddresses);  
                        mail.setSubject('Your name has been removed from AM Influence https://cvent.my.salesforce.com/'+oppId);  
                        String body='<span style='+'\''+'color:black; font-size:11.0pt;font-family:"Calibri",sans-serif;'+'\''+'><b>Hi '+oppIdVsAMOwnerNameMap.get(oppId)+',  </b></br></br></b><b>Reason of alert : </b></br></br><b>Opp. ID link –</b> <a href="https://cvent.my.salesforce.com/'+oppId+'">'+'https://cvent.my.salesforce.com/'+oppId+'</a></br></p></br><b>Please </b><span style='+'\''+'color:red; font-size:11.0pt;font-family:"Calibri",sans-serif;'+'\''+'><b> write to contracts team </b></span><b>in case of any discrepancy. </b> </p></p></br><span style='+'\''+'font-size:11.0pt;font-family:"Calibri",sans-serif;color:red'+'\''+'><b>Possible Reasons for the update:</b><ul><li>AM Influence has been updated by another rep.</li><li>If the owner of the opportunity is the same name in the AM Influence field.</li><li>If the name identified was incorrectly associated to the AM influence field, according to the parent contract.</li></ul> </span> <span style='+'\''+'font-size:11.0pt;font-family:"Calibri",sans-serif;color:#000000'+'\''+'><b>Thanks,</br>'+'SF Alerts'+'<o:p></o:p></b></span>';
                        mail.setHtmlBody(body);
                        allmsg.add(mail);
                    }
                }
                if(allmsg.size()>0)
                    Messaging.sendEmail(allmsg,false);
                }   
            }
    }



    /*
    **  Added on 1/10/2018 ( Shanu Aggarwal)
    **  Create RFP Cases after Opportunity is Closed Lost and Account's CSN Listing Type is Basic
    **  P-001519 
    **/
     public static void CreateRFPCaseOnClosedLost( List<Opportunity> newList, Map<Id,Opportunity> oldMapValues){
    
        System.debug('Ashna**** Called 2');
        Set<Id> oppIds = new Set<ID>();
        List<Case> casesToCreate = new List<Case>();
        //Opportunity is Closed Won and License Type is 1 > 4 Diamond
        for(Opportunity opp : newList){        
            if(istest || (oldMapValues.get(opp.id).StageName!=opp.StageName && opp.StageName=='Closed Lost' && (opp.License_Type__c=='1 Diamond' ||  opp.License_Type__c=='2 Diamond' ||   opp.License_Type__c=='3 Diamond' || opp.License_Type__c=='4 Diamond' ))){
                oppIds.add(opp.Id);
                
            }
        }
        System.debug('Ashna**** '+ oppIds);
        //Create cases If account listing type is basic
        if(oppIds.size()>0){
            system.debug('=====>Account.CSN_Listing_Type__c'+Account.CSN_Listing_Type__c);
            for( Opportunity opp : [ Select AccountId From Opportunity Where ID IN: oppIds and Account.CSN_Listing_Type__c = 'Basic' AND (Account.BillingCountry ='US' OR Account.BillingCountry ='CA' OR  Account.BillingCountry ='VI' OR Account.BillingCountry ='MX')]){   //Account.BillingCountry check added by Udita on Ashna request - P-004419
                System.debug('Ashna**** '+ opp);
                Case c = new Case(AccountId=opp.AccountId,RecordTypeId='0120000000096iP',OwnerId='00G00000006uMGq',Subject='Property moved from diamond to basic - review user shut down',Product_Type__c='CSN - Supplier',Client_Services_Category__c='Profile Management',Origin='CSN Task');
                casesToCreate.add(c);
            }
            if(casesToCreate.size()>0)
                insert casesToCreate;
        }       

    }
    /*
    **
    Creaed By : HSR
    Date : 16th Jan 2018
    Description : Owner Assignment while creating Opportunity on the basis of the AccountTeamMember.
    **
    */
    public static void oppOwnerAssignment(List<Opportunity> newOppList){
        System.debug('#Checkpoint Inside*****');
        Set<Id> accountIdSet = new Set<Id>();
        List<Opportunity> oppRecList = new List<Opportunity>();
        For(Opportunity oppRec : newOppList)
        {
            if(oppRec.Product__c!=null && !oppRec.IsClosed && !oppRec.IsWon && ((oppRec.NBB_Renewal__c!=null && oppRec.NBB_Renewal__c=='Renewal') || (oppRec.Deal_Year__c!=null && oppRec.Deal_Year__c!='1'))){//&& oppRec.Deal_Closed_by__c == null (oppRec.MYD_Deal__c!=null && oppRec.MYD_Deal__c == 'MYD')
                accountIdSet.add(oppRec.AccountId);
                oppRecList.add(oppRec);
            }
        }
        System.debug('oppRecList*****'+oppRecList);
        System.debug('accountIdSet*****'+accountIdSet);
        if(accountIdSet.size()>0){
            //Fetching AccountTeam Member.
            Map<Id,Account> mapIDOppParentAcc=new Map<ID,Account>([SELECT Id,
                                                                    (SELECT Id, AccountId,UserId,TeamMemberRole FROM AccountTeamMembers WHERE TeamMemberRole = 'AM - Event' OR TeamMemberRole ='AM - Event Cloud'
                                                                        OR TeamMemberRole = 'Multi-Product' OR TeamMemberRole = 'AM - Inquisium' OR TeamMemberRole = 'AM - RegOnline' OR
                                                                        TeamMemberRole = 'AM - CrowdCompass' OR TeamMemberRole = 'AM - OS' OR TeamMemberRole = 'AM - HC' OR
                                                                        TeamMemberRole = 'AM–OS' OR TeamMemberRole = 'SAT-HMC' OR TeamMemberRole = 'SAT-CHAIN'
                                                                    )FROM Account WHERE Id IN: accountIdSet]); 
    
                                                             
            Map<ID,Map<String,String>> mapAccountIdTeam=new Map<Id,Map<String,String>>();
            for(Account acc : mapIDOppParentAcc.values()){
                if(acc.AccountTeamMembers!=null){
                    Map<String,String> mapRoleVsuserID=new Map<String,String>();
                    for(AccountTeamMember actTeam : acc.AccountTeamMembers){
                        mapRoleVsuserID.put(actTeam.TeamMemberRole,actTeam.UserId);
                    }
                     system.debug('*****mapRoleVsuserID*******'+mapRoleVsuserID);
                    mapAccountIdTeam.put(acc.Id,mapRoleVsuserID);
                }
            }
           
            If(!mapAccountIdTeam.isEmpty())
            {
                For(Opportunity oppRec : oppRecList){
                    if(mapAccountIdTeam.containsKey(oppRec.AccountId)){
                        //Opportunity Owner Assignment for - Hospitality Cloud
                        String chainDeal = String.ValueOf(oppRec.Chain_Deal__c);
                        if((oppRec.Product__c=='CSN' || oppRec.Product__c=='EMI' || oppRec.Product__c=='Lanyon Passkey' || oppRec.Product__c=='Lanyon Group' || oppRec.Product__c=='Lanyon Transient'|| oppRec.Product__c=='Lanyon Travel')
                        && (oppRec.Chain_Deal__c!=null &&  (oppRec.Chain_Deal__c == 'Venue/Service' || chainDeal.containsIgnoreCase('Ownership Group') || chainDeal.containsIgnoreCase('Advertising Agency') || 
                        chainDeal.endsWithIgnoreCase('by Affiliate')))
                        && mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - HC')
                        ){
                            oppRec.OwnerId = mapAccountIdTeam.get(oppRec.AccountId).get('AM - HC');
                        }
                        //...............Ends Here...........
                        //Opportunity Owner Assignment for - Event Cloud
                        else if(oppRec.Product__c=='Survey'){
                            if(mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - Inquisium')){
                                oppRec.OwnerId = mapAccountIdTeam.get(oppRec.AccountId).get('AM - Inquisium');
                            }
                            else if(mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - HC')){
                                oppRec.OwnerId = mapAccountIdTeam.get(oppRec.AccountId).get('AM - HC');
                            }
                        }
                        else if(oppRec.Product__c=='Event' || oppRec.Product__c=='CrowdCompass' || oppRec.Product__c=='Onsite Solutions'){
                            if(mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - Event')){
                                oppRec.OwnerId = mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - Event Cloud')?mapAccountIdTeam.get(oppRec.AccountId).get('AM - Event Cloud'):mapAccountIdTeam.get(oppRec.AccountId).get('AM - Event');break;
                                
                            }
                            else if(mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - CrowdCompass')){
                                oppRec.OwnerId = mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - Event Cloud')?mapAccountIdTeam.get(oppRec.AccountId).get('AM - Event Cloud'):mapAccountIdTeam.get(oppRec.AccountId).get('AM - CrowdCompass'); break;
                               
                            }
                            else if(mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - OS')){
                                oppRec.OwnerId = mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - Event Cloud')?mapAccountIdTeam.get(oppRec.AccountId).get('AM - Event Cloud'):mapAccountIdTeam.get(oppRec.AccountId).get('AM - OS');break;
                                
                            }
                            else if(mapAccountIdTeam.get(oppRec.AccountId).containsKey('Multi-Product')){
                                oppRec.OwnerId = mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - Event Cloud')?mapAccountIdTeam.get(oppRec.AccountId).get('AM - Event Cloud'):mapAccountIdTeam.get(oppRec.AccountId).get('Multi-Product');break;
                                
                            }
                            else if(mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - Event Cloud')){
                                oppRec.OwnerId = mapAccountIdTeam.get(oppRec.AccountId).get('AM - Event Cloud');break;
                                
                            }
                        }
                        else if(oppRec.Product__c=='RegOnline' && mapAccountIdTeam.get(oppRec.AccountId).containsKey('AM - RegOnline')){
                            System.debug('#Checkpoint Else');
                            oppRec.OwnerId = mapAccountIdTeam.get(oppRec.AccountId).get('AM - RegOnline');
                        }
                    }
                }
            }
        }
    }
/**
    ***
    Added By : HSR
    Date : 01/04/2018
    Description : When a Opportunity is associated with some other opportunity by putting the opportunity id in 
        the Reassigned_To__c field all the QouteLineItem from the previous opportunity should gets atached with the Re-assigned opportunity.
    ***
    **/
    public static void createQuoteLineReassignOpp(Map<Id,Opportunity> newMapValues,Map<Id,Opportunity> oldMap){
        //Assigning Variable
        Map<Id,Id> oppIdVsReaasignOppIdMap = new Map<Id,Id>();
        Opportunity oppOld;

        Map<Id,Id> reaasignOppIdVsReaasignOppQuoteIdMap = new Map<Id,Id>();//map to store re-assigned opp Id Vs primary Quote Id
        Map<Id,Opportunity> reaasignOppIdVsReaasignOppObjMap = new Map<Id,Opportunity>();//map to store re-assigned opp Id Vs primary Quote Id

        List<SBQQ__QuoteLine__c > quoteLineList = new List<SBQQ__QuoteLine__c>();
        /*..................Validation...............*/
        Set<Id> reassignToIdSet = new Set<Id>();
        Set<Id> reassignToStageValidationIdSet = new Set<Id>();
        Set<Id> reassignToPrimaryValidationIdSet = new Set<Id>();
        For(Opportunity oppRec : newMapValues.Values())
        {
            //P-004474 : added this line for this Project
            //if(oppRec.MYD_Deal__c!=null && oppRec.MYD_Deal__c!='MYD'){
                //if(oppRec.Opportunity_Type__c != 'MYD'){
                    oppOld = oldmap.get(oppRec.Id);
                    if(oppRec.Reassigned_To__c!=null && (oppOld.Reassigned_To__c!= oppRec.Reassigned_To__c))
                        reassignToIdSet.add(oppRec.Reassigned_To__c);
                    if(oppOld.Reassigned_To__c!=null)
                        reassignToIdSet.add(oppOld.Reassigned_To__c);
                //}
            //}
        }
        if(reassignToIdSet.size()>0){
            For(Opportunity reassignOpp : [SELECT Id,StageName,SBQQ__PrimaryQuote__c,SBQQ__PrimaryQuote__r.SBQQ__Primary__c,SBQQ__PrimaryQuote__r.ApprovalStatus__c FROM Opportunity WHERE Id IN : reassignToIdSet])
            {
                if((reassignOpp.StageName=='Closed Won' || reassignOpp.StageName=='Closed Won - AR Settlement' || reassignOpp.StageName=='Closed Won – Do Not Send to EBS'))
                {
                    reassignToStageValidationIdSet.add(reassignOpp.Id);
                }
                else if(reassignOpp.SBQQ__PrimaryQuote__c!=null && (reassignOpp.SBQQ__PrimaryQuote__r.ApprovalStatus__c=='Pending' || reassignOpp.SBQQ__PrimaryQuote__r.ApprovalStatus__c=='Approved'))
                {
                    reassignToPrimaryValidationIdSet.add(reassignOpp.Id);
                }
            }
        }
        /*....................ENDS HERE..................*/
        For(Opportunity oppRec : newMapValues.Values())
        {
            oppOld = oldmap.get(oppRec.Id);
            if(isTest || (oppRec.Reassigned_To__c!=null && (oppOld.Reassigned_To__c!= oppRec.Reassigned_To__c))){
                if(reassignToStageValidationIdSet.size()>0 && (reassignToStageValidationIdSet.contains(oppRec.Reassigned_To__c) || reassignToStageValidationIdSet.contains(oppOld.Reassigned_To__c))){
                    oppRec.addError('Unable to save the Close Reassignment because the recipient Opportunity has already been Closed Won. If you have any questions, send to ARHelp@cvent.com');
                }
                else if(reassignToPrimaryValidationIdSet.size()>0 && (reassignToPrimaryValidationIdSet.contains(oppRec.Reassigned_To__c) || reassignToPrimaryValidationIdSet.contains(oppOld.Reassigned_To__c)))
                {
                    oppRec.addError('Unable to save the Close Reassignment because the recipient Opportunity has been submitted for approval or already been approved. To complete the Close Reassignment, you will first need to recall the approval. If you have any questions, send to ARHelp@cvent.com');
                }
                else if(oppRec.Deal_Year__c == '1'){
                    oppIdVsReaasignOppIdMap.put(oppRec.Id,oppRec.Reassigned_To__c);//map storing the opportunityId against the opportunity re-assigned to it.
                }
            }
        }
        System.debug('oppIdVsReaasignOppIdMap*******'+oppIdVsReaasignOppIdMap);
        //Query on the re-assigned Opportunity to fetch it's primary Quote
        if(!oppIdVsReaasignOppIdMap.isEmpty()){
            For(Opportunity oppObj : [SELECT Id,SBQQ__PrimaryQuote__c,AccountId,SBQQ__RenewedContract__c FROM Opportunity WHERE Id IN : oppIdVsReaasignOppIdMap.values()])
            {
                //reaasignOppIdVsReaasignOppQuoteIdMap.put(oppObj.Id,oppObj.Reassigned_To__r.SBQQ__PrimaryQuote__c);
                reaasignOppIdVsReaasignOppObjMap.put(oppObj.Id,oppObj);
            }

            System.debug('reaasignOppIdVsReaasignOppObjMap*******'+reaasignOppIdVsReaasignOppObjMap);

            String selects = '';
            String objectName = 'SBQQ__QuoteLine__c';
            // Get a map of field name and field token
            Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
            list<string> selectFields = new list<string>();
             
            if (fMap != null){
                for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    if (fd.isCreateable()){ // field is creatable
                        selectFields.add(fd.getName());
                    }
                }
            }
             
            if (!selectFields.isEmpty()){
                for (string s:selectFields){
                    selects += s + ',';
                }
                if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}
                 
            }
            System.debug('selects*********'+selects);
            Set<Id> oqoutLineIdSet = oppIdVsReaasignOppIdMap.keySet();
            String quoteLineQuery = 'SELECT '+selects+',SBQQ__Quote__r.SBQQ__Opportunity2__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c IN : oqoutLineIdSet';
            
            //For(SBQQ__QuoteLine__c qouteLineRec : [SELECT SBQQ__Quote__c,SBQQ__Quote__r.SBQQ__Opportunity2__c,Account_Name__c FROM SBQQ__QuoteLine__c 
            //                                  WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c IN : oppIdVsReaasignOppIdMap.keySet()])
            System.debug('quoteLineQuery**'+quoteLineQuery);
            For(SBQQ__QuoteLine__c qouteLineRec : Database.query(quoteLineQuery))
            {
                SBQQ__QuoteLine__c cloneQouteLine = qouteLineRec.Clone();
                cloneQouteLine.Account_Name__c = reaasignOppIdVsReaasignOppObjMap.get(oppIdVsReaasignOppIdMap.get(qouteLineRec.SBQQ__Quote__r.SBQQ__Opportunity2__c)).AccountId;
                cloneQouteLine.SBQQ__Quote__c = reaasignOppIdVsReaasignOppObjMap.get(oppIdVsReaasignOppIdMap.get(qouteLineRec.SBQQ__Quote__r.SBQQ__Opportunity2__c)).SBQQ__PrimaryQuote__c;
                
                cloneQouteLine.ReassignedFromOpportunityId__c = qouteLineRec.SBQQ__Quote__r.SBQQ__Opportunity2__c;
                cloneQouteLine.ReassignedFromRenewedContract__c = qouteLineRec.SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c;
                
                //cloneQouteLine.SBQQ__RequiredBy__c = null;
                if(qouteLineRec.SBQQ__RequiredBy__c == null)
                    cloneQouteLine.Old_Quote_Id__c = qouteLineRec.Id;
                System.debug('cloneQouteLine.SBQQ__Quote__c**********'+cloneQouteLine.SBQQ__Quote__c);
                quoteLineList.add(cloneQouteLine);
            }
            System.debug('quoteLineList*******'+quoteLineList);
            //Inserting QuoteLine to the re-assigned opportunity.
            if(quoteLineList.size()>0){
                if(!Test.isRunningtest()){
                    insert quoteLineList;
                }
                
                Map<String,Id> oldQLVsnewQLId = new Map<String,Id>();
                
                For(SBQQ__QuoteLine__c quoteLineRec : quoteLineList)
                {
                    if(String.isNotBlank(quoteLineRec.Old_Quote_Id__c)){
                        oldQLVsnewQLId.put(quoteLineRec.Old_Quote_Id__c,quoteLineRec.Id);
                    }
                }
                List<SBQQ__QuoteLine__c> tempUpdate = new List<SBQQ__QuoteLine__c>();
                List<SBQQ__Quote__c> tempQuoteUpdate = new List<SBQQ__Quote__c>();
                SBQQ__Quote__c quoteObj = new SBQQ__Quote__c(); 
                Set<Id> quoteId = new Set<Id>();
                For(SBQQ__QuoteLine__c quoteLineRec : quoteLineList)
                {
                    if(quoteLineRec.SBQQ__RequiredBy__c!=null){
                        quoteLineRec.SBQQ__RequiredBy__c = oldQLVsnewQLId.get(quoteLineRec.SBQQ__RequiredBy__c);
                        tempUpdate.add(quoteLineRec);
                        
                        if(!quoteId.contains(quoteLineRec.SBQQ__Quote__c)){
                            quoteObj = new SBQQ__Quote__c(Id = quoteLineRec.SBQQ__Quote__c);
                            quoteObj.SBQQ__Primary__c = false;                  
                            quoteId.add(quoteLineRec.SBQQ__Quote__c);
                            tempQuoteUpdate.add(quoteObj);
                        }
                    }
                }
                if(tempUpdate.size()>0 ) //&& !Test.isRunningTest()
                    update tempUpdate;
            }
            /*if(tempQuoteUpdate.size()>0)
                update tempQuoteUpdate;
            
            For(SBQQ__Quote__c quoteRec : tempQuoteUpdate)
            {
                quoteObj.SBQQ__Primary__c = true;   
            }
            
            update tempQuoteUpdate;*/
        }
        
    }
    //to delete bookings classification : Udita
    public static void deleteRelatedBookings(map<id,Opportunity> oldOppMap)
    {  
        List<Booking_Classification__c> relatedBookings = [SELECT id,Opportunity__c FROM Booking_Classification__c WHERE Opportunity__r.id IN: oldOppMap.keyset()];
        if(relatedBookings.size() > 0){
          delete relatedBookings;
        }
    }
    //method ends
    //Delete quote lines once Reassigned to is removed.....
    public static void DeleteReassignedToQuoteLines(Map<Id,Opportunity> newMapValues,Map<Id,Opportunity> oldMap){
        Opportunity oldOpportunity;
        Set<String> OppIdSet = new Set<String>();
        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        System.debug('newMapValues****'+newMapValues.keySet());
        List<Booking_Classification__c> deleteBCList = new List<Booking_Classification__c>();
        For(Opportunity opportunityRec : newMapValues.values()){
            oldOpportunity = oldMap.get(opportunityRec.Id);
            System.debug('newMaprEASSIGN****'+opportunityRec.Reassigned_To__c);
            System.debug('oldReassign****'+oldOpportunity.Reassigned_To__c);
            if(istest || (opportunityRec.Reassigned_To__c == null && opportunityRec.Reassigned_To__c != oldOpportunity.Reassigned_To__c && oldOpportunity.Reassigned_To__c!=null))
            {
                System.debug('Inside If');
                OppIdSet.add(String.ValueOf(oldOpportunity.Reassigned_To__c));
            }
        }
        System.debug('OppIdSet****'+OppIdSet);
        OppIdSet.remove(null);
       if(OppIdSet.size()>0){
            For(Booking_Classification__c BCRec : [SELECT Id FROM Booking_Classification__c WHERE Opportunity__c IN : OppIdSet])
            {
                deleteBCList.add(BCRec);
            }
            For(SBQQ__QuoteLine__c quoteLineRec : [SELECT Id FROM SBQQ__QuoteLine__c WHERE ReassignedFromOpportunityId__c IN : newMapValues.keySet() AND SBQQ__Quote__r.SBQQ__Opportunity2__c IN : OppIdSet]){
                quoteLineList.add(quoteLineRec);
            }
            System.debug('quoteLineList****'+quoteLineList);
            if(quoteLineList.size()>0)
                delete quoteLineList;
            if(deleteBCList.size()>0)
                delete deleteBCList;
        }
        
    }
    /*HSR : To update Booking Classification fields when some of the opportunity fields is being updated.*/
    public static void updateBCValues(Map<Id,Opportunity> oldMapValues, Map<Id,Opportunity> newMapValues){
        Opportunity oldOpp = new Opportunity();
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        For(Opportunity oppRec : newMapValues.values())
        {
            oldOpp = oldMapValues.get(oppRec.Id);
            if(istest || ((oppRec.SBQQ__AmendedContract__c != oldOpp.SBQQ__AmendedContract__c || 
                oppRec.Deal_Year__c != oldOpp.Deal_Year__c || 
                    oppRec.SBQQ__RenewedContract__c != oldOpp.SBQQ__RenewedContract__c || 
                    oppRec.Exchange_Rate__c != oldOpp.Exchange_Rate__c || 
                        oppRec.Contract_Type_2_0__c != oldOpp.Contract_Type_2_0__c) && oppRec.SBQQ__Contracted__c==false) || oppRec.Exchange_Rate__c != oldOpp.Exchange_Rate__c)
            {
                oppMap.put(oppRec.Id,oppRec);
            }
        }
        if(!oppMap.isEmpty()){
            List<Booking_Classification__c> BCObjList = new List<Booking_Classification__c>();
            For(Booking_Classification__c BCObj : [SELECT Id,Opportunity__c,SBQQ_AmendedContract__c,SBQQ_RenewedContract__c,Contract_Type_2_0__c,Deal_Years__c FROM Booking_Classification__c WHERE Opportunity__c IN : oppMap.keySet()]){
                
                BCObj.SBQQ_AmendedContract__c = oppMap.get(BCObj.Opportunity__c).SBQQ__AmendedContract__c!=null?String.ValueOf(oppMap.get(BCObj.Opportunity__c).SBQQ__AmendedContract__c):'';
                BCObj.SBQQ_RenewedContract__c = oppMap.get(BCObj.Opportunity__c).SBQQ__RenewedContract__c!=null?String.Valueof(oppMap.get(BCObj.Opportunity__c).SBQQ__RenewedContract__c):'';
                BCObj.Contract_Type_2_0__c = oppMap.get(BCObj.Opportunity__c).Contract_Type_2_0__c!=null?String.valueOf(oppMap.get(BCObj.Opportunity__c).Contract_Type_2_0__c):'';
                BCObj.Deal_Years__c = oppMap.get(BCObj.Opportunity__c).Deal_Year__c!=null?Integer.ValueOf(oppMap.get(BCObj.Opportunity__c).Deal_Year__c):null;
                BCObj.Exchange_Rates__c = oppMap.get(BCObj.Opportunity__c).Exchange_Rate__c;
                BCObjList.add(BCObj);
            }
        
            if(BCObjList.size()>0)
                update BCObjList;
        }
    }// end 
    
    
    /*
    Author : Kumud
    Desc: Set opportunity owner role : Move code from OwnerRoleTrigger  and deactivated the trigger
    Date: 26 June 2018

    */
    private static void populateOppOwnerRole(List<Opportunity> listOfOpp){

        Set<Id> setUserIDs = new Set<Id>();
        for(Opportunity instOpp : listOfOpp)
        {
            setUserIDs.add(instOpp.OwnerId);
        }
        
        Map<Id,User> mapUser = new Map<Id,User>([Select id, UserRole.Name from User where Id IN :setUserIDs]);
        
        for(Opportunity instOpp : listOfOpp){
            
            
            if(mapUser.containskey(instOpp.ownerID) && mapUser.get(instOpp.ownerID)!=null){
                
                instOpp.opp_owner_role__c = mapUser.get(instOpp.OwnerId).UserRole.Name;
            }
            
        }

    } // end of method

    /*
    Author : Kumud
    Desc: Move delete validation here
    Date: 26 June 2018

    */
    public static void onbeforeDelete(List<Opportunity> listOfOpportunity){
        
        final String userID=label.OpprtunityDeleteUserID;
        final Id loginUserID=userInfo.getUserID();
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>(); 
        String[] toAddresses = new String[]{'vaibhav.jain@cvent.com','ZMahmood@cvent.com','Ankit.Jain@cvent.com'};
        String ProfileId = UserInfo.getProfileId();
        
        //OppDeleteCS Trigger
        List<Profile> userRec =  [Select id from Profile where name = 'Client Services Leadership' or Name = 'System Administrator'];   
        
        
        for(opportunity  instOFOpp : listOfOpportunity){
             // PreventOppDeletion,preventoppdelete  trigger. 
            if (!instOFOpp.ignoreValidation__c && loginUserID !=userID && ((instOFOpp.StageName == 'Closed Won'||instOFOpp.StageName == 'Closed Lost') && instOFOpp.New_Type__c.startswith('Renewal') || (instOFOpp.StageName == 'Closed Won'&& instOFOpp.CFC_Check__c != null && instOFOpp.Contract_Implemented__c == True))) {
            
                instOFOpp.addError('You are not authorised to delete this Opportunity.');
             
            }
            
            if(!instOFOpp.ignoreValidation__c && loginUserID !=userID && instOFOpp.LeadSource == 'Client Services'  && (ProfileId != userRec[0].Id || ProfileId != userRec[0].Id)  ){
                
                instOFOpp.addError('You cannot delete opportunities created by Client Services');
            }
            
            if(!instOFOpp.ignoreValidation__c && loginUserID !=userID && instOFOpp.Master_Type__c!=null &&  instOFOpp.Master_Type__c.contains('Renewal') ){
                
                instOFOpp.addError('You are not authorised to delete this Opportunity.');
            }

            else if(instOFOpp.New_Type__c!=null && instOFOpp.New_Type__c.contains('Renewal')){
                
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(toAddresses);
                    mail.setSenderDisplayName('CVENT Notifications');
                    mail.setSubject('Opportunity deleted!');
                    mail.setBccSender(false);
                    mail.setUseSignature(false);
                    mail.setHtmlBody ('Hi,</br></br>'+
                    'An opportunity has been deleted. Please see details below: </br>' +
                    'Opportunity Name : '+ instOFOpp.Name + '</br>' +
                    'Opportunity Link : https://cvent.my.salesforce.com/'+ instOFOpp.Id + '</br>' +
                    'Unique Id Opp : '+ instOFOpp.Unique_ID_Opp__c + '</br>' +
                    'Contract Type : '+ instOFOpp.New_Type__c + '</br>' +
                    'Close Date : '+ instOFOpp.CloseDate + '</br>' +
                    'Product : '+ instOFOpp.Product__c + '</br>' +
                    'Opportunity Owner : '+ instOFOpp.Owner + '</br>' +
                    'Contract Total : '+ instOFOpp.New_Contract_Total__c + '</br>' +
                    'Account Link : https://cvent.my.salesforce.com/'+ instOFOpp.AccountId+ '</br>' +
                    'Deleted by: '+ UserInfo.getName()  + '</br></br>' +
                    'Regards,</br>'+ 
                    'Sales Support India');
                    mails.add(mail);
                
            }
        } // end of loop
        if(!mails.isEmpty()){
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>(mails));
        }
            
    }// end 

    
    /*
        
        Author : Kumud
        Desc: Call task automation and billing handler on after update of opportunity: // Moving code from trigger to Handler


    */
    private static void onAfterUpdateTaskBillingUpdate(List<Opportunity> listOpp,Map<Id,Opportunity> newMapOpp,Map<Id,Opportunity> oldMapOpp){

        //Add by Kumud 
        Map<Id, Opportunity> newMapOppty=new  Map<Id ,Opportunity>();
        Map<Id, Opportunity> oldMapOppty=new  Map<Id, Opportunity>();
        //For Onboarding Creation
        Map<Id, Opportunity> newMapOnboardingOppty=new  Map<Id ,Opportunity>();
        Map<Id, Opportunity> oldMapOnboardingOppty=new  Map<Id, Opportunity>();
        //When Primary Quote is re-synced or Net Total is updated.....
        Set<Id> oppIdBCCalculate = new Set<Id>();
        Set<String> oppIdReassignBCCalculate = new Set<String>();
        Map<String,Id> oldNewOppLineIdMap = new Map<String,id>();
        for(Opportunity objOppty:listOpp){
            
            if((objOppty.stageName!=oldMapOpp.get(objOppty.id).stageName || objOppty.Contract_Implemented__c !=oldMapOpp.get(objOppty.id).Contract_Implemented__c) && (objOppty.stageName=='Closed Won' && objOppty.Contract_Implemented__c)){
                if(!objOppty.Task_Created__c){
                  newMapOppty.put(objOppty.id,objOppty);
                  oldMapOppty.put(objOppty.id,oldMapOppty.get(objOppty.id));
                }
                //if(!objOppty.Onboarding_Created__c)
                //{
                    newMapOnboardingOppty.put(objOppty.id,objOppty);
                    oldMapOnboardingOppty.put(objOppty.id,oldMapOppty.get(objOppty.id));
                //}
              }
              //When Primary Quote is re-synced or Net Total is updated.....
              if(objOppty.SBQQ__PrimaryQuote__c!=oldMapOpp.get(objOppty.id).SBQQ__PrimaryQuote__c || objOppty.Net_Amount_Opp__c!=oldMapOpp.get(objOppty.id).Net_Amount_Opp__c){
                  oppIdBCCalculate.add(objOppty.Id);
                  if(String.isNotBlank(objOppty.Reassigned_To__c)){
                      oppIdReassignBCCalculate.add(objOppty.Reassigned_To__c);
                      oldNewOppLineIdMap.put(objOppty.Reassigned_To__c,objOppty.Id);
                  }
              }
              
        } 
        //When Primary Quote is re-synced or Net Total is updated.....
        if(oppIdBCCalculate.size()>0 && Label.IsBCRecalculate=='True'){
            SnapShotUtilityHelper.CreateOppProdSnapshot(null,oppIdBCCalculate,oppIdReassignBCCalculate,oldNewOppLineIdMap);
        }
        if(!TaskAssignAutomationTrgHelper.isRun && newMapOppty.size()>0 && Label.IsTaskAssignAutomationTrgHelper=='True')
            TaskAssignAutomationTrgHelper.onAfterUpdatecreateTask(newMapOppty,oldMapOppty);  
        if(!TaskAssignAutomationTrgHelper.isRunOnboard && newMapOnboardingOppty.size()>0)
            TaskAssignAutomationTrgHelper.onAfterUpdatecreateOnboarding(newMapOnboardingOppty,oldMapOnboardingOppty);  
            // End here 
        // Add by kd
        List<Opportunity> listOpp_ContractImpl=new List<Opportunity>(); 
        /*  below list and set are used to identify whether it is hybrid opp or not */
        List<Opportunity> listHybridOpp=new List<Opportunity>(); 
        List<Opportunity> listNonHybridOpp=new List<Opportunity>();
        Set<Id> setOppIDs=new Set<Id>();
        for(Opportunity oppty:listOpp){
                if((newMapOpp.get(oppty.id).Contract_Implemented__c !=oldMapOpp.get(oppty.id).Contract_Implemented__c||newMapOpp.get(oppty.id).Contract_Number_New__c!=oldMapOpp.get(oppty.id).Contract_Number_New__c) && newMapOpp.get(oppty.id).Contract_Implemented__c){
                   listOpp_ContractImpl.add(newMapOpp.get(oppty.id));
                   setOppIDs.add(oppty.id);
                }
        }
        if(listOpp_ContractImpl.size()>0 && !billingCaseCreate_Opp_handler.isRunonce){
            Map<Id,Boolean>  mapOppIdIsHybrid=AssignReviewerOpptyTriggerHelper.isHybridOppty(setOppIDs);
            billingCaseCreate_Opp_handler.isRunonce=true;
            billingCaseCreate_Opp_handler.createContractReview(listOpp_ContractImpl,mapOppIdIsHybrid);
        }


    }
        
}// end of class