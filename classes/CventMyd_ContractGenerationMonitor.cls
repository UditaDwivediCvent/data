global without sharing class CventMyd_ContractGenerationMonitor implements Schedulable {

    global Set<Id> opportunityIds ;

    global String jobName ;

    global static Boolean isRunning = false;

    global CventMyd_ContractGenerationMonitor(Set<Id> opportunityIds, String jobName) {

        this.opportunityIds = opportunityIds;

        this.jobName = jobName;

    }

    global void execute(SchedulableContext sc) {

        isRunning = true;

        String exceptionString = null;

        List<Opportunity> opportunitiesFailed = new List<Opportunity>();

        try {

            Integer minutesToCheck = CventMyd_Settings.minutesBeforeContractMonitor + 2;

            DateTime dateTimeLowEnd = DateTime.now().addMinutes( (-1) * minutesToCheck );

            Set<String> opportunityFieldNames = new Set<String> {

                'contractedDateTime__c',

                'contractedRetried__c',

                'contractedCompleted__c',

                'SBQQ__PrimaryQuote__r.SBQQ__Type__c',

                'LastModifiedBy.Email',

                'SBQQ__AmendedContract__c',

                'SBQQ__PrimaryQuote__c',

                'SBQQ__PrimaryQuote__r.SBQQ__Type__c',

                '(SELECT Id FROM SBQQ__Contracts__r WHERE RecordType.Name = \'Child Contract\' AND CreatedDate >: dateTimeLowEnd)'

            };

            Id currentUserId = UserInfo.getUserId();

            User currentUser = [SELECT Validation_Bypass__c FROM User WHERE Id =: currentUserId];

            String queryString = 'SELECT Id,Name';

            queryString += ',' + CventMyd_UtilityMethods.getFieldNamesStringFromStringSet(opportunityFieldNames);

            queryString += ' FROM Opportunity';

            queryString += (opportunityIds != null) ? ' WHERE Id IN: opportunityIds' : ' WHERE contractedDateTime__c >: dateTimeLowEnd AND SBQQ__Contracted__c = true';

            System.debug('queryString0: ' + queryString);

            List<Opportunity> opportunities = Database.query(queryString);

            List<Opportunity> opportunitiesSucceeded = new List<Opportunity>();

            Set<Id> amendmentQuoteIds = new Set<Id>();

            for(Opportunity opportunity : opportunities) {

                Boolean isAmendment = (opportunity.SBQQ__PrimaryQuote__r.SBQQ__Type__c == 'Amendment' && opportunity.SBQQ__AmendedContract__c != null);

                if(isAmendment && !opportunity.contractedCompleted__c && !opportunity.contractedRetried__c) {

                    opportunitiesFailed.add(opportunity);

                }

                else if(!isAmendment && opportunity.SBQQ__Contracts__r.size() != 1) {

                    opportunitiesFailed.add(opportunity);

                }

                else if(!isAmendment && opportunity.SBQQ__Contracts__r.size() == 1) {

                    opportunity.contractedCompleted__c = true;

                    opportunitiesSucceeded.add(opportunity);

                }

                if(opportunity.SBQQ__PrimaryQuote__c != null && opportunity.SBQQ__PrimaryQuote__r.SBQQ__Type__c == 'Amendment') {

                    amendmentQuoteIds.add(opportunity.SBQQ__PrimaryQuote__c);

                }

            }

            if(!amendmentQuoteIds.isEmpty()) {

                CventMyd_UtilityMethods.updateSubscriptionsAfterAmendment(amendmentQuoteIds);

            }

            System.debug('opportunitiesFailed: ' + opportunitiesFailed);

            if(!opportunitiesFailed.isEmpty()) {

                if(opportunitiesFailed.size() <= 3) {

                    Boolean updateUser = false;

                    if(currentUser.Validation_Bypass__c != true) {

                        updateUser = true;

                        currentUser.Validation_Bypass__c = true;

                        update currentUser;

                    }

                    for(Opportunity opportunity : opportunitiesFailed) {

                        opportunity.SBQQ__Contracted__c = false;

                        opportunity.contractedRetried__c = true;

                    }

                    update opportunitiesFailed;

                    for(Opportunity opportunity : opportunitiesFailed) {

                        opportunity.SBQQ__Contracted__c = true;

                    }

                    update opportunitiesFailed;

                    if(updateUser) {

                        currentUser.Validation_Bypass__c = !currentUser.Validation_Bypass__c;

                        update currentUser;

                    }

                }

            }

            if(!opportunitiesSucceeded.isEmpty()) {

                update opportunitiesSucceeded;

            }

        }

        catch(Exception e) {

            exceptionString = CventMyd_UtilityMethods.getExceptionString(e);

            sendContractingFailureEmail(opportunitiesFailed,exceptionString);

        }

        if(exceptionString == null && !opportunitiesFailed.isEmpty()) {

            sendContractingFailureEmail(opportunitiesFailed,null);

        }

        CventMyd_UtilityMethods.abortSchedulableJobs(true,null,this.jobName,false);

    }

    public static void sendContractingFailureEmail(List<Opportunity> opportunitiesFailed, String exceptionString) {

        Messaging.reserveSingleEmailCapacity(1);

        Messaging.SingleEmailMessage singleEmailMessage = new Messaging.SingleEmailMessage();

        String[] toAddresses = CventMyd_Settings.administratorEmails;

        Id opportunityId;

        String failureMessage = '';

        for(Opportunity opportunity : opportunitiesFailed) {

            opportunityId = opportunity.Id;

            String emailAddressString = String.valueOf(opportunity.LastModifiedBy.Email);

            if(!toAddresses.contains(emailAddressString)) {

                toAddresses.add(emailAddressString);

            }

            failureMessage += (opportunity.SBQQ__PrimaryQuote__r.SBQQ__Type__c == 'Amendment') ? 'Amendment o' : 'O';

            failureMessage += 'pportunity with name \'' + opportunity.Name + '\'';

            failureMessage += ' and Id \'' + String.valueOf(opportunity.Id) + '\'';

            failureMessage += ' was marked contracted @ ' + CventMyd_UtilityMethods.getFormattedDateTimeString(opportunity.contractedDateTime__c,true,true);

            failureMessage += '<br/>';

        }

        singleEmailMessage.setToAddresses(toAddresses);

        if(opportunityId != null) {

        	singleEmailMessage.setWhatId(opportunityId);

        }

        singleEmailMessage.setSaveAsActivity(false);

        singleEmailMessage.setUseSignature(true);

        String subjectString = 'Contract Generation Failure for Opportunity';

        subjectString += (opportunityId != null) ? ' with Id \'' + String.valueOf(opportunityId) : '';

        String htmlBodyString = 'Hi all,<br/><br/>';

        htmlBodyString += 'You are (a)user(s) who has(have) either recently modified a contracted opportunity, or are designated as recipients of system monitoring emails.<br/><br/>';

        htmlBodyString += failureMessage;

        if(opportunitiesFailed.size() <= 3 && exceptionString == null) {

            htmlBodyString += '<br/>This(these) opportunities was(were) NOT successfully contracted, and will be retried but once more ONLY.<br/><br/>';

            htmlBodyString += 'Kindly monitor the results by navigating to the affected child contract data.';

        }

        else if(opportunitiesFailed.size() > 3 && exceptionString == null) {

            htmlBodyString += '<br/>There are too many opportunities that failed to rectify them at once. Please uncheck and recheck manually or write a batch job or schedulable chain.';

        }

        else if(exceptionString != null) {

            htmlBodyString += '<br/><div style="color:red; font-weight:bold;">';

            exceptionString = exceptionString.replaceAll('\r\n','<br/>');

            htmlBodyString += 'An error occurred when during execution of the contract generation monitor scheduled job.<br/><br/>' + exceptionString;

            htmlBodyString += '</div>';

        }

        singleEmailMessage.setSubject(subjectString);

        singleEmailMessage.setHtmlBody(htmlBodyString);

        Messaging.SingleEmailMessage[] singleEmailMessages = new Messaging.SingleEmailMessage[] {singleEmailMessage};

        Messaging.SendEmailResult[] sendEmailResults = Messaging.sendEmail(singleEmailMessages);

    }   

}