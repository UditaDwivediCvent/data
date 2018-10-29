@isTest
public class LitmosUserSync_BatchTest{
    static testMethod void unit1(){
        Account accRec =new Account();
        accRec.Name = 'Test Account';
        insert accRec;
        
        Contact conObj = new Contact();
        conObj.LastName = 'Test Last Name';
        conObj.AccountId = accRec.Id;
        insert conObj;
        
        Opportunity oppRec = new Opportunity();
        oppRec.Name = 'Test opp';
        oppRec.StageName = 'Verbal';
        oppRec.CloseDate = System.Today();
        oppRec.AccountId = accRec.Id;
        oppRec.Contact_Associated__c = conObj.Id;
        oppRec.Contact_Role__c = 'Infulencer';
        insert opprec;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        //Create your product
            Product2 prod = new Product2(
                Name = 'Event',
                ProductCode = 'Pro-X',
                Family ='CrowdCompass',
                isActive = true
            );
            insert prod;
            
            //Create your pricebook entry
            PricebookEntry pbEntry = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = prod.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            insert pbEntry;
            
            //create your opportunity line item.  This assumes you already have an opportunity created, called opp
            OpportunityLineItem oli1= new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,UnitPrice = 2.00,PricebookEntryId = pbEntry.Id);
 
         insert new List <OpportunityLineItem> { oli1};
         
         String CRON_EXP = '0 0 0 15 3 ? *';
         Test.startTest();

            String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new LitmosUserSyncSchedule());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
        
        //LitmosUserSyncSchedule ll = new LitmosUserSyncSchedule();
        //Database.executeBatch(new LitmosUserSync_Batch());
    }
}