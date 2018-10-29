global without sharing class CventMyd_UtilityMethods {

    public static final String newLine = '\r\n';

    public static Map<Id,List<Opportunity>> contractIdToRenewalOpportunities = new Map<Id,List<Opportunity>>();

    public static List<String> getListOfStrings(String stringToSplit) {

        List<String> stringList = new List<String>();

        Integer i = 0;

        if(stringToSplit != null) {

            while(i < stringToSplit.length()) {
                        
                if(stringToSplit.charAt(i) == 10 || stringToSplit.charAt(i) == 13) {

                    stringToSplit = stringToSplit.replace(stringToSplit.subString(i,i+1),';');

                    Integer lengthBefore = stringToSplit.length();

                    stringToSplit = stringToSplit.replace(';;',';');

                    Integer lengthAfter = stringToSplit.length();

                    if(lengthAfter < lengthBefore) {i = i - 1;}

                }

                i = i + 1; 

            }

            stringList = stringToSplit.split(';');

        }

        if(stringList.isEmpty()) {stringList.add('');}
        
        return stringList;

    }

    public static Map<Integer,String> getStandardYearToEndDateFieldMap(SObject record) {

        Map<Integer,String> yearToEndDateFieldMap = new Map<Integer,String>();

        String objectName = String.valueOf(record.getSObjectType());

        String currentYearEndDateFieldName = (objectName == 'SBQQ__Quote__c') ? 'SBQQ__EndDate__c' : 'EndDate';

        yearToEndDateFieldMap.put(1,currentYearEndDateFieldName);

        yearToEndDateFieldMap.put(2,'Year_2_End_Date__c');

        yearToEndDateFieldMap.put(3,'Year_3_End_Date__c');

        yearToEndDateFieldMap.put(4,'Year_4_End_Date__c');

        yearToEndDateFieldMap.put(5,'Year_5_End_Date__c');

        return yearToEndDateFieldMap;

    }

    public static List<String> getEndDateFieldNames(SObject record) {
        
        List<String> endDateFieldNames = new List<String>();
        
        String objectName = String.valueOf(record.getSObjectType());
        
        endDateFieldNames.add( (objectName == 'SBQQ__Quote__c') ? 'SBQQ__EndDate__c' : 'EndDate' );
        
        for(Integer i = 2; i <=5; i++) {endDateFieldNames.add('Year_' + i + '_End_Date__c');}
        
        return endDateFieldNames;
        
    }      

    public static Map<Integer,String> getYearToEndDateFieldName(SObject record) {
        
        String objectName = String.valueOf(record.getSObjectType());
        
        Boolean parentContract = (objectName == 'Contract' && String.valueOf(record.get('recordTypeName__c')) == 'Parent Contract');
        
        Boolean newQuote = (objectName == 'SBQQ__Quote__c' && Integer.valueOf(record.get('Current_Year__c')) == 1);
        
        if(parentContract || newQuote) {
            
            return getStandardYearToEndDateFieldMap(record);
            
        }
        
        else {
            
            Integer currentYear = Integer.valueOf(record.get('Current_Year__c'));

            Integer finalYear = Integer.valueOf( (objectName == 'SBQQ__Quote__c') ? record.get('Contract_Term_Years__c') : record.get('Parent_Contract_Term_Years__c') );
            
            Map<Integer,String> yearToEndDateFieldName = new Map <Integer,String>();

            system.debug('this is the final year: ' + finalYear);

            system.debug('this is the current year: ' + currentYear);

            for(Integer i = 0; i <= (finalYear - currentYear) ; i++) {

                Integer year = i + currentYear;

                yearToEndDateFieldName.put(year,getEndDateFieldNames(record)[i]);

            }

            return yearToEndDateFieldName;
            
        }
        
    }

    public static Map<Integer,CventMyd_Outyear> getOutYearMap(SObject record) {

        Map<Integer,CventMyd_Outyear> outyearMap = new Map<Integer,CventMyd_Outyear>();

        String objectName = String.valueOf(record.getSObjectType());

        Integer currentYear = Integer.valueOf(record.get('Current_Year__c'));

        Integer finalYear = Integer.valueOf( (objectName == 'SBQQ__Quote__c') ? record.get('Contract_Term_Years__c') : record.get('Parent_Contract_Term_Years__c') );

        Map<Integer,String> yearToEndDateFieldName = getYearToEndDateFieldName(record);

        String currentYearEndDateFieldName = yearToEndDateFieldName.get(currentYear);

        System.debug('currentYearEndDateFieldName: ' + currentYearEndDateFieldName);

        Date previousYearEndDate = Date.valueOf(record.get(currentYearEndDateFieldName));

        System.debug('previousYearEndDate: ' + previousYearEndDate);

        for(Integer year = currentYear + 1; year <= finalYear; year++) {

            CventMyd_Outyear outyear = new CventMyd_Outyear();

            outyear.startDate = Date.today();

            System.debug('year: ' + year);

            System.debug('previousYearEndDate: ' + previousYearEndDate);

            outyear.startDate = previousYearEndDate.addDays(1);

            String endDateFieldName = String.valueOf(yearToEndDateFieldName.get(year));

            System.debug('endDateFieldName: ' + endDateFieldName);

            Date endDateFieldValue = Date.valueOf(record.get(endDateFieldName));

            System.debug('endDateFieldValue: ' + endDateFieldValue);

            if(endDateFieldValue == null) {

                if(objectName == 'Contract' && String.valueOf(record.get('recordTypeName__c')) == 'Child Contract') {

                    SObject parentContractRecord = (SObject)((Contract)record).Parent_Contract__r;

                    endDateFieldValue = Date.valueOf(parentContractRecord.get(getStandardYearToEndDateFieldMap(parentContractRecord).get(year)));

                    System.debug('endDateFieldValue from parent contract: ' + endDateFieldValue);

                }
                
                if(endDateFieldValue == null) {

                    endDateFieldValue = outyear.startDate.addMonths(12);

                    endDateFieldValue = endDateFieldValue.addDays(-1);

                }

            }

            outyear.endDate = endDateFieldValue;

            previousYearEndDate = outyear.endDate;

            outyearMap.put(year,outyear);

        }

        System.debug('outyearMap: ' + JSON.serialize(outyearMap));

        return outyearMap;

    }

    public static String getApexContext() {

        if(System.isBatch()) {return 'Batch';}

        else if(System.isQueueable()) {return 'Queueable';}

        else if(System.isScheduled()) {return 'Schedulable';}

        else if(System.isFuture()) {return 'Future';}

        else {return 'Synchronous';}

    }    

    public static Map<String,Long> getApexLimitsMap() {

        Map<String,Long> apexLimitsMap = new Map<String,Long>();

        apexLimitsMap.put('SOQL Queries', (Long)Limits.getQueries());

        apexLimitsMap.put('Query Rows', (Long)Limits.getQueryRows());

        apexLimitsMap.put('DML Statements', (Long)Limits.getDMLStatements());

        apexLimitsMap.put('DML Rows', (Long)Limits.getDMLRows());

        apexLimitsMap.put('CPU MS', (Long)Limits.getCpuTime());

        apexLimitsMap.put('Heap Size Bytes', (Long)Limits.getHeapSize());

        apexLimitsMap.put('Callouts', (Long)Limits.getCallouts());

        apexLimitsMap.put('Future Calls', (Long)Limits.getFutureCalls());

        apexLimitsMap.put('Queueable Jobs', (Long)Limits.getQueueableJobs());

        return apexLimitsMap;

    }

    public static String getApexLimitsString() {

        String apexLimitsString = ''; Map<String,Long> apexLimitsMap = getApexLimitsMap();

        for(String apexLimit : apexLimitsMap.keySet()) {

            apexLimitsString += apexLimit + ': ' + apexLimitsMap.get(apexLimit) + '\r\n';

        }

        apexLimitsString = apexLimitsString.substringBeforeLast('\r\n');

        return apexLimitsString;        

    }

    public static void updatePreviousQuotes(Map<Id,Id> quoteIdToNextQuote) {

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();

        for(Id quoteId : quoteIdToNextQuote.keySet()) {

            quotes.add(new SBQQ__Quote__c(Id= quoteId, nextQuote__c = quoteIdToNextQuote.get(quoteId)));

        }

        update quotes;

    }        

    public static void updateSubscriptionsAfterAmendment(Set<Id> amendmentQuoteIds) {

        System.debug('have triggers been disabled from quote trigger: ' + CventMyd_QuoteTriggerHandler.disabledCpqTriggers);

        Boolean areCpqTriggersActive = SBQQ.TriggerControl.isEnabled();

        System.debug('are CPQ triggers actually active: ' + areCpqTriggersActive);

        List<SBQQ__Subscription__c> subscriptionsToUpdate = new List<SBQQ__Subscription__c>();

        for(SBQQ__Quote__c quote : [SELECT

            Id,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.SBQQ__AmendedContract__c,

            SBQQ__Opportunity2__r.SBQQ__Contracted__c,SBQQ__Type__c,

            Multiple_Years_Commitment__c,createdFromLegacyContract__c,

            SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.Current_Year__c,

            (SELECT Id,jsonString__c,SBQQ__UpgradedSubscription__c,SBQQ__Quantity__c,

            legacySubscription__c,term__c,SBQQ__Optional__c,

            legacySubscription__r.Id,

            legacySubscription__r.SBQQ__Quantity__c,

            legacySubscription__r.Year_2_Quantity_X__c, 

            legacySubscription__r.Year_3_Quantity_X__c,

            legacySubscription__r.Year_4_Quantity_X__c,

            legacySubscription__r.Year_5_Quantity_X__c

            FROM SBQQ__LineItems__r

            WHERE ( SBQQ__UpgradedSubscription__c != null AND SBQQ__Optional__c = false ) OR ( legacySubscription__c != null AND SBQQ__Optional__c = true AND legacySubscription__r.SBQQ__RenewalQuantity__c != 0) )

            FROM SBQQ__Quote__c

            WHERE Id IN: amendmentQuoteIds

                AND SBQQ__Type__c = 'Amendment'

                AND SBQQ__Opportunity2__r.SBQQ__Contracted__c = TRUE

        ]) {

            Contract contract = quote.SBQQ__Opportunity2__r.SBQQ__AmendedContract__r;

            for(SBQQ__QuoteLine__c ql : quote.SBQQ__LineItems__r) {

                SBQQ__Subscription__c subscription;

                if(!CventMyd_ContractGenerationMonitor.isRunning && ql.SBQQ__UpgradedSubscription__c != null && !ql.SBQQ__Optional__c) {

                    subscription = new SBQQ__Subscription__c(Id = ql.SBQQ__UpgradedSubscription__c,jsonString__c = ql.jsonString__c);

                    subscriptionsToUpdate.add(subscription);

                }

                else if(CventMyd_ContractGenerationMonitor.isRunning && ql.legacySubscription__c != null && ql.SBQQ__Optional__c && quote.Multiple_Years_Commitment__c && quote.createdFromLegacyContract__c) {

                    System.debug('FOUND ql with legacy subscription populated: ' + ql.Id);

                    subscription = ql.legacySubscription__r;

                    if(subscription.SBQQ__Quantity__c == 0) {

                        System.debug('quantity on the legacy sub is zero: ' + subscription.Id);

                        Integer currentYear = (Integer)contract.Current_Year__c;   

                        System.debug('current year is: ' + currentYear);

                        Integer year = (Integer)ql.term__c;

                        Integer yearNumber = year - currentYear + 1;

                        String yearFieldName = 'Year_' + String.valueOf(yearNumber) + '_Quantity_X__c';

                        System.debug('yearFieldNam e is: ' + yearFieldName);

                        Decimal yearQuantityDec = (Decimal)subscription.get(yearFieldName);

                        Integer yearQuantity = (yearQuantityDec != null) ? (Integer)yearQuantityDec : null;

                        System.debug('yearQuantity is: ' + yearQuantity);

                        if(yearQuantity != null && yearQuantity != 0) {

                            Map<Id,SBQQ__Subscription__c> subscriptionMap = new Map<Id,SBQQ__Subscription__c>(subscriptionsToUpdate);

                            if(!subscriptionMap.containsKey(subscription.Id)) {

                                subscription = new SBQQ__Subscription__c(Id = ql.legacySubscription__c,SBQQ__RenewalQuantity__c = 0);

                                System.debug('adding sub to update: ' + subscription);

                                subscriptionsToUpdate.add(subscription);

                            }

                        }

                    }

                }

            }

        }

        if(subscriptionsToUpdate.size() > 0) {

            update subscriptionsToUpdate;

        }

    }

    public static CventMyd_RecalculationWrapper getRecalculationWrapper(Set<Id> quoteIds, Boolean forceRecalculation) {

        CventMyd_RecalculationWrapper recalculationWrapper = new CventMyd_RecalculationWrapper();

        recalculationWrapper.mapOfQuotesToRecalculate = new Map<Id,Boolean>();

        recalculationWrapper.opportunityIdToPrimaryQuoteId = new Map<Id,Id>();

        recalculationWrapper.quotes = new List<SBQQ__Quote__c>();

        for(SBQQ__Quote__c quote : [SELECT               

            SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.contractedAmendmentQuote__c,

            Id,recalculationToggler__c,jsonString__c,SBQQ__Opportunity2__c,SBQQ__Type__c,

            SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c,SBQQ__Primary__c,isLockedIntratermRenewal__c

            FROM SBQQ__Quote__c

            WHERE Id IN: quoteIds

        ]) {

            recalculationWrapper.quotes.add(quote);

            CventMyd_QuoteObject quoteObject = (CventMyd_QuoteObject)JSON.deserialize(quote.jsonString__c,CventMyd_QuoteObject.class);

            Boolean outyearProcessingComplete = (quoteObject.automationStage.outyearProcessingStage == CventMyd_QuoteAutomationStage.OutyearProcessingStage.OUTYEAR_PROCESSING_COMPLETE);

            if(!outyearProcessingComplete || forceRecalculation) {

                if(quote.recalculationToggler__c) {

                    recalculationWrapper.mapOfQuotesToRecalculate.put(quote.Id,false);

                }

                else if(!quote.recalculationToggler__c) {

                    recalculationWrapper.mapOfQuotesToRecalculate.put(quote.Id,true);

                }

            }

            if(quote.SBQQ__Primary__c && quote.SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c == null) {

                recalculationWrapper.opportunityIdToPrimaryQuoteId.put(quote.SBQQ__Opportunity2__c,quote.Id);

            }

        }

        return recalculationWrapper;

    }

    // method that takes in a map of Id --> boolean and returns a list of quotes to recalculate

    public static List<SBQQ__Quote__c> getListOfQuotesToRecalculate(Map<Id,Boolean> mapOfQuotesToRecalculate) {

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();

        for(Id quoteId : mapOfQuotesToRecalculate.keySet()) {

            quotes.add(new SBQQ__Quote__c(Id= quoteId, recalculationToggler__c = mapOfQuotesToRecalculate.get(quoteId) ));

        }

        return quotes;

    }    

    // method that takes in a map of opportunity Id --> quote Id and returns a list of opportunities to update primary quote

    public static List<Opportunity> getOpportunitiesToUpdatePrimaryQuote(Map<Id,Id> opportunityIdToPrimaryQuoteId) {

        List<Opportunity> opportunities = new List<Opportunity>();

        for(Id oppId : opportunityIdToPrimaryQuoteId.keySet()) {

            opportunities.add(new Opportunity(Id= oppId, SBQQ__PrimaryQuote__c = opportunityIdToPrimaryQuoteId.get(oppId) ));

        }

        return opportunities;

    }

    // method that takes in a set of quote ids and recalculates quotes where appropriate 

    @future

    public static void recalculateQuotes(Set<Id> quoteIds, Boolean forceRecalculation) {

        CventMyd_RecalculationWrapper recalculationWrapper = getRecalculationWrapper(quoteIds,forceRecalculation);

        List<SBQQ__Quote__c> quotesToRecalculate = getListOfQuotesToRecalculate(recalculationWrapper.mapOfQuotesToRecalculate);

        if(quotesToRecalculate.size() > 0) {

            update quotesToRecalculate;

        }

    }    

    // method that takes in a set of quote ids and updates opportunites where the primary quote field is null

    @future

    public static void updatePrimaryQuoteFieldOnOpportunities(Set<Id> quoteIds, Boolean forceRecalculation) {

        CventMyd_RecalculationWrapper recalculationWrapper = getRecalculationWrapper(quoteIds,forceRecalculation);

        List<Opportunity> opportunitiesToUpdate = getOpportunitiesToUpdatePrimaryQuote(recalculationWrapper.opportunityIdToPrimaryQuoteId);

        if(opportunitiesToUpdate.size() > 0) {

            update opportunitiesToUpdate;

        }

    }

    // method that aborts all scheduled variable apex jobs for a given set of quote ids

    @future

    public static void uncheckPrimaryOnQuotes(Set<Id> quoteIds) {

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();

        List<SBQQ__Quote__c> existingQuotes = [SELECT Id,SBQQ__Primary__c FROM SBQQ__Quote__c WHERE IsDeleted = FALSE AND Id IN: quoteIds];

        for(SBQQ__Quote__c quote : existingQuotes) {

            if(quote.SBQQ__Primary__c) {

                quotes.add(new SBQQ__Quote__c(Id= quote.Id, SBQQ__Primary__c = false));

            }

        }

        update quotes;

    }

    public static Map<String,Boolean> getQuoteStatusMap(CventMyd_QuoteObject quoteObject) {

        Map<String,Boolean> quoteStatusMap = new Map<String,Boolean>();

        quoteStatusMap.put('lastUpdatedByTrigger',

        (quoteObject.automationStage.codeStatus == CventMyd_QuoteAutomationStage.CodeStatus.LAST_UPDATED_BY_TRIGGER));

        quoteStatusMap.put('calculationCycleFinished',

        (quoteObject.automationStage.codeStatus == CventMyd_QuoteAutomationStage.CodeStatus.CALCULATION_CYCLE_FINISHED));

        quoteStatusMap.put('outyearProcessingInProgress',

        (quoteObject.automationStage.outyearProcessingStage == CventMyd_QuoteAutomationStage.OutyearProcessingStage.OUTYEAR_PROCESSING_IN_PROGRESS));

        quoteStatusMap.put('outyearProcessingComplete',

        (quoteObject.automationStage.outyearProcessingStage == CventMyd_QuoteAutomationStage.OutyearProcessingStage.OUTYEAR_PROCESSING_COMPLETE));

        quoteStatusMap.put('currentYearFinished',

        (quoteObject.automationStage.outyearProcessingStage == CventMyd_QuoteAutomationStage.OutyearProcessingStage.CURRENT_YEAR_FINISHED));

        quoteStatusMap.put('newlyInsertedVariable',

        (quoteObject.automationStage.outyearProcessingStage == CventMyd_QuoteAutomationStage.OutyearProcessingStage.NEWLY_INSERTED_VARIABLE));

        quoteStatusMap.put('newlyInsertedNonVariable',

        (quoteObject.automationStage.outyearProcessingStage == CventMyd_QuoteAutomationStage.OutyearProcessingStage.NEWLY_INSERTED_NON_VARIABLE));        

        return quoteStatusMap;

    }

    public static Map<String,Boolean> getQuoteStatusMap(SBQQ__Quote__c quote) {

        CventMyd_QuoteObject quoteObject = getQuoteObject(quote);

        return getQuoteStatusMap(quoteObject);

    }    

    public static CventMyd_QuoteObject getQuoteObject(SBQQ__Quote__c quote) {
       
        if(quote.jsonString__c != null) {

            return (CventMyd_QuoteObject)JSON.deserialize(quote.jsonString__c,CventMyd_QuoteObject.class);

        }

        else {

            return null;

        }

    }

    public static CventMyd_QuoteLineObject getQuoteLineObject(SBQQ__QuoteLine__c quoteLine) {

        return (CventMyd_QuoteLineObject)JSON.deserialize(quoteLine.jsonString__c,CventMyd_QuoteLineObject.class);

    }

    public static List<Integer> getQuoteOutyears(SBQQ__Quote__c quote, Boolean getAllYears) {

        List<Integer> years = new List<Integer>();

        if(quote.Multiple_Years_Commitment__c) {

            Integer firstYear = (quote.SBQQ__Type__c == 'Renewal') ? (Integer)quote.Current_Year__c : (Integer)quote.Current_Year__c + 1;

            if(getAllYears) {

                Integer finalYear = Integer.valueOf(quote.Contract_Term_Years__c);

                for(Integer year = firstYear; year <= finalYear; year++) {years.add(year);}

            }

            else if(quote.SBQQ__Type__c == 'Renewal') {years.add(firstYear);}

        }

        return years;

    }

    public static Map<Id,List<Integer>> getQuoteIdToAllOutyears(List<SBQQ__Quote__c> quotes) {

        Map<Id,List<Integer>>   quoteIdToOutyears = new Map<Id,List<Integer>>();

        for(SBQQ__Quote__c quote : quotes) {

            quoteIdToOutyears.put(quote.Id,getQuoteOutyears(quote,true));

        }

        return quoteIdToOutyears;

    }

    public static Integer getExpectedNumberOfQuoteLineGroups(SBQQ__Quote__c quote) {

        List<Integer> outyears = getQuoteOutyears(quote,true);

        return (quote.SBQQ__Type__c == 'Amendment') ? outyears.size() + 1 : outyears.size() ;

    }

    public static CpqAudit__c getAuditRecord(SBQQ__Quote__c quote, Boolean isInsertion, String apexLimitsString) {

        CpqAudit__c auditRecord = new CpqAudit__c(quote__c = quote.Id);

        auditRecord.Name = quote.Name + ( ( (quote.createdFromLegacyContract__c)) ? ' Legacy' : '') + ((isInsertion) ? ' insertion' : ' status check');

        auditRecord.Name += '; Type: ' + quote.SBQQ__Type__c;

        auditRecord.Name += (quote.Multiple_Years_Commitment__c) ? ', Variable' : ', Non-Variable';

        auditRecord.Name += '; Cloned: ' + String.valueOf(quote.SBQQ__Source__c != null);

        auditRecord.processingInformation__c = '==================================================';

        auditRecord.processingInformation__c += '\r\n' + 'Apex Context: ' + CventMyd_UtilityMethods.getApexContext();

        auditRecord.processingInformation__c += '\r\n' + 'Limits after insertion: ' + '\r\n' + apexLimitsString;

        auditRecord.processingInformation__c += '\r\n' + 'Trigger Size: ' + Trigger.size;

        auditRecord.processingInformation__c += '\r\n' + '==================================================';

        auditRecord.processingInformation__c += '\r\n' + 'User Id: ' + UserInfo.getUserId();

        auditRecord.processingInformation__c += '\r\n' + 'User Name: ' + UserInfo.getName();

        auditRecord.processingInformation__c += '\r\n' + 'User Email: ' + UserInfo.getUserEmail();

        auditRecord.processingInformation__c += '\r\n' + 'Time Zone: ' + UserInfo.getTimeZone();

        CventMyd_QuoteObject quoteObject = (CventMyd_QuoteObject)JSON.deserialize(quote.jsonString__c,CventMyd_QuoteObject.class);

        auditRecord.statusCheckCount__c = quote.statusCheckCount__c;

        auditRecord.outyearProcessingStage__c = String.valueOf(quoteObject.automationStage.outyearProcessingStage);

        auditRecord.statusCheckCount__c = 0;

        return auditRecord;

    }

    // get master chain audit record 

    public static CpqAudit__c getAuditRecord(Id chainMasterRecordId, DateTime scheduledFinishDateTime, String jobName) {

        CpqAudit__c auditRecord;

        if(chainMasterRecordId == null) {

            auditRecord = new CpqAudit__c();

            auditRecord.Name = jobName;

            auditRecord.scheduledFinishTime__c  = scheduledFinishDateTime;

            auditRecord.isChainMaster__c = true;

            auditRecord.jobsInChain__c = (!Test.isRunningTest()) ? 0 : 1 ;

        }

         else if(chainMasterRecordId != null) {

            auditRecord = [SELECT

                Id,jobsInChain__c,processingInformation__c,scheduledFinishTime__c,Name

                FROM CpqAudit__c

                WHERE Id =: chainMasterRecordId

            ];

            auditRecord.jobsInChain__c = auditRecord.jobsInChain__c + 1;

         }

        return auditRecord;

    }

    public static CpqAudit__c getAuditRecord(Id chainMasterRecordId, Id contractId, Id previousChainLinkId) {

        CpqAudit__c auditRecord = new CpqAudit__c(chainMaster__c = chainMasterRecordId, contract__c = contractId);

        auditRecord.Name = getRenewalChainLinkJobName(DateTime.now());

        auditRecord.previousJob__c = previousChainLinkId;

        return auditRecord;

    }

    public static String getRenewalChainLinkJobName(DateTime startDateTime) {

        return 'Renewal Chain Link @ ' + getFormattedDateTimeString(startDateTime,true,true);

    }

    public static String getRenewalChainMasterJobName(DateTime startDateTime, DateTime endDateTime) {

        String jobName = 'Renewal Chain Master ';

        String startTimeString = getFormattedDateTimeString(startDateTime,true,false);

        String yearSubstring = '/' + String.valueOf(endDateTime.year());

        String endTimeString = (getFormattedDateTimeString(endDateTime,true,true)).replace(yearSubstring,'');

        jobName += startTimeString + ' - ' + endTimeString;

        return jobName;

    }

    public static String getFormattedDateTimeString(DateTime dateTimeVar, Boolean showSeconds, Boolean showTimeZone) {

        String dateFormatString = (showSeconds) ? 'MM/dd/yyyy hh:mm:ss aaa' : 'MM/dd/yyyy hh:mm aaa';

        String timeZoneAbbreviation = UserInfo.getTimeZone().getDisplayName();

        timeZoneAbbreviation = timeZoneAbbreviation.replaceAll('\\B.|\\P{L}', '').toUpperCase();

        String timeZoneString = UserInfo.getTimeZone().toString();

        String dateTimeString = dateTimeVar.format(dateFormatString,timeZoneString);

        dateTimeString += (showTimeZone) ? ' ' + timeZoneAbbreviation : '' ;

        return dateTimeString;

    }

    public static void abortSchedulableJobs(Boolean useFuture, String previousJobName, String currentJobName, Boolean abortAllJobs) {

        if(useFuture) {

            abortSchedulableJobsFuture(previousJobName,currentJobName,abortAllJobs);

        }

        else {

            abortSchedulableJobs(previousJobName,currentJobName,abortAllJobs);

        }

    }

    @future

    public static void abortSchedulableJobsFuture(String previousJobName, String currentJobName, Boolean abortAllJobs) {

        abortSchedulableJobs(previousJobName,currentJobName,abortAllJobs);

    }

    public static void abortSchedulableJobs(String previousJobName, String currentJobName, Boolean abortAllJobs) {

        String queryString = 'SELECT Id,CronJobDetail.Name';

        queryString += ' FROM CronTrigger WHERE';

        Set<String> jobNamesToAbort = new Set<String>{previousJobName,currentJobName};

        for(CpqAudit__c auditRecord : [SELECT

            Id,Name,processingInformation__c

            FROM CpqAudit__c WHERE Name LIKE 'Abortion failure%'

            ORDER BY CreatedDate DESC

            LIMIT 5

        ]) {

            for(String jobName : auditRecord.processingInformation__c.split(';')) {

                jobNamesToAbort.add(jobName);

            }

        }

        if(!abortAllJobs) {

            queryString += ' CronJobDetail.Name IN: jobNamesToAbort';

        }

        else if(abortAllJobs) {

            queryString += ' CronJobDetail.NAME LIKE \'Renewal Quote Job Master%\'';

            queryString += ' OR CronJobDetail.NAME LIKE \'Renewal Chain Master%\'';

            queryString += ' OR CronJobDetail.NAME LIKE \'%status check; Type:%\'';

            queryString += ' OR CronJobDetail.NAME LIKE \'Renewal Chain Link%\'';

        }

        List<CronTrigger> cronTriggers = Database.query(queryString);

        try {

            for(CronTrigger cronTrigger : cronTriggers) {

                System.abortJob(cronTrigger.Id);

            }

        }

        catch(Exception e) {

            if(!cronTriggers.isEmpty()) {

                String dateTimeString = getFormattedDateTimeString(DateTime.now(),true,false);

                String jobNameString = '';

                for(CronTrigger cronTrigger : cronTriggers) {

                    jobNameString = cronTrigger.CronJobDetail.Name + ';';

                }

                CpqAudit__c auditRecord = new CpqAudit__c(Name = 'Abortion failure @ ' + dateTimeString);

                auditRecord.processingInformation__c = jobNameString;

                insert auditRecord;                

            }

        }

    }

    public static String getCronString(Integer secondsUntilJobStart) {

        DateTime currentDateTime = System.now();

        DateTime dateTimeForNextJob = currentDateTime.addSeconds(secondsUntilJobStart);

        Integer seconds = dateTimeForNextJob.second();

        Integer minutes = dateTimeForNextJob.minute();

        Integer hours = dateTimeForNextJob.hour();

        Integer dayOfMonth = dateTimeForNextJob.day();

        Integer month = dateTimeForNextJob.month();

        Integer year = dateTimeForNextJob.year();

        String cronString = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ?' + ' ' + year;   

        return cronString;  

    }

    public static Decimal getHoursBetweenDateTimes(DateTime dateTime0, DateTime dateTime1) {

        Long dateTime0Ms = dateTime0.getTime();

        Long dateTime1Ms = dateTime1.getTime();

        Long msDifference = dateTime1Ms - dateTime0Ms;

        Long secondsDifference = msDifference / 1000;
      
        return ((Decimal)secondsDifference).divide(3600,5);

    }
    
    public static String getExceptionString(Exception e) { 

        String apexLimitsString = CventMyd_UtilityMethods.getApexLimitsString();

        String exceptionString = '\r\n' + '==================================================';

        exceptionString += '\r\n'+ '##EXCEPTION##';

        exceptionString += '\r\n' + 'CAUSE: '+ e.getCause();

        exceptionString += '\r\n' + 'MESSAGE: ' + e.getMessage();

        exceptionString += '\r\n' + 'STACK TRACE: ' + e.getStackTraceString();

        exceptionString += '\r\n' + 'TYPE NAME: ' + e.getTypeName();

        exceptionString += '\r\n' + '==================================================';

        exceptionString += '\r\n' + 'Apex Limits: ' + '\r\n';

        exceptionString += apexLimitsString;

        return exceptionString; 

    }    

    @future

    public static void deleteOpportunities(Set<Id> opportunityIds) {

        List<Opportunity> opportunities = new List<Opportunity>();

        for(Id oppId : opportunityIds) {opportunities.add(new Opportunity(Id = oppId));}

        delete opportunities;

    }  

    public static String getQleId() {

        String characterString = 'abcdefghijklmnopqrstuvxwz';

        return getFiveRandomIntegerString() + '_' + getThreeRandomLetterString() + '_' + getFiveRandomIntegerString();

    }

    public static String getFiveRandomIntegerString() {

        String randomIntegerString = '';

        for(Integer i = 0; i < 5; i++) {

            Double randomDouble = Math.random() * (9);

            Integer randomInteger = Math.round(randomDouble);           

            randomIntegerString = randomIntegerString + String.valueOf(randomInteger);

        }

        return randomIntegerString;

    }

    public static String getThreeRandomLetterString() {

        String characterString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

        String randomCharacterString = '';

        for(Integer i = 0; i < 3; i++) {

            Double randomDouble = Math.random() * (characterString.length() - 1);

            Integer randomInteger = Math.round(randomDouble);           

            randomCharacterString = randomCharacterString + characterString.subString(randomInteger,randomInteger + 1);

        }

        return randomCharacterString;

    }

    webservice static void recalculateQuote(Id quoteId) {

        SBQQ__Quote__c quote = [SELECT Id,recalculationToggler__c FROM SBQQ__Quote__c WHERE Id =: quoteId];

        if(quote.recalculationToggler__c) {

          quote.recalculationToggler__c = false;

        }

        else if(!quote.recalculationToggler__c) {

          quote.recalculationToggler__c = true;

        }  

        update quote;  

    }

    webservice static void clearSubscriptionJsonStrings(Id contractId) {

        List<SBQQ__Subscription__c> subscriptions = [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c =: contractId];

        for(SBQQ__Subscription__c subscription : subscriptions) {

            subscription.jsonString__c = null;

        }

        update subscriptions;

    }    

    webservice static void clearSubscriptionJsonStringsAndDeleteRenewal(Id contractId) {

        List<SBQQ__Subscription__c> subscriptions = [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c =: contractId];

        for(SBQQ__Subscription__c subscription : subscriptions) {

            subscription.jsonString__c = null;

        }

        Contract contract = new Contract(Id = contractId, SBQQ__RenewalForecast__c = false, SBQQ__RenewalQuoted__c = false);

        update contract;

        update subscriptions;

        delete [SELECT Id FROM Opportunity WHERE SBQQ__RenewedContract__c =: contractId];

        delete [SELECT Id FROM Opportunity WHERE SBQQ__AmendedContract__c =: contractId];

    }

    webservice static void closeWinOpportunity(Id opportunityId) {

        Opportunity opportunity = new Opportunity(Id = opportunityId, StageName = 'Closed Won');

        update opportunity;

    }

    public class TwinFieldException extends Exception {}

    public static Set<String> getSubscriptionQuoteLineTwinFieldNames() {       

        Map<String,Schema.SObjectField> quoteLineFieldNameToField = Schema.getGlobalDescribe().get('SBQQ__QuoteLine__c').getDescribe().fields.getMap();
    
        Map<String,Schema.SObjectField> subscriptionFieldNameToField = Schema.getGlobalDescribe().get('SBQQ__Subscription__c').getDescribe().fields.getMap();

        Set<String> twinFields = new Set<String>();

        for(String fieldName0 : quoteLineFieldNameToField.keySet()) {

            Schema.SObjectField field = quoteLineFieldNameToField.get(fieldName0);

            String fieldType0 = getFieldType('SBQQ__QuoteLine__c',fieldName0,field);

            Boolean isString0 = (fieldType0 == 'PICKLIST' || fieldType0 == 'STRING');

            for(String fieldName1 : subscriptionFieldNameToField.keySet()) {
            
                if(fieldName0 == fieldName1 && fieldName0.containsIgnoreCase('__c')) {

                    field = subscriptionFieldNameToField.get(fieldName0);
                
                    String fieldType1 = getFieldType('SBQQ__Subscription__c',fieldName1,field);

                    Boolean isString1 = (fieldType1 == 'PICKLIST' || fieldType1 == 'STRING');

                    if(fieldType1 == fieldType0 || isString0 && isString1) {

                        twinFields.add(fieldName0);

                    }

                    else {

                        String exceptionString = 'Quote Line ---> Subscription twin fields should be the same type.';

                        exceptionString += ' For field ' + fieldName0;

                        exceptionString += ', ' + fieldType0 + ' != ' + fieldType1;

                        throw new TwinFieldException(exceptionString);

                    }
                    
                }

            }
            
        }

        return twinFields;   

    }

    public static String getFieldType(String objectName, String fieldName, Schema.SObjectField field) {

        Map<String,Schema.SObjectField> fieldNameToField = (field == null) ? Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap() : null ;

        field = (field != null) ? field : fieldNameToField.get(fieldName);

        Schema.DescribeFieldResult describeFieldResult = field.getDescribe();

        return String.valueOf(describeFieldResult.getType());

    }

    public static String getFieldNamesStringFromStringSet(Set<String> fieldNames) {

        String fieldNamesString = '';

        for(String fieldName : fieldNames) {

            fieldNamesString += fieldName + ',';

        }

        fieldNamesString = fieldNamesString.substringBeforeLast(',');

        return fieldNamesString;

    }

    public static Integer queryScheduledJobCount() {

        Integer scheduledJobCount = [SELECT

            count()

            FROM CronTrigger

            WHERE (STATE = 'waiting' or STATE = 'queued' or STATE = 'executing')

                AND (CronJobDetail.JobType = '7')

        ];

        return scheduledJobCount;

    }

    public static Messaging.SingleEmailMessage getSingleEmailMessage(List<String> additionalToAddresses, String htmlBodyString, String subjectString, String whatId) {

        Messaging.SingleEmailMessage singleEmailMessage = new Messaging.SingleEmailMessage();

        String[] toAddresses = CventMyd_Settings.administratorEmails;

        if(additionalToAddresses != null && !additionalToAddresses.isEmpty()) {

            toAddresses.addAll(additionalToAddresses);

        }

        singleEmailMessage.setToAddresses(toAddresses);

        singleEmailMessage.setWhatId(whatId);

        singleEmailMessage.setSaveAsActivity(false);

        singleEmailMessage.setSubject(subjectString);

        singleEmailMessage.setHtmlBody(htmlBodyString);

        return singleEmailMessage;

    }

    public static void sendEmail(Messaging.SingleEmailMessage singleEmailMessage) {

        Messaging.reserveSingleEmailCapacity(1);

        Messaging.SingleEmailMessage[] singleEmailMessages = new Messaging.SingleEmailMessage[] {singleEmailMessage};

        Messaging.SendEmailResult[] sendEmailResults = Messaging.sendEmail(singleEmailMessages);

    }

    public static String replaceJsonStringWithPricingMethod(String jsonString, SBQQ__Subscription__c subscription) {

        System.debug('jsonString (BEFORE): ' + jsonString);

        String originalJsonTargetSubstring;

        String jsonReplacementSubstring;

        if(!jsonString.containsIgnoreCase('SBQQ__PricingMethod__c')) {

            jsonReplacementSubstring  = '"SBQQ__PricingMethod__c":["' + subscription.SBQQ__PricingMethod__c + '"],';
        
            if(jsonString.contains('nextYearQleId') && !jsonString.contains('"nextYearQleId":null')) {
                
                String targetSubstring = '"' + subscription.SBQQ__PricingMethod__c + '"';
                
                String replacementSubstring = '"' + subscription.SBQQ__PricingMethod__c + '","' + subscription.SBQQ__PricingMethod__c + '"';
            
                jsonReplacementSubstring = jsonReplacementSubstring.replace(targetSubstring,replacementSubstring);
                
            }

            originalJsonTargetSubstring = '"SBQQ__EndDate__c":' ;

            jsonReplacementSubstring += originalJsonTargetSubstring;

        }

        else if(jsonString.containsIgnoreCase('SBQQ__PricingMethod__c')) {

            originalJsonTargetSubstring = jsonString.substringBetween('SBQQ__PricingMethod__c":[',']');

            String originalPricingMethod = getPricingMethodFromJsonString(jsonString);

            System.debug('originalPricingMethod: ' + originalPricingMethod);

            System.debug('subscription.SBQQ__PricingMethod__c: ' + subscription.SBQQ__PricingMethod__c);

            jsonReplacementSubstring = originalJsonTargetSubstring.replaceAll(originalPricingMethod,subscription.SBQQ__PricingMethod__c);

        }

        System.debug('(jsonString != null): ' + (jsonString != null));

        System.debug('(originalJsonTargetSubstring != null): ' + (originalJsonTargetSubstring != null));

        System.debug('(jsonReplacementSubstring != null): ' + (jsonReplacementSubstring != null));
        
        jsonString = jsonString.replace(originalJsonTargetSubstring,jsonReplacementSubstring);

        System.debug('jsonString (AFTER): ' + jsonString);

        return jsonString;

    }

    public static String getPricingMethodFromJsonString(String jsonString) {

        String pricingMethod;

        if(jsonString.containsIgnoreCase('SBQQ__PricingMethod__c')) {

            String substring = jsonString.substringBetween('SBQQ__PricingMethod__c":[',']');

            substring = substring.replace('null','"null"');

            pricingMethod = substring.substringBetween('"');

        }

        return pricingMethod;

    }    

    @future

    public static void updateSubscriptionPricingMethodJson(Integer contractCount, Boolean doUpdate) {

        List<SBQQ__Subscription__c> subscriptions = [SELECT 

            Id,jsonString__c,SBQQ__Contract__c,SBQQ__Product__c,
            
            SBQQ__Contract__r.contractedAmendmentQuote__c,

            SBQQ__Contract__r.isLegacy__c,
            
            SBQQ__PricingMethod__c
            
            FROM SBQQ__Subscription__c
            
            WHERE pricingMethodChanged__c = true

            AND SBQQ__Contract__c != null

            AND SBQQ__TerminatedDate__c = null

            ORDER BY CreatedDate DESC
                    
        ];

        List<DataDump__c> snapShots = new List<DataDump__c>();

        Map<Id,List<SBQQ__Subscription__c>> contractIdToSubscriptions = (Map<Id,List<SBQQ__Subscription__c>>)getParentIdToChildrenRecords(subscriptions,'SBQQ__Contract__c');

        Set<Id> productIds = new Set<Id>();

        Set<Id> quoteIds = new Set<Id>();

        List<SBQQ__Subscription__c> subscriptionsToUpdate = new List<SBQQ__Subscription__c>();

        Integer contractsHandledCount = 0;

        for(Id contractId : contractIdToSubscriptions.keySet()) {

            if(contractsHandledCount < contractCount) {

                Boolean subscriptionFound = false;

                for(SBQQ__Subscription__c subscription : contractIdToSubscriptions.get(contractId)) {
                    
                    Boolean jsonNotNull = (subscription.jsonString__c != null);
                    
                    Boolean jsonHasPricingMethod = ( jsonNotNull && subscription.jsonString__c.containsIgnoreCase('SBQQ__PricingMethod__c') );
                    
                    Boolean jsonWontGetUpdated = (subscription.SBQQ__Contract__r.contractedAmendmentQuote__c != null || subscription.SBQQ__Contract__r.isLegacy__c != true);

                    if(!jsonHasPricingMethod && jsonWontGetUpdated && jsonNotNull) {

                        DataDump__c snapShot = new DataDump__c(subscription__c = subscription.Id,originalJsonString__c = subscription.jsonString__c);

                        snapShots.add(snapShot);

                        subscription.jsonString__c = replaceJsonStringWithPricingMethod(subscription.jsonString__c,subscription);

                        subscriptionsToUpdate.add(subscription);

                        subscriptionFound = true;

                    }

                }

                contractsHandledCount += (subscriptionFound) ? 1 : 0;
                
            }

            else {

                break;

            }

        }

        System.debug('contractsHandledCount: ' + contractsHandledCount);

        System.debug('subscriptionsToUpdate.size(): ' + subscriptionsToUpdate.size());

        Set<Id> contractIds = getIdSet(subscriptionsToUpdate,'SBQQ__Contract__c');

        String contractIdString = getIdString(contractIds,';');

        System.debug('contractIdString: ' + contractIdString);

        if(subscriptionsToUpdate.size() > 0 && doUpdate) {

            if(SBQQ.TriggerControl.isEnabled()) {SBQQ.TriggerControl.disable();}

            insert snapShots;

            update subscriptionsToUpdate;

        } 

    }

    public class JsonUpdateException extends Exception {}

    @future

    public static void updateQuoteLinePricingMethodJson(Set<Id> quoteIds, Integer quoteCount, Boolean doOpen, Boolean doClosed, Boolean doUpdate, Boolean takeSnapShots) {

        // Integer queryLimit = quoteCount * 250;

       if(quoteIds != null && (quoteCount != null || doClosed != null || doOpen != null) ) {

            throw new JsonUpdateException('If you specify quote Ids, you must not define other parameters specifying quotes to include.');

        }

        if(doClosed != null && !doClosed && doOpen != null && !doOpen) {

            throw new JsonUpdateException('Specify open or closed quotes or both, not neither.');

        }

        Set<String> quoteLineFields = new Set<String> {

            'SBQQ__PricingMethod__c','SBQQ__UpgradedSubscription__c',

            'SBQQ__RenewedSubscription__r.SBQQ__PricingMethod__c',

            'legacySubscription__c','SBQQ__Quote__c','jsonString__c',

            'legacySubscription__r.SBQQ__PricingMethod__c','SBQQ__NetTotal__c',

            'SBQQ__UpgradedSubscription__r.SBQQ__PricingMethod__c',

            'SBQQ__Product__r.SBQQ__PricingMethod__c','SBQQ__RenewedSubscription__c',

            'term__c','SBQQ__Quote__r.Current_Year__c','SBQQ__Optional__c',

            'SBQQ__Quote__r.SBQQ__Type__c','SBQQ__EffectiveQuantity__c'

        };

        String queryString = 'SELECT Id,Name,' + getFieldNamesStringFromStringSet(quoteLineFields);

        queryString += ' FROM SBQQ__QuoteLine__c';

        queryString += ' WHERE ';

        if(doClosed != null && !doClosed) {

            queryString += '((NOT SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName LIKE \'%Closed%\') AND SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Contracted__c != TRUE) AND ';

        }

        else if(doOpen != null && !doOpen) {

            queryString += '((SBQQ__Quote__r.SBQQ__Opportunity2__r.StageName LIKE \'%Closed%\') OR SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Contracted__c = TRUE) AND ';

        }

        queryString += 'pricingMethodChanged__c = TRUE ';     

        /*

        queryString += '(legacySubscription__r.pricingMethodChanged__c = TRUE';

        queryString += ' OR SBQQ__UpgradedSubscription__r.pricingMethodChanged__c = TRUE';

        queryString += ' OR SBQQ__RenewedSubscription__r.pricingMethodChanged__c = TRUE)';

        */

        if(quoteIds == null) {

            queryString += ' AND (SBQQ__Quote__r.SBQQ__Type__c = \'Amendment\'';

            queryString += ' OR (SBQQ__Quote__r.SBQQ__Type__c = \'Renewal\' AND SBQQ__Quote__r.Current_Year__c > 1))';

            queryString += ' ORDER BY CreatedDate ASC';

        }

        else if(quoteIds != null) {

            queryString += ' AND SBQQ__Quote__c IN: quoteIds';

        }

        List<SBQQ__QuoteLine__c> quoteLines = Database.query(queryString);

        Map<Id,List<SBQQ__QuoteLine__c>> quoteIdToQuoteLines = getParentIdToChildrenRecords(quoteLines,'SBQQ__Quote__c');

        Integer quotesHandledCount = 0;

        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();

        List<DataDump__c> snapShots = new List<DataDump__c>();

        for(Id quoteId : quoteIdToQuoteLines.keySet()) {

            System.debug('quoteIdToQuoteLines.get(quoteId).size(): ' + quoteIdToQuoteLines.get(quoteId).size());

            if( (quotesHandledCount < quoteCount) || quoteIds != null) {

                Boolean lineFound = false;

                for(SBQQ__QuoteLine__c quoteLine : quoteIdToQuoteLines.get(quoteId)) {
                    
                    Boolean jsonNotNull = (quoteLine.jsonString__c != null);

                    SBQQ__Subscription__c subscription;

                    if(quoteLine.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal') {

                        subscription = (quoteLine.SBQQ__RenewedSubscription__c != null) ? quoteLine.SBQQ__RenewedSubscription__r : quoteLine.legacySubscription__r;

                    }
                    
                    if(quoteLine.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment') {

                        subscription = (quoteLine.SBQQ__UpgradedSubscription__c != null) ? quoteLine.SBQQ__UpgradedSubscription__r : quoteLine.legacySubscription__r;

                    }

                    if(subscription != null && jsonNotNull) {

                        Boolean pricingMethodMismatch = false;

                        String quoteLinePricingMethod = getPricingMethodFromJsonString(quoteLine.jsonString__c);

                        if(jsonNotNull && quoteLine.SBQQ__PricingMethod__c != quoteLinePricingMethod) {

                            pricingMethodMismatch = true;

                        }

                        quoteLinePricingMethod = (quoteLinePricingMethod != null) ? quoteLinePricingMethod : quoteLine.SBQQ__PricingMethod__c;

                        if(quoteLinePricingMethod != subscription.SBQQ__PricingMethod__c) {

                            pricingMethodMismatch = true;

                        }

                        System.debug('pricingMethodMismatch: ' + pricingMethodMismatch);

                        if(pricingMethodMismatch) {

                            System.debug('quoteLine.Id: ' + quoteLine.Id);

                            DataDump__c snapShot = new DataDump__c(quoteLine__c = quoteLine.Id);

                            snapShot.originalEffectiveQuantity__c = quoteLine.SBQQ__EffectiveQuantity__c;

                            snapShot.originalPricingMethod__c = quoteLine.SBQQ__PricingMethod__c;

                            snapShot.originalNetTotal__c = quoteLine.SBQQ__NetTotal__c;

                            snapShot.originalJsonString__c = quoteLine.jsonString__c;

                            snapShots.add(snapShot);

                            quoteLine.jsonString__c = replaceJsonStringWithPricingMethod(quoteLine.jsonString__c,subscription);

                            quoteLine.SBQQ__PricingMethod__c = subscription.SBQQ__PricingMethod__c;

                            quoteLinesToUpdate.add(quoteLine);

                            lineFound = true;

                        }

                    }

                }

                quotesHandledCount += (lineFound) ? 1 : 0;
                
            }

            else {

                break;

            }                  

        }

        System.debug('quotesHandledCount: ' + quotesHandledCount);

        Set<Id> allQuoteIds = getIdSet((List<SObject>)quoteLinesToUpdate,'SBQQ__Quote__c');

        System.debug('allQuoteIds.size(): ' + allQuoteIds.size());

        List<SObject> closedQuotes = [SELECT

            Id FROM SBQQ__Quote__c

            WHERE Id IN: allQuoteIds

            AND (SBQQ__Opportunity2__r.StageName

            LIKE '%Closed%' OR SBQQ__Opportunity2__r.SBQQ__Contracted__c = TRUE)

        ];

        System.debug('closed quote count: ' + closedQuotes.size());

        Set<Id> closedQuoteIds = getIdSet(closedQuotes);

        Set<Id> openQuoteIds = allQuoteIds; openQuoteIds.removeAll(closedQuoteIds);

        System.debug('open quote count: ' + openQuoteIds.size());

        String openQuoteIdString = getIdString(openQuoteIds,';');

        String closedQuoteIdString = getIdString(closedQuoteIds,';');

        System.debug('openQuoteIdString: ' + openQuoteIdString);

        System.debug('closedQuoteIdString: ' + closedQuoteIdString);

        if(takeSnapShots) {

            insert snapShots;

        }

        if(quoteLinesToUpdate.size() > 0 && doUpdate) {

            SBQQ.TriggerControl.disable();

            CventMyd_Settings.mydTriggersAreActive = false;

            update quoteLinesToUpdate;

        }  

    }

    public static Map<Id,List<SObject>> getParentIdToChildrenRecords(List<SObject> childrenRecords, String lookupFieldName) {

        Map<Id,List<Id>> parentRecordIdToChildrenRecordIds = getParentIdToChildrenIdList(childrenRecords,lookupFieldName);

        Map<Id,SObject> childRecordIdToChildRecord = new Map<Id,SObject>(childrenRecords);

        Map<Id,List<SObject>> parentRecordIdToChildrenRecords = new Map<Id,List<SObject>>();

        for(Id parentRecordId : parentRecordIdToChildrenRecordIds.keySet()) {

            List<SObject> theseChildrenRecords = new List<SObject>();

            for(Id childRecordId : parentRecordIdToChildrenRecordIds.get(parentRecordId)) {

                theseChildrenRecords.add(childRecordIdToChildRecord.get(childRecordId));

            }

            parentRecordIdToChildrenRecords.put(parentRecordId,theseChildrenRecords);

        }

        return parentRecordIdToChildrenRecords;

    }

    public static Map<Id,Set<Id>> getParentIdToChildrenIdSet(List<SObject> childrenRecords, String lookupFieldName) {

        Map<Id,List<Id>> parentRecordIdToChildrenRecordIdList = getParentIdToChildrenIdList(childrenRecords,lookupFieldName);

        Map<Id,Set<Id>> parentRecordIdToChildrenRecordIdSet = new Map<Id,Set<Id>>();

        for(Id parentRecordId : parentRecordIdToChildrenRecordIdList.keySet()) {

            Set<Id> childrenRecordIds = new Set<Id>(parentRecordIdToChildrenRecordIdList.get(parentRecordId));

            parentRecordIdToChildrenRecordIdSet.put(parentRecordId,childrenRecordIds);

        }

        return parentRecordIdToChildrenRecordIdSet;        

    }    

    public static Map<Id,List<Id>> getParentIdToChildrenIdList(List<SObject> childrenRecords, String lookupFieldName) {

        Map<Id,List<Id>> parentRecordIdToChildrenRecordIds = new Map<Id,List<Id>>();

        for(SObject record : childrenRecords) {

            Id parentRecordId = (Id)record.get(lookupFieldName);

            if(parentRecordIdToChildrenRecordIds.get(parentRecordId) == null) {

                parentRecordIdToChildrenRecordIds.put(parentRecordId,new List<Id>());

            }

            parentRecordIdToChildrenRecordIds.get(parentRecordId).add(record.Id);

        }

        return parentRecordIdToChildrenRecordIds;

    }

    public static String getIdString(List<Id> recordIds, String separator) {

        String idString = '';

        for(Id recordId : recordIds) {idString += String.valueOf(recordId) + separator;}

        return idString;

    }    

    public static String getIdString(Set<Id> recordIds, String separator) {

        String idString = '';

        for(Id recordId : recordIds) {idString += String.valueOf(recordId) + separator;}

        return idString;

    }

    public static String getIdString(List<SObject> records, String separator) {

        String idString = '';

        Set<Id> recordIds = getIdSet(records);

        for(Id recordId : recordIds) {idString += String.valueOf(recordId) + separator;}

        return idString;

    }

    public static Set<Id> getIdSet(List<SObject> records) {

        Map<Id,SObject> recordIdToSObject = new Map<Id,SObject>(records);

        return recordIdToSObject.keySet();

    }

    public static Set<Id> getIdSet(List<SObject> records, String lookupFieldName) {

        Set<Id> recordIds = new Set<Id>();

        for(SObject record : records) {

            recordIds.add((Id)record.get(lookupFieldName));

        }

        return recordIds;

    }

    public static Set<Id> getIdSet(String idString, String separator) {

        Set<Id> ids = new Set<Id>();

        for(String idStr : idString.split(separator)) {

            ids.add(Id.valueOf(idStr));

        }

        return ids;

    }  
     
}