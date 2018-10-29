/* ===============================
 AUTHOR     : Shanu Aggarwal    
 CREATED DATE     : 12 MAY 2016
 PURPOSE     :  Test Class For Opportunity trigger handler "OpportunityTrgHelperCls_Version_2"
 SPECIAL NOTES: We have extended a version of OpportunityTrgHelperCls which is used for Opportunity trigger. 
 
============================= 
*/

@isTest
public class OpportunityTrgHelperCls_Version_2_Test{
     
     
     
    public static Account instofAcc = new Account();
    public static Contact instofCon;
    public static List<PricebookEntry> listOfPBE=new List<PricebookEntry>();
    public static List<Product2> listOFProduct =new List<Product2>();

    static{
        // create custom setting
        UserAssignment__c instUA = new UserAssignment__c();
        instUA.Name = 'Integrated_Events';
        instUA.User_id__c = userinfo.getUserID();
        instUA.UserName__c = 'Brett Wischow';
        insert instUA;
        
        instofAcc=TestUtil.createAccount('Test Account','Biz_Ac');
        instofAcc.Supplier_Type__c = 'Venue';
        instofAcc.Venue_Type__c = 'CVB';
        instofAcc.CSN_Status__c ='Using';
        instofAcc.Supplier_Status__c='Approved';
        insert instofAcc;
        
        instofCon=TestUtil.createContact(instofAcc.id);
        insert instofCon;
        
        listOFProduct =TestUtil.createProducts(new List<String>{'CVENT Attendee Support','Cvent Creative Services'});
        listOFProduct[0].productcode='CV-AD-HC-CSN-1PPMP';
        insert listOFProduct;
        PricebookEntry instPBE= TestUtil.createPricebookEntry(listOFProduct[0],100);
        listOfPBE.add(instPBE);
        instPBE= TestUtil.createPricebookEntry(listOFProduct[1],100);
        listOfPBE.add(instPBE);
        insert listOfPBE;
        
        
        

    } 
    public static void createCustomsetting(){
        
        List<OpportunityAlerts__c> listOppAlert=new List<OpportunityAlerts__c>();
        OpportunityAlerts__c oppAl=new OpportunityAlerts__c();
        oppAl.name ='Completion';
        //oppAl.Alert__c=
        oppAl.Alert_Description__c='Notify contracts to begin implementation. Note that the alert converts to a case for Contracts.';
        oppAl.Sent_to__c='0F91N0000009Xwt';
        oppAl.Stage__c='Closed Won';
        listOppAlert.add(oppAl);
        
        oppAl=new OpportunityAlerts__c();
        oppAl.name ='MSA/Bulk Purchase Contract Type';
        oppAl.Alert__c='Magazine Ad Sold & Reprint Ads sold';
        oppAl.Alert_Description__c='Label:OppAlert';
        oppAl.Sent_to__c='0F91N0000009Xwt';
        oppAl.Stage__c='Closed Won';
        listOppAlert.add(oppAl);
        
        oppAl=new OpportunityAlerts__c();
        oppAl.name ='Tax Exemption Customer';
        oppAl.Alert__c='Magazine Ad Sold & Reprint Ads sold';
        oppAl.Alert_Description__c='Label:OppAlert';
        oppAl.Sent_to__c='0F91N0000009Xwt';
        oppAl.Stage__c='Closed Won';
        listOppAlert.add(oppAl);
        
        insert listOppAlert;
        
    }
    
    private static void createImplementationSurvey(ID OppID,ID quoteID){
        Implementation_Survey__c instImp=new Implementation_Survey__c();
        instImp.Account__c=instofAcc.id;
        instImp.Opportunity__c=OppID;
        instImp.Tax_Exempt__c='Yes';
        instImp.Quote__c=quoteID;
        insert instImp;
        
        
    }
    //Testing CreateTMMob Method of OpportunityTrgHelperCls_Version_2
    public static testmethod void testTicketMob(){
    
          
        User instUsr = TestUtil.CreateDeploymentUser();
        system.RunAs(instUsr){
            
            
            
            Test.startTest();
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
            instOpp.Contact_Associated__c=instofCon.id; 
            insert instOpp;
            
            List<Opportunity> listOfOpp=new List<Opportunity>{instOpp};
            List<OpportunityLineItem> listOlitem = new List<OpportunityLineItem>();
            
            OpportunityLineItem instOfOlitem=new OpportunityLineItem();
            instOfOlitem.OpportunityID = instOpp.Id;
            instOfOlitem.PriceBookEntryID=listOfPBE[0].Id;
            instOfOlitem.Product__c = 'CVENT Attendee Support';
            instOfOlitem.quantity=4;
            instOfOlitem.totalprice=200;
            
            listOlitem.add(instOfOlitem);
            
             instOfOlitem=new OpportunityLineItem();
            instOfOlitem.OpportunityID = instOpp.Id;
            instOfOlitem.PriceBookEntryID=listOfPBE[1].Id;
            instOfOlitem.Product__c = 'Cvent Creative Services';
            instOfOlitem.quantity=4;
            instOfOlitem.totalprice=200;
            
            listOlitem.add(instOfOlitem);
            
            insert listOlitem;
            
            
            
            
            
            instOpp.Web_Design_Support_Minutes_Purchased__c = 1 ;
            instOpp.StageName ='Closed Won';
            update instOpp;
            
            Map<Id,Opportunity> mapOpp=new Map<Id,Opportunity>();
            mapOpp.put(instOpp.id,instOpp);
            OpportunityTrgHelperCls_Version_2.WebDesignSupportRollup(listOfOpp,mapOpp,false,true);
            OpportunityTrgHelperCls_Version_2.CreateTMMob(mapOpp);
            OpportunityTrgHelperCls_Version_2.OnAfterInsert(mapOpp);
            OpportunityTrgHelperCls_Version_2.OnAfterDelete(new List<Opportunity>{instOpp},mapOpp);
            Test.stopTest();
        
        }
    }// end here
    
    public testmethod static void unitTesting(){
        
        User instUsr = TestUtil.CreateDeploymentUser();
        system.RunAs(instUsr){
            
            
            
            Test.startTest();
            instofAcc=TestUtil.createAccount('Test Account','Biz_Ac');
            instofAcc.Supplier_Type__c = 'Venue';
            instofAcc.Venue_Type__c = 'CVB';
            insert instofAcc;
            
            
            Opportunity instOpp=TestUtil.createOpportunity('Test Opp','Event','Qualified');
            instOpp.StageName ='Closed Won';
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
            instOpp.Contact_Associated__c=instofCon.id; 
            //instopp.SBQQ__PrimaryQuote__c ='';
            //instopp.SBQQ__RenewedContract__c=con1.Id;
            insert instOpp;
           
            
            SBQQ__Quote__c sbqq = new SBQQ__Quote__c();
            sbqq.SBQQ__Opportunity2__c = instopp.id;
            //sbqq.SBQQ__RenewedContract__c='';
           
            insert sbqq;
            instopp.SBQQ__PrimaryQuote__c=sbqq.id;
            //instopp.SBQQ__RenewedContract__c=con.Id;
            update sbqq;
            Map<Id,Opportunity> mapOpp=new Map<Id,Opportunity>();
            mapOpp.put(instOpp.id,instOpp);
            
            test.stopTest();
            
        } 
        
        
    }
    public static testmethod void contractOppSBqq(){
        User instUsr = TestUtil.CreateDeploymentUser();
        system.RunAs(instUsr){
        contract con = new contract();
        RecordType rtType = [SELECT r.SobjectType, r.DeveloperName,r.IsActive
                     FROM RecordType r WHERE SobjectType='Contract' And DeveloperName='Customer_Contracts' 
                     And IsActive=true limit 1];
            con.RecordTypeId =rtType.Id; 
            con.Contract_Request_Date__c= system.today();
            con.AccountId =instofAcc.Id;
            con.Status='On Hold';
            con.Contract_Term_Years__c='5';
            con.Current_Year__c=1;
            con.StartDate=system.today().addMonths(1);
            try{
                insert con;
            }catch(Exception e){
                
                
            }
            
            contract con1 = new contract();
            con1.Contract_Request_Date__c= system.today();
            con1.AccountId =instofAcc.Id;
            con1.Status='On Hold';
            con1.Parent_Contract__c=con.id;
            //con1.Upcoming_Renewal_Type__c='MYD Renewal';
            con1.StartDate=system.today().addMonths(2);
            try{
            
                insert con1;}
            catch (exception e)
            {
                system.debug('error'+e.getMessage());
            }

            
         Test.startTest();
            instofAcc=TestUtil.createAccount('Test Account','Biz_Ac');
            instofAcc.Supplier_Type__c = 'Venue';
            instofAcc.Venue_Type__c = 'CVB';
            insert instofAcc;
            
            
            
            Opportunity instOpp=TestUtil.createOpportunity('Test Opp','Event','Qualified');
            instOpp.StageName ='Closed Won';
            instOpp.Deal_Year__c ='1';
            instOpp.Is_Close_Date_Locked__c=false;
            //instopp.Master_Agreement__c=con.Id;
            instOpp.NBB_Renewal__c = 'NBB';
            instOpp.Parent_Upsell__c = 'Primary';
            
            instOpp.CloseDate = system.today().addmonths(12);
            instOpp.Web_Design_Support_Minutes_Purchased__c =0;
            instOpp.Contract_Implemented__c = true;
            instOpp.ContractReceived__c = system.today();
            instOpp.Product__c ='TicketMob';
            
            
            instOpp.MYD_Deal__c='First Year';
            instOpp.pricebook2id=Test.getStandardPricebookID();
            instOpp.Contact_Associated__c=instofCon.id; 
            instopp.Master_Agreement__c=con.Id;
            
            instopp.Contact_Role__c='Influencer';
            
            
            //instopp.SBQQ__RenewedContract__c=con1.Id;
            insert instOpp;
            
            con1.SBQQ__Opportunity__c=instOpp.id;
            update con1;
            
            SBQQ__Quote__c sbqq = new SBQQ__Quote__c();
            sbqq.SBQQ__StartDate__c=system.today();
            sbqq.SBQQ__Opportunity2__c = instopp.id;
            //sbqq.SBQQ__RenewedContract__c='';
           
           
            insert sbqq;
            //SBQQ__QuoteLine__c instQLitem =new SBQQ__QuoteLine__c();
            //instQLitem.Number_of_Guest_Rooms__c='201-749';
            
            instopp.SBQQ__PrimaryQuote__c=sbqq.id;
            instopp.Master_Agreement__c =con1.id;
            instopp.SBQQ__RenewedContract__c=con1.Id;
            
            update instopp;
            //Map<Id,Opportunity> mapOpp=new Map<Id,Opportunity>();
            //mapOpp.put(instOpp.id,instOpp);
            
            test.stopTest();
            
        } 
    }
    
    public static testmethod void OpportunityChatterAlertsTest(){
        ID profileID=[select id from profile where name='System Administrator'].id;
        User u=TestUtil.createUser(profileID,'kdnewuser@testorg.com');
        u.lastname='Kd';
        u.email='Kdthakur@gmail.com.test';
        insert u;
        User instUsr = TestUtil.CreateDeploymentUser();
        insert instUsr;
        Id userId=userinfo.getUserID();
        createCustomsetting();
        system.RunAs(instUsr){
            
            Map<Id,Opportunity> mapOppOld=new Map<Id,Opportunity>();
            Map<Id,Opportunity> mapOppNew=new Map<Id,Opportunity>();
            Id CSNRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CSN-Supplier').getRecordTypeId();
                Opportunity instOpp=TestUtil.createOpportunity('Test Opp','Event','Closed Won');
                instOpp.AccountID =instofAcc.id;
                instOpp.Deal_Year__c ='1';
                instOpp.NBB_Renewal__c = 'NBB';
                instOpp.Parent_Upsell__c = 'Primary';
                instOpp.CloseDate = system.today().addmonths(12);
                instOpp.Web_Design_Support_Minutes_Purchased__c =0;
                instOpp.Contract_Implemented__c = true;
                instOpp.ContractReceived__c = system.today();
                instOpp.Product__c ='CSN';
                instOpp.MYD_Deal__c='First Year';
                instOpp.pricebook2id=Test.getStandardPricebookID();
                instOpp.Contact_Associated__c=instofCon.id;
                instOpp.Is_Close_Date_Locked__c=false;
                instopp.recordtypeID=CSNRecTypeId;
                instopp.Chain_Deal__c='Bulk Purchase';
                instOpp.ownerID=instUsr.id;
                instopp.AM_Owner__c='Kd';
                insert instOpp;
                
                SBQQ__Quote__c sbqq = new SBQQ__Quote__c();
                sbqq.SBQQ__Opportunity2__c = instopp.id;
                sbqq.ownerID=userId;
                insert sbqq;
                
                createImplementationSurvey(instopp.id,sbqq.id);
            
                instopp.SBQQ__PrimaryQuote__c=sbqq.id;
                //instopp.AM_Owner__c='Test Opp';
                //mapOppOld.put(instopp.id,instopp);
                update instopp;
            

           
                mapOppOld.put(instopp.id,instopp);

                
            Test.startTest();   
                

                mapOppNew.put(instopp.id,instopp);
                OpportunityTrgHelperCls_Version_2.isTest=true;
                OpportunityTrgHelperCls_Version_2.OpportunityChatterAlerts(mapOppNew, mapOppOld);
                //OpportunityTrgHelperCls_Version_2.isTest=true;
                OpportunityTrgHelperCls_Version_2.syncOwner(mapOppNew.values(),mapOppOld);
                OpportunityTrgHelperCls_Version_2.ChangeOppSplitOwner(mapOppNew,mapOppOld);
                OpportunityTrgHelperCls_Version_2.SendAMAlert(mapOppNew,mapOppOld);
            Test.stopTest();
        

        }
    }
    
    
    public static testmethod void CreateRFPCaseOnClosedLostTest(){
       
       
        User instUsr = TestUtil.CreateDeploymentUser();
        insert instUsr;
        List<AccountTeamMember> listOfAccountTeam=new List<AccountTeamMember>();
        List<Opportunity> listOfOppty=new List<Opportunity>();
        Id userId=userinfo.getUserID();
        createCustomsetting();
        system.RunAs(instUsr){
            
            AccountTeamMember instATeam=TestUtil.createAccountTeamMember(instofAcc.id,'AM - Inquisium');
            listOfAccountTeam.add(instATeam);
            
            insert listOfAccountTeam;
            
            Map<Id,Opportunity> mapOppOld=new Map<Id,Opportunity>();
            Map<Id,Opportunity> mapOppNew=new Map<Id,Opportunity>();
            Id CSNRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CSN-Supplier').getRecordTypeId();
                Opportunity instOpp=TestUtil.createOpportunity('Test Opp','Event','Qualified');
                instOpp.AccountID =instofAcc.id;
                instOpp.Deal_Year__c ='2';
                instOpp.NBB_Renewal__c = 'Renewal';
                instOpp.Parent_Upsell__c = 'Primary';
                instOpp.CloseDate = system.today().addmonths(12);
                instOpp.Web_Design_Support_Minutes_Purchased__c =0;
                instOpp.Contract_Implemented__c = true;
                instOpp.ContractReceived__c = system.today();
                instOpp.Product__c ='CSN';
                instOpp.MYD_Deal__c='First Year';
                instOpp.pricebook2id=Test.getStandardPricebookID();
                instOpp.Contact_Associated__c=instofCon.id;
                instOpp.Is_Close_Date_Locked__c=false;
                instopp.recordtypeID=CSNRecTypeId;
                instopp.Chain_Deal__c='Venue/Service';
                instOpp.ownerID=instUsr.id;
                instopp.AM_Owner__c='Kd';
                instopp.License_Type__c='1 Diamond';
                listOfOppty.add(instopp);
                
                instOpp=TestUtil.createOpportunity('Test Opp2','Event','Qualified');
                instOpp.AccountID =instofAcc.id;
                instOpp.Deal_Year__c ='2';
                instOpp.NBB_Renewal__c = 'Renewal';
                instOpp.Parent_Upsell__c = 'Primary';
                instOpp.CloseDate = system.today().addmonths(12);
                instOpp.Product__c ='Survey';
                instopp.recordtypeID=CSNRecTypeId;
                listOfOppty.add(instopp);
                
                instOpp=TestUtil.createOpportunity('Test Opp3','Event','Qualified');
                instOpp.AccountID =instofAcc.id;
                instOpp.Deal_Year__c ='2';
                instOpp.NBB_Renewal__c = 'Renewal';
                instOpp.Parent_Upsell__c = 'Primary';
                instOpp.CloseDate = system.today().addmonths(12);
                instOpp.Product__c ='Event';
                instopp.recordtypeID=CSNRecTypeId;
                listOfOppty.add(instopp);
                
                instOpp=TestUtil.createOpportunity('Test Opp3','Event','Qualified');
                instOpp.AccountID =instofAcc.id;
                instOpp.Deal_Year__c ='2';
                instOpp.NBB_Renewal__c = 'Renewal';
                instOpp.Parent_Upsell__c = 'Primary';
                instOpp.CloseDate = system.today().addmonths(12);
                instOpp.Product__c ='RegOnline';
                instopp.recordtypeID=CSNRecTypeId;
                listOfOppty.add(instopp);
                
                insert listOfOppty;
                
                SBQQ__Quote__c sbqq = new SBQQ__Quote__c();
                sbqq.SBQQ__Opportunity2__c = instopp.id;
                sbqq.ownerID=userId;
                insert sbqq;
                
               
                
            Test.startTest();   
                mapOppOld.put(instopp.id,instopp);
                instopp.SBQQ__PrimaryQuote__c=sbqq.id;
                instopp.StageName='Closed Lost';
                //instopp.AM_Owner__c='Test Opp';
                //mapOppOld.put(instopp.id,instopp);
                update instopp;
                mapOppNew.put(instopp.id,instopp);
                OpportunityTrgHelperCls_Version_2.istest=true;
                OpportunityTrgHelperCls_Version_2.CreateRFPCaseOnClosedLost(mapOppNew.values(),mapOppOld);
            Test.stopTest();
        

        }
    }// end 
    
    
    private testmethod static void createQuoteLineReassignOppTest(){
        
        OpportunityTrgHelperCls_Version_2.isComingfromTestHandler1=true;
        User instUsr = TestUtil.CreateDeploymentUser();
        insert instUsr;
        
        List<Opportunity> listOfOppty=new List<Opportunity>();
        Id userId=userinfo.getUserID();
        createCustomsetting();
        system.RunAs(instUsr){
            
            Map<Id,Opportunity> mapOppOld=new Map<Id,Opportunity>();
            Map<Id,Opportunity> mapOppNew=new Map<Id,Opportunity>();
            Id CSNRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CSN-Supplier').getRecordTypeId();
                Opportunity instOpp=TestUtil.createOpportunity('Test Opp','Event','Qualified');
                instOpp.AccountID =instofAcc.id;
                instOpp.Deal_Year__c ='1';
                instOpp.NBB_Renewal__c = 'Renewal';
                instOpp.Parent_Upsell__c = 'Primary';
                instOpp.CloseDate = system.today().addmonths(12);
                instOpp.Web_Design_Support_Minutes_Purchased__c =0;
                instOpp.Contract_Implemented__c = true;
                instOpp.ContractReceived__c = system.today();
                instOpp.Product__c ='CSN';
                instOpp.MYD_Deal__c='First Year';
                instOpp.pricebook2id=Test.getStandardPricebookID();
                instOpp.Contact_Associated__c=instofCon.id;
                instOpp.Is_Close_Date_Locked__c=false;
                instopp.recordtypeID=CSNRecTypeId;
                instopp.Chain_Deal__c='Venue/Service';
                instOpp.ownerID=instUsr.id;
                instopp.AM_Owner__c='Kd';
                instopp.License_Type__c='1 Diamond';
                
                insert instopp;
                
                Id OppId=instopp.id;
                
                instOpp=TestUtil.createOpportunity('Test Opp2','Event','Closed Won');
                instOpp.AccountID =instofAcc.id;
                instOpp.Reassigned_To__c=OppId;
                instOpp.Deal_Year__c ='1';
                instOpp.NBB_Renewal__c = 'Renewal';
                instOpp.Parent_Upsell__c = 'Primary';
                instOpp.CloseDate = system.today().addmonths(12);
                instOpp.Product__c ='Survey';
                instopp.recordtypeID=CSNRecTypeId;
                
                insert instopp;
                
                SBQQ__Quote__c sbqq = new SBQQ__Quote__c();
                sbqq.SBQQ__Opportunity2__c = instopp.id;
                sbqq.Contract_Term_Years__c='2';
                sbqq.SBQQ__EndDate__c = Date.today().addMonths(12);
                insert sbqq;
                
                SBQQ__QuoteLine__c instQLI=new SBQQ__QuoteLine__c();
                instQLI.SBQQ__Quote__c=sbqq.id;
                instQLI.SBQQ__Product__c=listOFProduct[0].id;
                instQLI.SBQQ__Renewal__c=true;
                instQLI.SBQQ__Existing__c=false;
                instQLI.SBQQ__NetPrice__c=1000;
                
                insert instQLI;
                
               
            
                instopp.SBQQ__PrimaryQuote__c=sbqq.id;
                
                update instopp;
                
                mapOppOld.put(instopp.id,instopp);
                mapOppNew.put(instopp.id,instopp);
                Test.StartTest();
                OpportunityTrgHelperCls_Version_2.istest=true;
                OpportunityTrgHelperCls_Version_2.createQuoteLineReassignOpp(mapOppNew,mapOppOld);
                Test.stopTest();
                //listOfOppty.add(instopp);
        
        }
    }// end here
    
    private testmethod static void BookingClassificationTest(){
        
        //OpportunityTrgHelperCls_Version_2.isComingfromTestHandler1=true;
        User instUsr = TestUtil.CreateDeploymentUser();
        insert instUsr;
        
        List<Opportunity> listOfOppty=new List<Opportunity>();
        Id userId=userinfo.getUserID();
        createCustomsetting();
        system.RunAs(instUsr){
            
            Map<Id,Opportunity> mapOppOld=new Map<Id,Opportunity>();
            Map<Id,Opportunity> mapOppNew=new Map<Id,Opportunity>();
            Id CSNRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CSN-Supplier').getRecordTypeId();
               
                
               Opportunity instOpp=TestUtil.createOpportunity('Test Opp2','Event','Closed Won');
                instOpp.AccountID =instofAcc.id;
                //instOpp.Reassigned_To__c=OppId;
                instOpp.Deal_Year__c ='2';
                instOpp.NBB_Renewal__c = 'Renewal';
                instOpp.Parent_Upsell__c = 'Primary';
                instOpp.CloseDate = system.today().addmonths(12);
                instOpp.Product__c ='Survey';
                instopp.recordtypeID=CSNRecTypeId;
                
                insert instopp;
                
                Id OppId=instopp.id;
                instOpp=TestUtil.createOpportunity('Test Opp','Event','Qualified');
                instOpp.AccountID =instofAcc.id;
                instOpp.Deal_Year__c ='2';
                instOpp.NBB_Renewal__c = 'Renewal';
                instOpp.Parent_Upsell__c = 'Primary';
                instOpp.CloseDate = system.today().addmonths(12);
                instOpp.Web_Design_Support_Minutes_Purchased__c =0;
                instOpp.Contract_Implemented__c = true;
                instOpp.ContractReceived__c = system.today();
                instOpp.Product__c ='CSN';
                instOpp.MYD_Deal__c='First Year';
                instOpp.pricebook2id=Test.getStandardPricebookID();
                instOpp.Contact_Associated__c=instofCon.id;
                instOpp.Is_Close_Date_Locked__c=false;
                instopp.recordtypeID=CSNRecTypeId;
                instopp.Chain_Deal__c='Venue/Service';
                instOpp.ownerID=instUsr.id;
                instopp.AM_Owner__c='Kd';
                instopp.License_Type__c='1 Diamond';
                instOpp.Reassigned_To__c=OppId;
                insert instopp;
                
                mapOppOld.put(instopp.id,instopp);
                
                
                Booking_Classification__c instBooking=new Booking_Classification__c();
                instBooking.Opportunity__c=instopp.id;
                
                insert instBooking;
                
                contract con1 = new contract();
                con1.Contract_Request_Date__c= system.today();
                con1.AccountId =instofAcc.Id;
                con1.Status='On Hold';
                
                //con1.Upcoming_Renewal_Type__c='MYD Renewal';
                con1.StartDate=system.today().addMonths(2);
                try{
                
                    insert con1;}
                catch (exception e)
                {
                    system.debug('error'+e.getMessage());
                }
                Test.startTest();
                instopp.SBQQ__AmendedContract__c=con1.id;
                //instopp.SBQQ__RenewedContract__c=true;
                update instopp;
                OpportunityTrgHelperCls_Version_2.istest=true;
                
                OpportunityTrgHelperCls_Version_2.DeleteReassignedToQuoteLines(mapOppOld,mapOppOld);
                OpportunityTrgHelperCls_Version_2.updateBCValues(mapOppOld,mapOppOld);
                OpportunityTrgHelperCls_Version_2.deleteRelatedBookings(mapOppOld);
                
                try{
                
                delete instopp;
                }catch(Exception e){
                
                }
                Test.stopTest();
                
                
        }
    }   
}