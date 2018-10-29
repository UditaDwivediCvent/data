public without sharing class CventMyd_QuoteTriggerHandler {

    public static Map<String,Opportunity> quoteInsertionIdToOpportunity = new Map<String,Opportunity>();

    public static List<List<String>> fieldValueMapFieldNameLists = new List<List<String>>();

    public static Map<Id,Id> amendedContractIdToAmendmentOpportunityId = new Map<Id,Id>();

    public static Map<Id,CpqAudit__c> quoteIdToInsertionAuditRecord = new Map<Id,CpqAudit__c>();

    public static Map<Id,Id> quoteIdToNextQuote = new Map<Id,Id>();

    public static Set<Id> newQuoteIds = new Set<Id>();

    public static Id contractIdInRenewalJob;

    public static Id amendmentChainMasterId;

    public static Id renewalChainMasterId;

    public static String sessionIdString;

    public static Boolean disabledCpqTriggers = false;

    public static Map<String,Opportunity> getUpdatedQuoteToOpportunityMap(Map<String,Opportunity> quoteInsertionIdToOpportunity) {

        Map<Id,List<String>> opportunityIdToInsertionIds = new Map<Id,List<String>>();

        for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>)Trigger.new) {

            CventMyd_QuoteObject quoteObject = CventMyd_UtilityMethods.getQuoteObject(quote);
            
            if(quoteObject != null && quote.nextQuote__c == null) {

                String insertionId = quoteObject.insertionId;

                if(!quoteInsertionIdToOpportunity.containsKey(insertionId)) {

                    if(!opportunityIdToInsertionIds.containsKey(quote.SBQQ__Opportunity2__c)) {

                        opportunityIdToInsertionIds.put(quote.SBQQ__Opportunity2__c,new List<String>());

                    }

                    opportunityIdToInsertionIds.get(quote.SBQQ__Opportunity2__c).add(insertionId);

                }

            }

        }

        Set<Id> opportunityIdsToQuery = opportunityIdToInsertionIds.keySet();

        if(opportunityIdsToQuery.size() > 0) {

            String queryString = 'SELECT Id,Name';

            queryString += ',' + CventMyd_Settings.opportunityFieldNamesString;

            queryString += ', (SELECT Id,Name,SBQQ__Primary__c,Cloned_From_Quote__c FROM SBQQ__Quotes2__r ORDER BY CreatedDate DESC)';

            queryString += ' FROM Opportunity';

            queryString += ' WHERE Id IN: opportunityIdsToQuery';

            for(Opportunity opportunity : Database.query(queryString)) {

                for(String insertionId : opportunityIdToInsertionIds.get(opportunity.Id)) {

                    quoteInsertionIdToOpportunity.put(insertionId,opportunity);

                }

            }

        }

        return quoteInsertionIdToOpportunity;

    }

    /*
       #Added By Mohsin

       Whenever a new quote is being created, this method will check for the 'amended contract’ field on opportunity.

       If 'amended contract’ is not blank and this quote is not the first quote for the parent opportunity then it will not allow user to create the Quote.
       
    */
    
    public static void checkForAmendedContract() {

        Map<Id,List<SBQQ__Quote__c>> opportunityIdToQuotes = new Map<Id,List<SBQQ__Quote__c>>();

        System.debug('trigger new size: ' + Trigger.new.size());
        
        for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>)Trigger.new) {

            if(quote.SBQQ__Opportunity2__c != null) {

                System.debug('opportunityId 0: ' + quote.SBQQ__Opportunity2__c);

                if(opportunityIdToQuotes.get(quote.SBQQ__Opportunity2__c) == null) {

                    opportunityIdToQuotes.put(quote.SBQQ__Opportunity2__c, new List<SBQQ__Quote__c>());

                }

                opportunityIdToQuotes.get(quote.SBQQ__Opportunity2__c).add(quote);

            }

        }

        if(Trigger.isInsert) {
        
            for(Opportunity opp : quoteInsertionIdToOpportunity.values()) {

                if(opportunityIdToQuotes.containsKey(opp.Id) && opp.SBQQ__AmendedContract__c != null) {

                    List<SBQQ__Quote__c> quotes = opp.SBQQ__Quotes2__r;

                    if(quotes.size() > 0 || CventMyd_ContractAmendmentController.contractIdsBeingAmended.isEmpty()) {

                        System.debug('opportunityId 1: ' + opp.Id);

                        for(SBQQ__Quote__c quote : opportunityIdToQuotes.get(opp.Id)) {

                            quote.addError('You’ve already started an amendment; in order to change create a new quote, create a new opportunity.');

                        }
                    
                    }

                }

            }

        }

        else if(Trigger.isUpdate) {

            for(Id opportunityId : opportunityIdToQuotes.keySet()) {

                List<SBQQ__Quote__c> quotes = opportunityIdToQuotes.get(opportunityId);

                for(SBQQ__Quote__c quote : quotes) {

                    if(quote.opportunityAmendedContractId__c != null) {

                        Boolean oldPrimaryBoolean = ((SBQQ__Quote__c)Trigger.oldMap.get(quote.Id)).SBQQ__Primary__c;

                        Boolean newPrimaryBoolean = quote.SBQQ__Primary__c;

                        if(CventMyd_ContractAmendmentController.contractIdsBeingAmended.isEmpty() && oldPrimaryBoolean != newPrimaryBoolean) {

                            quote.addError('It is not permitted to explicitly change the primary checkbox of an existing quote sitting on an amendment opportunity.');

                        }

                    }

                }

            }

        }

    }
    
    public static void handleBeforeInsert() {

        System.debug('#####CventMyd_QuoteTriggerHandler.handleBeforeInsert()#####');

        List<Opportunity> opportunitiesToDelete = new List<Opportunity>();

        System.debug('sessionIdString (in quote trigger handler): ' + sessionIdString);

        renewalChainMasterId = CventMyd_AutoRenewContractSchedulable.renewalChainMasterId;

        for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>)Trigger.new) {

            if(quote.Cloned_From_Quote__c == null) {

                quote.renewalChainMaster__c = renewalChainMasterId;

                quote.amendmentChainMaster__c = amendmentChainMasterId;

                CventMyd_QuoteObject quoteObject = new CventMyd_QuoteObject();

                quoteObject.insertionId = CventMyd_UtilityMethods.getQleId();

                System.debug('quoteObject.insertionId: ' + quoteObject.insertionId);

                quoteObject.settings = new CventMyd_QuoteObject.Settings();

                quoteObject.settings.preCalculationFieldNames = CventMyd_Settings.fieldValueMapFieldNameLists[0];

                quoteObject.settings.calculatedFieldNames = CventMyd_Settings.fieldValueMapFieldNameLists[1];

                quoteObject.settings.msAtLastUpdate = null;

                quoteObject.automationStage = new CventMyd_QuoteAutomationStage();

                quoteObject.automationStage.codeStatus = CventMyd_QuoteAutomationStage.CodeStatus.LAST_UPDATED_BY_TRIGGER;

                quoteObject.outyearMap = new Map<Integer,CventMyd_Outyear>();

                quote.jsonString__c = JSON.serialize(quoteObject);

            }

        }        

        quoteInsertionIdToOpportunity = getUpdatedQuoteToOpportunityMap(quoteInsertionIdToOpportunity);

        checkForAmendedContract();  //#Added By Mohsin
        
        for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>)Trigger.new) {         
            
            if(quote.SBQQ__Type__c != null && quote.Cloned_From_Quote__c == null ) {

                quote.sessionIdString__c = sessionIdString;

                CventMyd_QuoteObject quoteObject = CventMyd_UtilityMethods.getQuoteObject(quote);

                Opportunity opportunity = quoteInsertionIdToOpportunity.get(quoteObject.insertionId);

                quote.CurrencyIsoCode = (opportunity != null) ? opportunity.CurrencyIsoCode : quote.CurrencyIsoCode;

                SBQQ__Quote__c previousQuote;

                if(quote.SBQQ__Type__c == 'Renewal' && opportunity.SBQQ__RenewedContract__r != null && !quote.msaUpload__c) {

                    Contract childContract = opportunity.SBQQ__RenewedContract__r;

                    quote.Contract_Term_Years__c = childContract.Parent_Contract_Term_Years__c;

                    System.debug('Child Contract End Date before'+childContract.EndDate);

                    quote.SBQQ__StartDate__c = childContract.EndDate.addDays(1);

                     System.debug('Child Contract End Date after'+childContract.EndDate);

                    if(childContract.Upcoming_Renewal_Type__c == 'Contract Renewal') {

                        quote.Current_Year__c = 1;

                        System.debug('***********outside if*********'+quote.of_Products_with_Renewal_for_24_Months__c);

                        if(quote.of_Products_with_Renewal_for_24_Months__c > 0) {
                      
                            quote.SBQQ__EndDate__c = quote.SBQQ__StartDate__c.addYears(2);

                            quote.SBQQ__EndDate__c = quote.SBQQ__EndDate__c.addDays(-1); 

                            System.debug('***if start***' + quote.SBQQ__EndDate__c); 
                        }

                        else{
                            
                            quote.SBQQ__EndDate__c = quote.SBQQ__StartDate__c.addYears(1);

                            quote.SBQQ__EndDate__c = quote.SBQQ__EndDate__c.addDays(-1);

                        }
                        quote.Multiple_Years_Commitment__c = false;

                        quoteObject.automationStage.outyearProcessingStage = null;

                    }

                    else if(childContract.Upcoming_Renewal_Type__c == 'MYD Renewal') {

                        quote.isLockedIntratermRenewal__c = true;

                        quote.Current_Year__c = childContract.Current_Year__c + 1;

                        quote.Multiple_Years_Commitment__c = childContract.Multiple_Years_Commitment__c;

                    }

                    previousQuote = (childContract.contractedAmendmentQuote__c != null) ? childContract.contractedAmendmentQuote__r : childContract.SBQQ__Quote__r;

                    if(previousQuote != null && CventMyd_UtilityMethods.getQuoteObject(previousQuote) != null) {

                        quote.previousQuote__c = previousQuote.Id;

                        if(quote.Current_Year__c > 1) {

                            CventMyd_QuoteObject previousQuoteObject = CventMyd_UtilityMethods.getQuoteObject(previousQuote);

                            quote.SBQQ__EndDate__c = previousQuoteObject.outyearMap.get((Integer)quote.Current_Year__c).endDate;

                            for(Integer i = (Integer)quote.Current_Year__c + 1; i <= Integer.valueOf(quote.Contract_Term_Years__c); i++) {

                                quoteObject.outyearMap.put(i,previousQuoteObject.outyearMap.get(i));

                            }

                        }

                    }

                    else if(previousQuote == null || CventMyd_UtilityMethods.getQuoteObject(previousQuote) == null) {

                        quote.previousQuote__c = null;

                        quote.createdFromLegacyContract__c = true;

                        quote.SBQQ__EndDate__c = CventMyd_LegacyContractHandler.getEndDateForQuoteCreatedFromLegacyContract(quote,childContract);

                        quoteObject.outyearMap = CventMyd_UtilityMethods.getOutyearMap((SObject)childContract);

                        quoteObject.outyearMap.remove((Integer)quote.Current_Year__c);

                        quoteObject.currentYearSynced = true;

                    }

                }

                else if(quote.SBQQ__Type__c == 'Amendment' && opportunity.SBQQ__AmendedContract__r != null && !quote.msaUpload__c) {

                    Contract childContract = opportunity.SBQQ__AmendedContract__r;

                    quote.Multiple_Years_Commitment__c = childContract.Multiple_Years_Commitment__c;

                    quote.Current_Year__c = childContract.Current_Year__c;

                    quote.Contract_Term_Years__c = childContract.Parent_Contract_Term_Years__c;

                    quote.SBQQ__EndDate__c = childContract.EndDate;

                    Boolean amendmentOpportunityWasCreatedByUser = amendedContractIdToAmendmentOpportunityId.values().contains(opportunity.Id);

                    if(amendedContractIdToAmendmentOpportunityId.keySet().contains(opportunity.SBQQ__AmendedContract__c) && !amendmentOpportunityWasCreatedByUser) {

                        opportunitiesToDelete.add(opportunity);

                        quote.SBQQ__Opportunity2__c = amendedContractIdToAmendmentOpportunityId.get(opportunity.SBQQ__AmendedContract__c);

                    }                    

                    previousQuote = (childContract.contractedAmendmentQuote__c != null) ? childContract.contractedAmendmentQuote__r : childContract.SBQQ__Quote__r;

                    if(previousQuote != null && CventMyd_UtilityMethods.getQuoteObject(previousQuote) != null) {

                        quote.previousQuote__c = previousQuote.Id;

                        String insertionId = quoteObject.insertionId;

                        quoteObject = CventMyd_UtilityMethods.getQuoteObject(previousQuote);

                        quoteObject.insertionId = insertionId;

                        quoteObject.automationStage.codeStatus = CventMyd_QuoteAutomationStage.CodeStatus.LAST_UPDATED_BY_TRIGGER;

                    }

                    else if(previousQuote == null || CventMyd_UtilityMethods.getQuoteObject(previousQuote) == null) {

                        quote.previousQuote__c = null;

                        quote.createdFromLegacyContract__c = true;

                        quoteObject.outyearMap = CventMyd_UtilityMethods.getOutyearMap((SObject)childContract);

                        quote.SBQQ__EndDate__c = childContract.EndDate;

                    }

                }

                if(previousQuote != null) {quoteObject.previousQuoteType = previousQuote.SBQQ__Type__c;}

                quoteObject.automationStage.outyearProcessingStage = (quote.Multiple_Years_Commitment__c) ? CventMyd_QuoteAutomationStage.OutyearProcessingStage.NEWLY_INSERTED_VARIABLE : CventMyd_QuoteAutomationStage.OutyearProcessingStage.NEWLY_INSERTED_NON_VARIABLE;

                quote.SBQQ__LineItemsGrouped__c = (quote.SBQQ__Type__c == 'Renewal' || quote.SBQQ__Type__c == 'Amendment') ? quote.Multiple_Years_Commitment__c : false;

                Integer finalYear = (quote.Contract_Term_Years__c != null) ? Integer.valueOf(quote.Contract_Term_Years__c) : null;

                Boolean newQuote = (quote.SBQQ__Type__c == 'Quote');

                Boolean termRenewal = (quote.SBQQ__Type__c == 'Renewal' && quote.Current_Year__c == 1);
                
                quoteObject.outyearMap = (newQuote || termRenewal || quote.msaUpload__c) ? CventMyd_UtilityMethods.getOutyearMap((SObject)quote) : quoteObject.outyearMap;

                quote.Contract_End_Date__c = (finalYear != null && quoteObject.outyearMap.get(finalYear) != null) ? Date.valueOf(quoteObject.outyearMap.get(finalYear).endDate) : quote.SBQQ__EndDate__c;

                quote.jsonString__c = JSON.serialize(quoteObject);

                quote.SBQQ__Primary__c = true;

                quote.RecordTypeId = CventMyd_Settings.quoteUnlockedRecordTypeId;

            }

        }

        if(opportunitiesToDelete.size() > 0) {

            delete opportunitiesToDelete;

        }

        if(cloneRelated.pass != true) {

            Set<Id> quoteIdsToUncheckPrimary = new Set<Id>();

            for(Opportunity o : quoteInsertionIdToOpportunity.values()) {

                if(o.SBQQ__Quotes2__r.size() > 0) {

                    for(Integer i = 0; i < o.SBQQ__Quotes2__r.size(); i++) {

                        SBQQ__Quote__c quote = o.SBQQ__Quotes2__r[i];

                        if(quote.Id != null && quote.SBQQ__Primary__c) {

                            quoteIdsToUncheckPrimary.add(quote.Id);

                        }

                    }

                }

            }

            if(quoteIdsToUncheckPrimary.size() > 0 && !System.isFuture() && !System.isBatch()) {

                CventMyd_UtilityMethods.uncheckPrimaryOnQuotes(quoteIdsToUncheckPrimary);

            }

        }

    }

    public static void handleAfterInsert() {

        System.debug('#####CventMyd_QuoteTriggerHandler.handleAfterInsert()#####');

        List<CpqAudit__c> auditRecords = new List<CpqAudit__c>();

        String apexLimitsString = CventMyd_UtilityMethods.getApexLimitsString();

        Set<Id> quoteIdsToDelete = new Set<Id>();

        Map<Id,List<Integer>> quoteIdToYearsToCreateGroups = new Map<Id,List<Integer>>();

        for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>)Trigger.new) {

            if(quote.msaUpload__c && quote.Multiple_Years_Commitment__c) {

                CventMyd_LineAndGroupHandler.quoteIdToQuoteWrapper.put(quote.Id,new CventMyd_LineAndGroupHandler.QuoteWrapper(quote));

                quoteIdToYearsToCreateGroups.put(quote.Id,getYearsSorted(quote));

            }            

            else if( quote.SBQQ__Type__c == 'Renewal' && !quote.msaUpload__c && ContractTrgHelperCls.contractIdsBeingRenewed.isEmpty() && (System.isFuture() || CventMyd_ContractGenerationMonitor.isRunning) ) {

                if(System.isFuture() && !CventMyd_ContractGenerationMonitor.isRunning) {

                    System.debug('DISABLING CPQ TRIGGERS');

                    SBQQ.TriggerControl.disable();

                    disabledCpqTriggers = true;

                }

                quoteIdsToDelete.add(quote.Id);

            }

            else if(quote.Cloned_From_Quote__c == null && !quote.msaUpload__c) {

                CventMyd_QuoteObject quoteObject = CventMyd_UtilityMethods.getQuoteObject(quote);        

                CpqAudit__c auditRecord = CventMyd_UtilityMethods.getAuditRecord(quote,true,apexLimitsString);

                if(quote.SBQQ__Type__c == 'Amendment' || quote.SBQQ__Type__c == 'Renewal' && quote.SBQQ__Opportunity2__c != null) {

                    Opportunity opportunity = quoteInsertionIdToOpportunity.get(quoteObject.insertionId);

                    auditRecord.contract__c = (quote.SBQQ__Type__c == 'Amendment') ? opportunity.SBQQ__AmendedContract__c : opportunity.SBQQ__RenewedContract__c;

                    auditRecord.chainMaster__c = (renewalChainMasterId != null) ? renewalChainMasterId : amendmentChainMasterId ;

                }

                auditRecords.add(auditRecord);

                newQuoteIds.add(quote.Id);

            }

        }

        List<SBQQ__QuoteLineGroup__c> quoteLineGroups = CventMyd_LineAndGroupHandler.getMydQuoteLineGroups(quoteIdToYearsToCreateGroups,true);

        System.debug('quoteLineGroups: ' + quoteLineGroups);

        if(quoteLineGroups.size() > 0) {

            for(SBQQ__QuoteLineGroup__c qlg : quoteLineGroups) {

                Id quoteId = qlg.SBQQ__Quote__c;

                SBQQ__Quote__c quote = (SBQQ__Quote__c)Trigger.newMap.get(quoteId);

                Map<Integer,CventMyd_Outyear> yearToDates = getFullYearToDatesMap(quote);

                Integer year = (Integer)qlg.term__c;

                qlg.SBQQ__StartDate__c = yearToDates.get(year).startDate;

                qlg.SBQQ__EndDate__c = yearToDates.get(year).endDate;

                qlg.termLength__c = quote.Contract_Term_Years__c;

            }

            insert quoteLineGroups;

        }
        
        if(auditRecords.size() > 0) {
            
            insert auditRecords;
            
            for(CpqAudit__c auditRecord : auditRecords) {quoteIdToInsertionAuditRecord.put(auditRecord.quote__c,auditRecord);}
            
        }

        if(quoteIdsToDelete.size() > 0) {

            System.debug('SCHEDULING JOB TO DELETE GHOST QUOTES');

            String jobName = 'GHOST QUOTE DELETION: ' + CventMyd_UtilityMethods.getFormattedDateTimeString(DateTime.now(),true,false);

            CventMyd_DeleteGhostQuotes deleteGhostQuotes = new CventMyd_DeleteGhostQuotes(quoteIdsToDelete,jobName);

            String cronString = CventMyd_UtilityMethods.getCronString(20);

            String jobIdString = System.schedule(jobName,cronString,deleteGhostQuotes);

            System.debug('jobIdString: ' + jobIdString);
            
        }

    }

    public static Map<Integer,CventMyd_Outyear> getFullYearToDatesMap(SBQQ__Quote__c quote) {

        CventMyd_QuoteObject quoteObject = CventMyd_UtilityMethods.getQuoteObject(quote);

        Map<Integer,CventMyd_Outyear> yearToDates = quoteObject.outyearMap.clone();

        CventMyd_Outyear currentYear = new CventMyd_Outyear();

        currentYear.startDate = quote.SBQQ__StartDate__c;

        currentYear.endDate = quote.SBQQ__EndDate__c;

        yearToDates.put((Integer)quote.Current_Year__c,currentYear);

        return yearToDates;  

    }

    public static List<Integer> getYearsSorted(SBQQ__Quote__c quote) {

        Map<Integer,CventMyd_Outyear> yearToDates = getFullYearToDatesMap(quote);

        List<Integer> yearsSorted = new List<Integer>(yearToDates.keySet());

        yearsSorted.sort();

        System.debug('yearsSorted: ' + yearsSorted);

        return yearsSorted;

    }

    public static Integer getDaysBetween(Date startDate, Date endDate) {

        Integer daysBetween = startDate.daysBetween(endDate);

        daysBetween++;

        if(Date.isLeapYear(endDate.year())) {

            if(endDate.month() > 2 || endDate.month() == 2 && endDate.day() == 29) {

                daysBetween--;

            }

        }

        return daysBetween;

    }

    public static void handleBeforeUpdate() {

        checkForAmendedContract();

        for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>)Trigger.new) {

            System.debug('quote.Year_2_End_Date__c: ' + quote.Year_2_End_Date__c);

            System.debug('quote.Year_3_End_Date__c: ' + quote.Year_3_End_Date__c);

            System.debug('quote.Year_4_End_Date__c: ' + quote.Year_4_End_Date__c);

            System.debug('quote.Year_5_End_Date__c: ' + quote.Year_5_End_Date__c);

            if(quote.Multiple_Years_Commitment__c && quote.msaUpload__c) {

                quote.SBQQ__LineItemsGrouped__c = true;

            }             

            try {

                Integer finalYear = Integer.valueOf(quote.Contract_Term_Years__c);

                String outyearDatesVerbiage = '';

                Boolean nonStandardYears = false;

                Boolean populateDatesVerbiage = false;

                if(finalYear > quote.Current_Year__c && quote.jsonString__c != null) {

                    CventMyd_QuoteObject quoteObject = CventMyd_UtilityMethods.getQuoteObject(quote);

                    Map<Integer,CventMyd_Outyear> yearToDates = quoteObject.outyearMap.clone();

                    CventMyd_Outyear currentYear = new CventMyd_Outyear();

                    currentYear.startDate = quote.SBQQ__StartDate__c;

                    currentYear.endDate = quote.SBQQ__EndDate__c;

                    yearToDates.put((Integer)quote.Current_Year__c,currentYear);

                    List<Integer> yearsSorted = new List<Integer>(yearToDates.keySet());

                    yearsSorted.sort();

                    for(Integer year : yearsSorted) {

                        System.debug('year: ' + year);

                        Date startDate = yearToDates.get(year).startDate;

                        Date endDate = yearToDates.get(year).endDate;

                        Integer daysBetween = getDaysBetween(startDate,endDate);

                        System.debug('daysBetween: ' + daysBetween);

                        outyearDatesVerbiage += '• YEAR ' + String.valueOf(year) + ': ';

                        outyearDatesVerbiage += startDate.format();

                        outyearDatesVerbiage += ' to ' + endDate.format();

                        outyearDatesVerbiage += '\r\n';

                        if(daysBetween != 365) {populateDatesVerbiage = true;}

                    }

                }

                quote.outyearDatesVerbiage__c = (populateDatesVerbiage) ? outyearDatesVerbiage : '';

            }

            catch(Exception e) {

                System.debug('In general it is bad practice to just catch and debug exceptions... here it should be ok: ' + CventMyd_UtilityMethods.getExceptionString(e));

            }

        }

    }

    public static void handleAfterUpdate() {

        System.debug('#####CventMyd_QuoteTriggerHandler.handleAfterUpdate()#####');

        if(quoteInsertionIdToOpportunity.keySet().size() > 0) {

           quoteInsertionIdToOpportunity = getUpdatedQuoteToOpportunityMap(quoteInsertionIdToOpportunity);

        }

        Set<Id> quoteIdsToGroupByCurrentYear = new Set<Id>();

        Set<Id> quoteIdsToRoute = new Set<Id>();

        List<CpqAudit__c> insertionAuditRecordsToUpdate = new List<CpqAudit__c>();

        String apexLimitsString = CventMyd_UtilityMethods.getApexLimitsString();    

        Boolean updatePreviousQuotes = false;  

        for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>)Trigger.new) {

            System.debug('quote.Year_2_End_Date__c: ' + quote.Year_2_End_Date__c);

            System.debug('quote.Year_3_End_Date__c: ' + quote.Year_2_End_Date__c);

            System.debug('quote.Year_4_End_Date__c: ' + quote.Year_2_End_Date__c);

            System.debug('quote.Year_5_End_Date__c: ' + quote.Year_2_End_Date__c);            

            if(quote.jsonString__c == null) {

                Boolean oldPrimaryBoolean = ((SBQQ__Quote__c)Trigger.oldMap.get(quote.Id)).SBQQ__Primary__c;

                if(oldPrimaryBoolean != true && quote.SBQQ__Primary__c) {

                    String errorMessage = ' You cannot mark this quote as primary.';

                    errorMessage += ' Please use the quote on the opportunity that was migrated for you in the new format, or create a new quote.';

                    quote.addError(errorMessage);

                }

            }            

            else if(quote.previousQuote__c != null && !quoteIdToNextQuote.values().contains(quote.Id) && newQuoteIds.contains(quote.Id)) {

                updatePreviousQuotes = true;

                quoteIdToNextQuote.put(quote.previousQuote__c,quote.Id);

            }

        }           

        if(updatePreviousQuotes && !(System.isFuture() && CventMyd_ContractAmendmentController.contractIdsBeingAmended.isEmpty())) {

            CventMyd_UtilityMethods.updatePreviousQuotes(quoteIdToNextQuote);

        }            

        for(SBQQ__Quote__c quote : (List<SBQQ__Quote__c>)Trigger.new) {

            if(quote.Cloned_From_Quote__c == null && !quote.msaUpload__c && quote.jsonString__c != null && (quote.SBQQ__Type__c == 'Renewal' || quote.SBQQ__Type__c == 'Amendment')) {
                
                CventMyd_QuoteObject quoteObject = CventMyd_UtilityMethods.getQuoteObject(quote);
                
                Opportunity opportunity = quoteInsertionIdToOpportunity.get(quoteObject.insertionId);
                
                Boolean renewalQuoted = (opportunity != null && opportunity.SBQQ__RenewedContract__r != null) ? opportunity.SBQQ__RenewedContract__r.SBQQ__RenewalQuoted__c : false;

                Boolean renewalForecast = (opportunity != null && opportunity.SBQQ__RenewedContract__r != null) ? opportunity.SBQQ__RenewedContract__r.SBQQ__RenewalForecast__c : false;

                Boolean isRenewal = (renewalQuoted && !renewalForecast || renewalQuoted && renewalForecast);

                Boolean isAmendment = (quote.SBQQ__Type__c == 'Amendment');

                Boolean outyearProcessingComplete = quote.jsonString__c.contains('OUTYEAR_PROCESSING_COMPLETE');

                Boolean lastUpdatedByTrigger = quote.jsonString__c.contains('LAST_UPDATED_BY_TRIGGER');

                Boolean newAmendmentOrRenewal = ( (isRenewal || isAmendment) && lastUpdatedByTrigger);

                if(newAmendmentOrRenewal && quote.Multiple_Years_Commitment__c) {

                    quoteIdsToGroupByCurrentYear.add(quote.Id);

                }

                if(!outyearProcessingComplete && newQuoteIds.contains(quote.Id)) {

                    quoteIdsToRoute.add(quote.Id);

                }

            }
            
            CpqAudit__c insertionAuditRecord = quoteIdToInsertionAuditRecord.get(quote.Id);

            if(insertionAuditRecord != null) {

                insertionAuditRecord.processingInformation__c += '\r\n' + '==================================================';

                insertionAuditRecord.processingInformation__c += '\r\n' + 'After update trigger fire limits: ' + '\r\n' + apexLimitsString;

                insertionAuditRecordsToUpdate.add(insertionAuditRecord);

            }
            
        }

        if(insertionAuditRecordsToUpdate.size() > 0) {

          update insertionAuditRecordsToUpdate;

        }

        System.debug('quoteIdsToGroupByCurrentYear: ' + quoteIdsToGroupByCurrentYear);

        if(quoteIdsToGroupByCurrentYear.size() > 0) {

            CventMyd_LineAndGroupHandler.groupCurrentYearQuoteLines(quoteIdsToGroupByCurrentYear);

        }

        if(quoteIdsToRoute.size() > 0) {

            CventMyd_QuoteRouter.routeQuotes(quoteIdsToRoute);

        }

    }

}