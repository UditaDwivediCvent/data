public class ContractTrgHelperCls {

    public static Map<Id,Opportunity> contractIdToAmendmentOpportunity = new Map<Id,Opportunity>();

    public static Map<Id,Id> contractIdToOriginalAmendmentOpportunityId = new Map<Id,Id>();

    public static Map<Id,List<SBQQ__Subscription__c>> legacyContractIdToSubscriptions = new Map<Id,List<SBQQ__Subscription__c>>();

    public static Map<Id,Date> accountIdToEndDate = new Map<Id,Date>();

    public static Set<Id> contractIdsBeingRenewed = new Set<Id>();

    public static Set<Id> opportunityIdsContracted = new Set<Id>();

    public static Set<Id> childContractIdsInserted = new Set<Id>();

    public static Boolean contractGenerationMonitorScheduled = false;

    // call this method handleContractedOpportunities from opportunity trigger handler/dispatcher, before update

    public static void handleContractedOpportunities() {

        List<Opportunity> opportunities = (List<Opportunity>)Trigger.new;

        for(Opportunity opportunity : opportunities) {

            System.debug('opportunity id, in ContractTrgHelperCls: ' + opportunity.Id);

            Opportunity oldOpportunity = (Opportunity)Trigger.oldMap.get(opportunity.Id);

            Boolean wasContracted = oldOpportunity.SBQQ__Contracted__c;

            Boolean isContracted = opportunity.SBQQ__Contracted__c;

            if(!wasContracted && isContracted) {

                opportunity.contractedDateTime__c = DateTime.now();

                opportunityIdsContracted.add(opportunity.Id);

            }

            opportunity.contractedCompleted__c = (wasContracted != isContracted) ? false : opportunity.contractedCompleted__c;

            if(!CventMyd_ContractGenerationMonitor.isRunning && !isContracted && wasContracted) {

                opportunity.contractedRetried__c = false;

            }

        }

    }    

    public static void handleAfterInsert() {

        Map<Id,Date> accountIdToUpdateToEndDate = new Map<Id,Date>();

        for(Contract contract : (List<Contract>)Trigger.new) {

            Boolean updateAccount = ( accountIdToEndDate.get(contract.AccountId) == null || accountIdToEndDate.get(contract.AccountId) != contract.EndDate ) ;

            if(contract.RecordTypeId == CventMyd_Settings.parentContractRecordTypeId && updateAccount)  {

                accountIdToUpdateToEndDate.put(contract.AccountId,contract.EndDate);

            }

            if(accountIdToUpdateToEndDate.size() > 0) {

                updateEndDatesOnAccounts(accountIdToUpdateToEndDate);

            }

            if(contract.RecordTypeId == CventMyd_Settings.childContractRecordTypeId) {

                childContractIdsInserted.add(contract.Id);

            }

        }

    }

    public class RenewalException extends Exception {}

    public static void throwRenewalException(Id contractId, Boolean isLegacy) {

        String exceptionString = 'There are less than 1 renewable products on';

        exceptionString += (!isLegacy) ? ' non-legacy' : ' legacy';

        exceptionString += ' contract with Id';

        exceptionString += ' ' + '\'' + String.valueOf(contractId) + '\'';

        throw new RenewalException(exceptionString);

    }

    public static void handleBeforeUpdate() {

        Set<Id> contractIdsToQueryForAmendments = new Set<Id>();

        Boolean renewalQuotedChecked = false;

        Set<Id> legacyContractIdsToQuerySubscriptions = new Set<Id>();

        Id renewalMasterId = CventMyd_AutoRenewContractSchedulable.renewalChainMasterId;

        Boolean queryAmendmentOpportunities = ( System.isFuture() && !CventMyd_Settings.contractingInForeground ) || ( CventMyd_Settings.contractingInForeground && !opportunityIdsContracted.isEmpty()  );

        System.debug('ContractTrgHelperCls isFuture: ' + System.isFuture());

        for(Contract contract : (List<Contract>)Trigger.new) {

            Date endDate = contract.EndDate;

            if(contract.RecordTypeId == CventMyd_Settings.childContractRecordTypeId) {

                Integer daysInAdvanced = (contract.Upcoming_Renewal_Type__c == 'MYD Renewal') ? 90 : 365;

                contract.Renewal_Opportunity_Creation__c = String.valueOf(daysInAdvanced) + ' days in advance';

                contract.Renewal_Creation_Date__c = (endDate != null) ? endDate.addDays((-1)*daysInAdvanced) : null ;

            }

            contract.renewalChainMaster__c = (renewalMasterId != null) ? renewalMasterId : contract.renewalChainMaster__c;

            if(queryAmendmentOpportunities && !contractIdToAmendmentOpportunity.containsKey(contract.Id) && !childContractIdsInserted.contains(contract.Id)) {

                contractIdsToQueryForAmendments.add(contract.Id);

            }

            Boolean oldRenewalQuoted = ((Contract)Trigger.oldMap.get(contract.Id)).SBQQ__RenewalQuoted__c;

            Boolean newRenewalQuoted = contract.SBQQ__RenewalQuoted__c;

            Boolean isLegacyRenewal = (contract.isLegacy__c && contract.contractedAmendmentOpportunity__c == null);

            if(!oldRenewalQuoted && newRenewalQuoted) {

                contractIdsBeingRenewed.add(contract.Id);

                renewalQuotedChecked = true;

                Boolean isLegacy = contract.isLegacy__c;   

                if(!isLegacyRenewal && contract.renewableLineCount__c < 1 && !Test.isRunningTest()) {

                    throwRenewalException(contract.Id,false);

                }

            }

            Boolean haventQueriedSubscriptions = !ContractTrgHelperCls.legacyContractIdToSubscriptions.containsKey(contract.Id);

            if(renewalQuotedChecked && isLegacyRenewal && haventQueriedSubscriptions) {

                legacyContractIdsToQuerySubscriptions.add(contract.Id);

            }

        }

        System.debug('legacyContractIdsToQuerySubscriptions: ' + legacyContractIdsToQuerySubscriptions);

        List<SBQQ__Subscription__c> legacySubscriptions = new List<SBQQ__Subscription__c>();

        Boolean querySubscriptions = (legacyContractIdsToQuerySubscriptions.size() > 0);

        if(querySubscriptions) {

            legacySubscriptions = CventMyd_LegacyContractHandler.getAndSetLegacySubscriptions(legacyContractIdsToQuerySubscriptions);

        }

        System.debug('legacySubscriptions keySet: ' + (new Map<Id,SBQQ__Subscription__c>(legacySubscriptions)).keySet() );

        if(legacySubscriptions.size() > 0) {

            System.debug('legacy subscriptions found....');

            for(Id contractId : ContractTrgHelperCls.legacyContractIdToSubscriptions.keySet()) {

                if(contractIdsBeingRenewed.contains(contractId)) {

                    List<SBQQ__Subscription__c> subscriptions = ContractTrgHelperCls.legacyContractIdToSubscriptions.get(contractId);

                    Decimal renewableLineCount = CventMyd_LegacyContractHandler.getRenewableLineCount(subscriptions);

                    if(renewableLineCount < 1) {

                        throwRenewalException(contractId,true);

                    }

                }

            }

            update legacySubscriptions;

        }

        else if(legacySubscriptions.size() == 0 && querySubscriptions) {

            for(Id contractId : legacyContractIdsToQuerySubscriptions) {

                Boolean isLegacy = ((Contract)Trigger.newMap.get(contractId)).isLegacy__c;

                if(isLegacy){throwRenewalException(contractId,true);}

            }

        }

        Set<Id> amendmentQuoteIdsToUpdateSusbcriptions = new Set<Id>();

        System.debug('contractIdsToQueryForAmendments: ' + contractIdsToQueryForAmendments);

        if(contractIdsToQueryForAmendments.size() > 0) {

            DateTime twentyMinutesAgo = DateTime.now().addMinutes(-10);

            for(Contract contract : [SELECT Id,

                (SELECT Id,SBQQ__PrimaryQuote__c,Master_Agreement__c,

                SBQQ__PrimaryQuote__r.Contract_Extension__c,SBQQ__Contracted__c,

                SBQQ__PrimaryQuote__r.Multiple_Years_Commitment__c,

                SBQQ__PrimaryQuote__r.jsonString__c,contractedCompleted__c

                FROM SBQQ__AmendmentOpportunities__r

                WHERE SBQQ__Contracted__c = TRUE AND contractedCompleted__c != TRUE

                AND contractedDateTime__c >: twentyMinutesAgo

                ORDER BY contractedDateTime__c DESC NULLS LAST, CreatedDate DESC

                LIMIT 30)         

                FROM Contract

                WHERE Id IN: contractIdsToQueryForAmendments

            ]) {

                for(Opportunity opportunity : contract.SBQQ__AmendmentOpportunities__r) {

                    if(opportunity.SBQQ__PrimaryQuote__r.jsonString__c != null) {

                        contractIdToAmendmentOpportunity.put(contract.Id,opportunity);

                        amendmentQuoteIdsToUpdateSusbcriptions.add(opportunity.SBQQ__PrimaryQuote__c);

                        break;

                    }

                }

            }

        }

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for(Contract contract : (List<Contract>)Trigger.new) {

            if(contract.RecordTypeId == CventMyd_Settings.childContractRecordTypeId && contract.SBQQ__Quote__c != null) {

                contract.EndDate = contract.quoteEndDate__c;

            }
            
            Opportunity amendmentOpportunity = contractIdToAmendmentOpportunity.get(contract.Id);

            if(amendmentOpportunity != null && !amendmentOpportunity.contractedCompleted__c && amendmentOpportunity.SBQQ__PrimaryQuote__c != null) {

                System.debug('amendmentOpportunity.Id: ' + amendmentOpportunity.Id);

                contract.contractedAmendmentOpportunity__c = amendmentOpportunity.Id;

                contract.Last_Amended_Opportunity_Contracted__c = System.now();

                contract.contractedAmendmentQuote__c = amendmentOpportunity.SBQQ__PrimaryQuote__c;

                contract.Multiple_Years_Commitment__c = amendmentOpportunity.SBQQ__PrimaryQuote__r.Multiple_Years_Commitment__c;

                Boolean opportunityHasExtension = (amendmentOpportunity.SBQQ__PrimaryQuote__r.Contract_Extension__c != null && amendmentOpportunity.SBQQ__PrimaryQuote__r.Contract_Extension__c != '');

                contract.Parent_Contract__c = (opportunityHasExtension) ? amendmentOpportunity.Master_Agreement__c : contract.Parent_Contract__c;

                amendmentOpportunity.contractedCompleted__c = true;

                opportunitiesToUpdate.add(amendmentOpportunity);                

            }

            Boolean statusChange = (contract.Status != ((Contract)Trigger.oldMap.get(contract.Id)).Status);

            Boolean closedExecution = (contract.Status=='Closed/Executed' || contract.Status == 'Closed/Not Executed');

            if(statusChange && closedExecution) {

                contract.Status_Change_Date__c = System.today();

            }

        }

        System.debug('amendmentQuoteIdsToUpdateSusbcriptions: ' + amendmentQuoteIdsToUpdateSusbcriptions);

        if(amendmentQuoteIdsToUpdateSusbcriptions.size() > 0) {

            CventMyd_UtilityMethods.updateSubscriptionsAfterAmendment(amendmentQuoteIdsToUpdateSusbcriptions);

        }

        if(opportunitiesToUpdate.size() > 0) {

            // update opportunitiesToUpdate;

        }              

    }

    public static void handleAfterUpdate(){

        Map<Id,Date> accountIdToUpdateToEndDate = new Map<Id,Date>();

        for(Contract contract : (List<Contract>)Trigger.new) {

            Boolean updateAccount = ( accountIdToEndDate.get(contract.AccountId) != null && accountIdToEndDate.get(contract.AccountId) != contract.EndDate );

            Boolean endDateChanged = (Date)Trigger.oldMap.get(contract.Id).get('EndDate') != contract.EndDate;

            Boolean accountIdChanged = (Id)Trigger.oldMap.get(contract.Id).get('AccountId') != contract.AccountId;

            if(contract.RecordTypeId == CventMyd_Settings.parentContractRecordTypeId && (updateAccount || endDateChanged)) {

                accountIdToUpdateToEndDate.put(contract.AccountId,contract.EndDate);

            }

            if(accountIdToUpdateToEndDate.size() > 0) {

                updateEndDatesOnAccounts(accountIdToUpdateToEndDate);

            }

        }

    }

    public static void updateEndDatesOnAccounts(Map<Id,Date> accountIdToUpdateToEndDate) {

        List<Account> accountsToUpdate = new List<Account>();

        for(Id accountId : accountIdToUpdateToEndDate.keySet()) {

            Account account = new Account(Id = accountId, Contract_End_Date_Dev__c = accountIdToUpdateToEndDate.get(accountId));

            accountsToUpdate.add(account);

            accountIdToEndDate.put(accountId,accountIdToUpdateToEndDate.get(accountId));

        }

        update accountsToUpdate;
                       
    }

    public static void handleContractedMonitoring() {

        if(!CventMyd_Settings.contractingInForeground && !CventMyd_ContractGenerationMonitor.isRunning && !opportunityIdsContracted.isEmpty() && !contractGenerationMonitorScheduled) {

            Integer scheduledJobsRunning = CventMyd_UtilityMethods.queryScheduledJobCount();

            if(scheduledJobsRunning <= CventMyd_Settings.scheduledJobMax) {

                System.debug('this happened 1');

                String dateTimeString = CventMyd_UtilityMethods.getFormattedDateTimeString(DateTime.now(),true,true);

                String jobName = 'Contracting Monitor @ ' + dateTimeString;

                CventMyd_ContractGenerationMonitor contractGenerationMonitor = new CventMyd_ContractGenerationMonitor(opportunityIdsContracted, jobName);

                Integer secondsBeforeJobStart = (!Test.isRunningTest()) ? CventMyd_Settings.minutesBeforeContractMonitor * 60 : 100;

                String cronString = CventMyd_UtilityMethods.getCronString(secondsBeforeJobStart);

                contractGenerationMonitorScheduled = true;

                System.schedule(jobName,cronString,contractGenerationMonitor);

            }

            else if(scheduledJobsRunning > CventMyd_Settings.scheduledJobMax) {

                String subjectString = '***URGENT*** You have too much schedulable Apex running ***URGENT***';

                String htmlBodyString = 'Opportunities with following Id(s) have just been contracted.<br/><br/>';

                Id whatId;

                for(Id opportunityId : opportunityIdsContracted) {

                    htmlBodyString += String.valueOf(opportunityId)  + ';';

                    whatId = opportunityId;

                }

                htmlBodyString += '<br/><br/>However, there are ' + String.valueOf(scheduledJobsRunning) + ' Schedulable Apex jobs enqueued';

                htmlBodyString += ', which is greater than the specified threshhold of ' + Integer.valueOf(CventMyd_Settings.scheduledJobMax) + ' jobs.';

                htmlBodyString += '<br/><br/>As such, no child contract generation monitoring will occur.';

                htmlBodyString += '<br/><br/>Kindly cleanup your usage of Schedulable Apex.';

                htmlBodyString += '<br/><br/>Monitor the child contract generation yourself.';

                Messaging.SingleEmailMessage singleEmailMessage = CventMyd_UtilityMethods.getSingleEmailMessage(null,htmlBodyString,subjectString,whatId);

                CventMyd_UtilityMethods.sendEmail(singleEmailMessage);

            }

        }

    }
    
}