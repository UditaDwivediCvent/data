public without sharing class CventMyd_Settings {

    public static List<List<String>> fieldValueMapFieldNameLists;

    public static List<Map<String,List<String>>> quoteLineToSubscriptionFieldMaps;

    public static Integer hoursToRunRenewalChain;

    public static String opportunityFieldNamesString;

    public static String legacySubscriptionFieldNamesString;

    public static Id quoteUnlockedRecordTypeId;

    public static Id childContractRecordTypeId;

    public static Id parentContractRecordTypeId;

    public static Integer quoteLineMaxCount;

    public static Integer secondsBeforeFirstQuoteJob;

    public static Integer secondsBetweenRenewalJobs;

    public static Integer secondsBetweenQuoteJobs;

    public static String twinFieldNamesString;

    public static String extraQuoteLineFieldNamesString;

    public static String fullQuoteLineFieldNamesString;

    public static Integer statusChecksPerQuote;

    public static Integer secondsBeforeForceReroutingAmendment;

    public static Integer secondsBeforeLastQuoteJob;

    public static Integer quotesPerLegacyValidationJob;

    public static Boolean mydTriggersAreActive;

    public static Time timeToStartRenewalJob;

    public static Decimal maxHoursToRunRenewalChain;

    public static List<String> administratorEmails;

    public static String qleUrlBeforeQuoteId;

    public static String orgBaseUrl;

    public static Integer minutesBeforeFirstPulseCheck;

    public static Integer minutesBetweenPulseChecks;

    public static Integer minutesBeforeContractMonitor;

    public static Boolean contractingInForeground;

    public static Integer scheduledJobMax;

    static {

        Set<String> subscriptionFieldNames = new Set<String>();

        fieldValueMapFieldNameLists = new List<List<String>>();

        quoteLineToSubscriptionFieldMaps = new List<Map<String,List<String>>>();

        quoteLineToSubscriptionFieldMaps.add(new Map<String,List<String>>());

        quoteLineToSubscriptionFieldMaps.add(new Map<String,List<String>>());

        quotesPerLegacyValidationJob = 100;

        quoteUnlockedRecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Unlocked').getRecordTypeId();

        Map<String,Schema.RecordTypeInfo> contractRecordTypeNameToRecordTypeInfo = Schema.SObjectType.Contract.getRecordTypeInfosByName();

        childContractRecordTypeId = contractRecordTypeNameToRecordTypeInfo.get('Child Contract').getRecordTypeId();

        parentContractRecordTypeId = contractRecordTypeNameToRecordTypeInfo.get('Parent Contract').getRecordTypeId();

        Map<String,Schema.SObjectField> fieldNameToField = Schema.getGlobalDescribe().get('CventMyd_Settings__mdt').getDescribe().fields.getMap();

        Set<String> fieldNames = new Set<String>();

        for(String fieldName : fieldNameToField.keySet()) {

            if(fieldName.containsIgnoreCase('__c')){fieldNames.add(fieldName);}

        }

        String queryString = 'SELECT Id,DeveloperName,' + CventMyd_UtilityMethods.getFieldNamesStringFromStringSet(fieldNames);

        queryString += ' FROM CventMyd_Settings__mdt';

        for(CventMyd_Settings__mdt settingsRecord : Database.query(queryString)) {

            subscriptionFieldNames.addAll(CventMyd_UtilityMethods.getListOfStrings(settingsRecord.subscriptionFieldNames__c));

            if(settingsRecord.DeveloperName == 'QcpSettings') {

                fieldValueMapFieldNameLists.add(CventMyd_UtilityMethods.getListOfStrings(settingsRecord.preCalculationQuoteLineFieldNames__c));

                fieldValueMapFieldNameLists.add(CventMyd_UtilityMethods.getListOfStrings(settingsRecord.calculatedQuoteLineFieldNames__c));                

            }

            else if(settingsRecord.preOrPost__c == 'pre' || settingsRecord.preOrPost__c == 'post') {

                String jsonKey = settingsRecord.jsonStringFieldName__c;

                Integer fieldMapIndex = (settingsRecord.preOrPost__c == 'pre') ? 0 : 1;

                quoteLineToSubscriptionFieldMaps[fieldMapIndex].put(jsonKey,CventMyd_UtilityMethods.getListOfStrings(settingsRecord.subscriptionFieldNames__c));

            }

            else if(settingsRecord.DeveloperName == 'Processing_Settings') {

                Set<String> opportunityFieldNames = new Set<String>(CventMyd_UtilityMethods.getListOfStrings(settingsRecord.opportunityQueryFields__c));

                opportunityFieldNamesString = CventMyd_UtilityMethods.getFieldNamesStringFromStringSet(opportunityFieldNames);

                Set<String> quoteLineFieldNames = new Set<String>(CventMyd_UtilityMethods.getListOfStrings(settingsRecord.quoteLineQueryFields__c));

                extraQuoteLineFieldNamesString = CventMyd_UtilityMethods.getFieldNamesStringFromStringSet(quoteLineFieldNames);           

                qleUrlBeforeQuoteId = settingsRecord.qleUrlBeforeQuoteId__c;

                quoteLineMaxCount = (Integer)settingsRecord.quoteLineMaxCount__c;

                secondsBeforeFirstQuoteJob = (Integer)settingsRecord.secondsBeforeFirstQuoteJob__c;

                secondsBetweenRenewalJobs = (Integer)settingsRecord.secondsBetweenRenewalJobs__c;

                secondsBetweenQuoteJobs = (Integer)settingsRecord.secondsBetweenQuoteJobs__c;

                statusChecksPerQuote = (Integer)settingsRecord.statusChecksPerQuote__c;

                secondsBeforeForceReroutingAmendment = (Integer)settingsRecord.secondsBeforeForceReroutingAmendment__c;

                secondsBeforeLastQuoteJob = (Integer)settingsRecord.secondsBeforeLastQuoteJob__c;

                mydTriggersAreActive = settingsRecord.mydTriggersActive__c;

                timeToStartRenewalJob = settingsRecord.dateTimeToStartRenewalJob__c.time();

                maxHoursToRunRenewalChain = settingsRecord.maxHoursToRunRenewalChain__c;

                administratorEmails = CventMyd_UtilityMethods.getListOfStrings(settingsRecord.administratorEmails__c);

                minutesBeforeFirstPulseCheck = (Integer)settingsRecord.minutesBeforeFirstPulseCheck__c;

                minutesBetweenPulseChecks = (Integer)settingsRecord.minutesBetweenPulseChecks__c;

                minutesBeforeContractMonitor = (Integer)settingsRecord.minutesBeforeContractMonitor__c;

                contractingInForeground = (Boolean)settingsRecord.contractingInForeground__c;

                scheduledJobMax = (Integer)settingsRecord.scheduledJobMax__c;

            }

        }

        subscriptionFieldNames.remove('');

        legacySubscriptionFieldNamesString = CventMyd_UtilityMethods.getFieldNamesStringFromStringSet(subscriptionFieldNames);

        Set<String> twinFieldNames = CventMyd_UtilityMethods.getSubscriptionQuoteLineTwinFieldNames();

        twinFieldNamesString = CventMyd_UtilityMethods.getFieldNamesStringFromStringSet(twinFieldNames);

        fullQuoteLineFieldNamesString = extraQuoteLineFieldNamesString + ',' + twinFieldNamesString;

        orgBaseUrl = String.valueOf(System.URL.getSalesforceBaseUrl());

        orgBaseUrl = orgBaseUrl.split('delegate=')[1];

        orgBaseUrl = orgBaseUrl.substringBeforeLast(']') + '/';

    }

}