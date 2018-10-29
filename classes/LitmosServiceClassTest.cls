@isTest
public class LitmosServiceClassTest{
        public static List<PricebookEntry> listOfPBE=new List<PricebookEntry>();
public static List<Product2> listOFProduct =new List<Product2>();
    public static testMethod void syncCommunityUserInLitmosTest(){
        
        Account portalAccount = new Account(name = 'portalAccount');//create a portal account first
        insert portalAccount;
        Contact portalContact = new contact(LastName = 'portalContact', AccountId = portalAccount.Id); //create a portal contact
        insert portalContact;
        

        listOFProduct =TestUtil.createProducts(new List<String>{'Professional License - Event Management'});
        listOFProduct[0].productcode='CV-AD-HC-CSN-1PPMP';
        listOFProduct[0].Product_Group__c = 'Event Cloud';
        listOFProduct[0].Product_Family__c = 'Event';
        insert listOFProduct;
        
        PricebookEntry instPBE= TestUtil.createPricebookEntry(listOFProduct[0],100);
        listOfPBE.add(instPBE);
        insert listOfPBE;
        
        Opportunity instOpp=TestUtil.createOpportunity('Test Opp','Event','Qualified');
        instOpp.StageName ='Qualified';
        instOpp.Deal_Year__c ='1';
        instOpp.NBB_Renewal__c = 'NBB';
        instOpp.Parent_Upsell__c = 'Primary';
        instOpp.CloseDate = system.today().addmonths(12);
        instOpp.Web_Design_Support_Minutes_Purchased__c =0;
        instOpp.Contract_Implemented__c = true;
        instOpp.ContractReceived__c = system.today();
        instOpp.Product__c ='TicketMob';
        instOpp.MYD_Deal__c='First Year';
        instOpp.pricebook2id=Test.getStandardPricebookID();
        instOpp.AccountId = portalAccount.Id;
        instOpp.Contact_Role__c = 'Influencer';
        instOpp.Contact_Associated__c=portalContact.id; 
        insert instOpp;
        
        OpportunityLineItem instOfOlitem=new OpportunityLineItem();
        List<OpportunityLineItem> listOlitem=new List<OpportunityLineItem>();
        instOfOlitem.OpportunityID = instOpp.Id;
        instOfOlitem.PriceBookEntryID=listOfPBE[0].Id;
        instOfOlitem.Product__c = 'Professional License - Event Management';
        instOfOlitem.quantity=4;
        instOfOlitem.totalprice=200;
        
        listOlitem.add(instOfOlitem);
        insert listOlitem;

        Id portalProfileId = [SELECT Id FROM Profile WHERE Name = 'Cvent Customer Community User'].Id;
        User userRec = new User( email='genelia.dsouza@gmail.com',
                profileid = portalProfileId, 
                UserName='genelia.dsouza@gmail.com', 
                Alias = 'GDS',
                TimeZoneSidKey='America/New_York',
                EmailEncodingKey='ISO-8859-1',
                LocaleSidKey='en_US', 
                LanguageLocaleKey='en_US',
                ContactId = portalContact.Id,
                PortalRole = 'Manager',
                FirstName = 'Genelia',
                LastName = 'Dsouza');
        insert userRec;
        System.runAs(userRec){
            userRec.Litmos__LitmosUserId__c = 'ABC';
            update userRec;
        }
    }
}