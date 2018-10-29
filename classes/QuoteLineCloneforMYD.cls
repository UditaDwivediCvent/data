/*
File name :QuoteLineCloneforMYD
Desc: Cloning of quotes lines item on re assigning of opportunity. Call by trigger handler class on After update.
Author : Kumud |kumud.thakur1990@gmail.com
*/

public class QuoteLineCloneforMYD{
    
    public static Map<Id,QuoteWrapper> quoteIdToQuoteWrapper = new Map<Id,QuoteWrapper>();

    /**
    
    Method: checkVariablestype
    Parameters : List<Opportunity> of opportunity
    DESC: To find, var non var type of oppty.
    Author: Kumud
    
    */
    public void checkVariablestype(final List<Opportunity> listSourceOppty){
        
        final List<Opportunity> listNonVarToVarOpp=new List<Opportunity>();
        final Map<ID,Opportunity> mapNonVarToVarTrgOpp=new Map<ID,Opportunity>();
        final List<Opportunity> listVarToVarOpp=new List<Opportunity>();
        final Map<ID,Opportunity> mapVarToVarTrgOpp=new Map<ID,Opportunity>();
        final List<Opportunity> listVarToNonVarOpp=new List<Opportunity>();
        final Map<ID,Opportunity> mapVarToNonVarTrgOpp=new Map<ID,Opportunity>();
        
        Map<ID,Opportunity> MapSourceTrgtOppty=new Map<ID,Opportunity>();
        Map<ID,ID> mapOppTrgsrc=new Map<ID,ID>();
        set<ID> setID=new set<ID>();
        for(Opportunity opp:listSourceOppty){

            mapOppTrgsrc.put(opp.Reassigned_To__c,opp.id);
        }

        for(Opportunity instOpp:[select id,SBQQ__PrimaryQuote__c,Reassigned_To__c from opportunity where id in: mapOppTrgsrc.keySet() ]){

            MapSourceTrgtOppty.put(mapOppTrgsrc.get(instOpp.id),instOpp);
        }

        
        deleteQLItem(MapSourceTrgtOppty.keySet());// delete quote line item if, we change the value in reassign field
        
        for(Opportunity instOpp:listSourceOppty){
            // Non-variable to Variable 
            if(!instOpp.DELETE_Primary_Quote_is_Variable_Options__c && MapSourceTrgtOppty.get(instOpp.id).DELETE_Primary_Quote_is_Variable_Options__c){
                
                listNonVarToVarOpp.add(instOpp);
                mapNonVarToVarTrgOpp.put(instOpp.id,MapSourceTrgtOppty.get(instOpp.id));
                
            } //   Non-variable to Variable 
            // variable to Variable 
            else if(instOpp.DELETE_Primary_Quote_is_Variable_Options__c && MapSourceTrgtOppty.get(instOpp.id).DELETE_Primary_Quote_is_Variable_Options__c){
                
                listVarToVarOpp.add(instOpp);
                mapVarToVarTrgOpp.put(instOpp.id,MapSourceTrgtOppty.get(instOpp.id));
                
            } //   variable to Variable  

            // Variable to Non-Variable    
            else if(instOpp.DELETE_Primary_Quote_is_Variable_Options__c && !MapSourceTrgtOppty.get(instOpp.id).DELETE_Primary_Quote_is_Variable_Options__c){
                
                    listVarToNonVarOpp.add(instOpp);
                    mapVarToNonVarTrgOpp.put(instOpp.id,MapSourceTrgtOppty.get(instOpp.id));
                
            }           
        }   
        
        
        if(!listNonVarToVarOpp.isEmpty()){
            createNonVarToVarQuoteLines(listNonVarToVarOpp,mapNonVarToVarTrgOpp);
        }  
        if(!listVarToVarOpp.isEmpty()){
            createVarToVarQuoteLines(listVarToVarOpp,mapVarToVarTrgOpp);
        }  
        
        if(!listVarToNonVarOpp.isEmpty()){
            
            createVarToNonVar(listVarToNonVarOpp,mapVarToNonVarTrgOpp);
            
        }
                
    }   // end
    
    private void createVarToNonVar(final List<Opportunity> listVarToNonVarOpp,final Map<Id,Opportunity> mapVarToNonVarTrgOpp){
        
        Map<ID,SBQQ__Quote__c> mapQuote=new Map<ID,SBQQ__Quote__c>();
        Set<ID> setQuoteId=new Set<ID>();
        List<SBQQ__QuoteLine__c> listQLItem=new List<SBQQ__QuoteLine__c>();
        Map<Id,ID> mapQuoteSrcOpp=new Map<Id,ID>();
        /*for(Opportunity instOpp:mapVarToNonVarTrgOpp.values()){
            
            setQuoteId.add(instOpp.SBQQ__PrimaryQuote__c);
            
            
        }*/
        for(ID instID:mapVarToNonVarTrgOpp.keyset()){
            
                mapQuoteSrcOpp.put(mapVarToNonVarTrgOpp.get(instID).SBQQ__PrimaryQuote__c,instID);
            
        }
        mapQuote=new Map<ID,SBQQ__Quote__c>([select id,Current_Year__c,SBQQ__StartDate__c,SBQQ__EndDate__c from SBQQ__Quote__c where id in :mapQuoteSrcOpp.keySet()]);
        List<SBQQ__QuoteLineGroup__c> listQLGroup=groupCurrentYearQuoteLines(mapQuote);
        insert listQLGroup;
        
        Map<Id,List<SBQQ__QuoteLine__c>>  mapQLineItem= getQuoteLines(mapQuoteSrcOpp.keySet());
        for(SBQQ__QuoteLineGroup__c instLinegrp:listQLGroup){
            
            for(SBQQ__QuoteLine__c instQtLine:mapQLineItem.get(instLinegrp.SBQQ__Quote__c)){
                
                SBQQ__QuoteLine__c instQLine=new SBQQ__QuoteLine__c();
                instQLine=instQtLine;
                instQLine.SBQQ__Group__c=instLinegrp.id;
                instQLine.ReassignedFromOpportunityId__C=mapQuoteSrcOpp.get(instLinegrp.SBQQ__Quote__c);
                listQLItem.add(instQLine);
                
            }
            
            
        }//
        
        
        
        List<SBQQ__QuoteLine__c> listQLT= getNewQuoteLineItems(listVarToNonVarOpp,mapVarToNonVarTrgOpp);
        listQLItem.addAll(listQLT);
        
       
        if(!listQLItem.isEmpty()){
            
            insert listQLItem;
            
        }
        
        
        
        
    }
    
    public List<SBQQ__QuoteLine__c> getNewQuoteLineItems(final List<Opportunity> listSourceOpp,final Map<Id,Opportunity> mapSourceTrgOpp){
        
        final set<ID> setQuoteID=new Set<Id>();
        Map<Id,List<SBQQ__QuoteLine__c>> mapSrcQuoteLine=new Map<Id,List<SBQQ__QuoteLine__c>>();
        Map<Id,List<SBQQ__QuoteLineGroup__c>> mapTrgQuoteLineGrp=new Map<Id,List<SBQQ__QuoteLineGroup__c>>();
        Map<Id,Id> mapTrgQutSrcQut=new Map<Id,ID>();
        Map<Id,ID> mapOppTrgQuoteId=new Map<Id,Id>();
        
        for(Opportunity instOppty:listSourceOpp){
            
            if(instOppty.SBQQ__PrimaryQuote__c!=null){
                
                setQuoteID.add(instOppty.SBQQ__PrimaryQuote__c);
                
                
            }
            
            if(mapSourceTrgOpp.containskey(instOppty.id) && mapSourceTrgOpp.get(instOppty.id).SBQQ__PrimaryQuote__c!=null){
                
                mapOppTrgQuoteId.put(instOppty.id,mapSourceTrgOpp.get(instOppty.id).SBQQ__PrimaryQuote__c);
                mapTrgQutSrcQut.put(mapSourceTrgOpp.get(instOppty.id).SBQQ__PrimaryQuote__c,instOppty.SBQQ__PrimaryQuote__c);
                
            }
            
        }// end 

        if(!setQuoteID.isEmpty()){
            
            mapSrcQuoteLine=getQuoteLines(setQuoteID);
            
        }   
        
        if(!mapOppTrgQuoteId.isEmpty()){
            
            mapTrgQuoteLineGrp=getQuoteLineGroup(mapOppTrgQuoteId.values());
            
        }
        
        //for(Opportunity instOpp:listNonVarToVarOpp){
            
    //if(mapOppTrgQuoteId.containskey(instOpp.id)){
        List<SBQQ__QuoteLine__c> listQLT=new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLineGroup__c> listQLinegrp=new List<SBQQ__QuoteLineGroup__c>();
        for(List<SBQQ__QuoteLineGroup__c> listQLg:mapTrgQuoteLineGrp.values()){
            
            listQLinegrp.addAll(listQLg);
            
        }
        
        for(SBQQ__QuoteLineGroup__c instQLTG:listQLinegrp){
            
            if(mapTrgQutSrcQut.containskey(instQLTG.SBQQ__Quote__c) && mapSrcQuoteLine.containskey(mapTrgQutSrcQut.get(instQLTG.SBQQ__Quote__c))){
                
                
                for(SBQQ__QuoteLine__c instQLT:mapSrcQuoteLine.get(mapTrgQutSrcQut.get(instQLTG.SBQQ__Quote__c))){
                
                    SBQQ__QuoteLine__c instQLTClone= instQLT.clone(false, false, false, false);
                    instQLTClone.SBQQ__Quote__c=instQLTG.SBQQ__Quote__c;
                    instQLTClone.SBQQ__Group__c=instQLTG.id;
                    instQLTClone.ReassignedFromOpportunityId__C=instQLT.SBQQ__Quote__r.SBQQ__Opportunity2__c;
                    instQLTClone.Cloned_from_Quote_Line__c=instQLT.id;
                    instQLTClone.SBQQ__Optional__c=instQLTG.term__c==1?false:true;
                    
                    
                    listQLT.add(instQLTClone);
                
                }// end of inner loop   
                
            } // end of if
            
        }// end of outer loop   
        
    //}  
        return listQLT;
        
         
            
        
    }
    /*
    DESC: For non var to var scenario
    */
    private void createNonVarToVarQuoteLines(final List<Opportunity> listNonVarToVarOpp,final Map<Id,Opportunity> mapNonVarToVarTrgOpp){
        
        List<SBQQ__QuoteLine__c> listQLT= getNewQuoteLineItems(listNonVarToVarOpp,mapNonVarToVarTrgOpp);
        if(!listQLT.isEmpty()){
            
            insert listQLT;
            
        }  
        //}
                
        
        
    }// end
    /*
    DESC: For var to var scenario
    */
    private void createVarToVarQuoteLines(final List<Opportunity> listVarToVarOpp,final Map<Id,Opportunity> mapVarToVarTrgOpp){
        
        final set<ID> setQuoteID=new Set<Id>();
        Map<Id,List<SBQQ__QuoteLine__c>> mapSrcQuoteLine=new Map<Id,List<SBQQ__QuoteLine__c>>();
        Map<Id,List<SBQQ__QuoteLineGroup__c>> mapTrgQuoteLineGrp=new Map<Id,List<SBQQ__QuoteLineGroup__c>>();
        Map<Id,Id> mapTrgQutSrcQut=new Map<Id,ID>();
        Map<Id,ID> mapOppTrgQuoteId=new Map<Id,Id>();
        List<SBQQ__QuoteLine__c> listQLT=new List<SBQQ__QuoteLine__c>(); // list for insert
        List<SBQQ__QuoteLineGroup__c> listQLinegrp=new List<SBQQ__QuoteLineGroup__c>(); // target quote line group list
        Map<Id,List<SBQQ__QuoteLine__c>> mapSRCQGQlt=new Map<Id,List<SBQQ__QuoteLine__c>>(); // source line group with line items.
       
        
        for(Opportunity instOppty:listVarToVarOpp){
            
            if(instOppty.SBQQ__PrimaryQuote__c!=null){
                
                setQuoteID.add(instOppty.SBQQ__PrimaryQuote__c);
                
                
            }
            
            if(mapVarToVarTrgOpp.containskey(instOppty.id) && mapVarToVarTrgOpp.get(instOppty.id).SBQQ__PrimaryQuote__c!=null){
                
                mapOppTrgQuoteId.put(instOppty.id,mapVarToVarTrgOpp.get(instOppty.id).SBQQ__PrimaryQuote__c);
                mapTrgQutSrcQut.put(mapVarToVarTrgOpp.get(instOppty.id).SBQQ__PrimaryQuote__c,instOppty.SBQQ__PrimaryQuote__c);
                
            }
            
        }// end 
       
        if(!setQuoteID.isEmpty()){
            
            mapSrcQuoteLine=getQuoteLines(setQuoteID);
            for(String srcQuoteID:mapSrcQuoteLine.keySet()){
                
                for(SBQQ__QuoteLine__c instQLT:mapSrcQuoteLine.get(srcQuoteID)){
                    string key=srcQuoteID+instQLT.SBQQ__Group__r.term__C;
                    if(mapSRCQGQlt.containskey(key)){
                        
                        mapSRCQGQlt.get(key).add(instQLT);
                    }else{
                        mapSRCQGQlt.put(key ,new List<SBQQ__QuoteLine__c>{instQLT});
                    }
                    
                    
                }
                
            }   
            
        }   
        
        if(!mapOppTrgQuoteId.isEmpty()){
            
            mapTrgQuoteLineGrp=getQuoteLineGroup(mapOppTrgQuoteId.values());
            
        }
        
        
        for(List<SBQQ__QuoteLineGroup__c> listQLg:mapTrgQuoteLineGrp.values()){
            
            listQLinegrp.addAll(listQLg);
            
        }
        
        for(SBQQ__QuoteLineGroup__c instQLTG:listQLinegrp){
            
            string key=mapTrgQutSrcQut.get(instQLTG.SBQQ__Quote__c)!=null?String.valueOF(mapTrgQutSrcQut.get(instQLTG.SBQQ__Quote__c))+instQLTG.term__C:'';
                
            if(mapTrgQutSrcQut.containskey(instQLTG.SBQQ__Quote__c) && mapSRCQGQlt.containskey(key)){
                
                
                for(SBQQ__QuoteLine__c instQLT:mapSRCQGQlt.get(key)){
                
                    SBQQ__QuoteLine__c instQLTClone= instQLT.clone(false, false, false, false);
                    instQLTClone.SBQQ__Quote__c=instQLTG.SBQQ__Quote__c;
                    instQLTClone.SBQQ__Group__c=instQLTG.id;
                    instQLTClone.ReassignedFromOpportunityId__C=instQLT.SBQQ__Quote__r.SBQQ__Opportunity2__c;
                    instQLTClone.Cloned_from_Quote_Line__c=instQLT.id;
                    //instQLTClone.SBQQ__Optional__c=instQLTG.term__c==1?false:true;
                    
                    
                    listQLT.add(instQLTClone);
                
                }// end of inner loop   
                
            } // end of if
            
        }// end of outer loop   
        
    //}
        if(!listQLT.isEmpty()){
            
            insert listQLT;
            
        }   
        
        
        
    }  

    /*
    method name : getQuoteLines
    Desc: get all the quote line items of primary quote.
    @Author :kumud
    Parameter: Taking set of quootes ids.
    return : Map of quote id with all realted line items.
    */
    private Map<Id,List<SBQQ__QuoteLine__c>>  getQuoteLines(final Set<ID> setQuoteID){
        
        final Map<Id,List<SBQQ__QuoteLine__c>> mapQuoteLine=new Map<Id,List<SBQQ__QuoteLine__c>>();
        DescribeSObjectResult describeResult = SBQQ__QuoteLine__c.getSObjectType().getDescribe(); 
        Map<String, Schema.SObjectField> mapfield = Schema.SObjectType.SBQQ__QuoteLine__c.fields.getMap();      
        List<String> fieldNames = new List<String>( );  
        
        for(string field:describeResult.fields.getMap().keySet()){
            
            if(mapfield.get(field).getDescribe().isUpdateable()){
                fieldNames.add(field);
            
            }
            
        }
        
        system.debug('*****'+fieldNames.size());
        String query =    ' SELECT  SBQQ__Quote__r.SBQQ__Opportunity2__c, SBQQ__Group__r.term__C, ' +     String.join( fieldNames, ',' ) +     ' FROM ' 
        + describeResult.getName() +    ' WHERE ' + ' SBQQ__Quote__c in :setQuoteID ';

         system.debug('--->'+query);
        for(SBQQ__QuoteLine__c instQLT:database.query(query)){
            
            if(mapQuoteLine.containskey(instQLT.SBQQ__Quote__c)){
                
                mapQuoteLine.get(instQLT.SBQQ__Quote__c).add(instQLT);
                
            }else{
                mapQuoteLine.put(instQLT.SBQQ__Quote__c,new List<SBQQ__QuoteLine__c>{instQLT});
            }           
            
            
            
        }   
        
        return mapQuoteLine;
    }   // end of method
    
    /*
    method name : getQuoteLineGroup
    Desc: get all the quote line group of primary quote.
    @Author :kumud
    Parameter: Taking set of quootes ids.
    return : Map of quote id with all realted QuoteLineGroups
    */
    private Map<ID,List<SBQQ__QuoteLineGroup__c>> getQuoteLineGroup(final List<Id> listQuoteID){
        
        final Map<Id,List<SBQQ__QuoteLineGroup__c>> mapQuoteLineGrp=new Map<Id,List<SBQQ__QuoteLineGroup__c>>();
        for(SBQQ__QuoteLineGroup__c instQLTGrp:[Select id, SBQQ__Quote__c from SBQQ__QuoteLineGroup__c where SBQQ__Quote__c in :listQuoteID]){
            
            if(mapQuoteLineGrp.containskey(instQLTGrp.SBQQ__Quote__c)){
                
                mapQuoteLineGrp.get(instQLTGrp.SBQQ__Quote__c).add(instQLTGrp);
                
            }else{
                
                mapQuoteLineGrp.put(instQLTGrp.SBQQ__Quote__c,new List<SBQQ__QuoteLineGroup__c>{instQLTGrp});
            }
            
            
        }   // end of loop
        
        return mapQuoteLineGrp;
        
        
        
    }//end of method
    
    
    

public  List<SBQQ__QuoteLineGroup__c> getMydQuoteLineGroups(Map<Id,List<Integer>> quoteIdToOutyears, Boolean getCurrentYearGroup,Map<Id,SBQQ__Quote__c> mapQuote) {

    //    groupCurrentYearQuoteLines(quoteIdToOutyears.keyset());
        List<SBQQ__QuoteLineGroup__c> quoteLineGroups = new List<SBQQ__QuoteLineGroup__c>();

        for(Id quoteId : quoteIdToOutyears.keySet()) {

            SBQQ__Quote__c quote = mapQuote.get(quoteId) != null ? mapQuote.get(quoteId) : quoteIdToQuoteWrapper.get(quoteId).quote;

            CventMyd_QuoteObject quoteObject = CventMyd_UtilityMethods.getQuoteObject(quote);

            QuoteWrapper quoteWrapper = quoteIdToQuoteWrapper.get(quoteId);
            //QuoteWrapper quoteWrapper;
            if(quoteWrapper != null) {

                for(Integer year : quoteIdToOutyears.get(quoteId)) {

                    Boolean groupAlreadyCreated = quoteWrapper.yearToGroupWrapper.containsKey(year);

                    Integer maxNumberOfQuoteLineGroups = (Integer.valueOf(quote.Contract_Term_Years__c) - (Integer)quote.Current_Year__c) + 1;

                    if(!groupAlreadyCreated && (quote.numberOfQuoteLineGroups__c < maxNumberOfQuoteLineGroups) && (year > quote.Current_Year__c || getCurrentYearGroup) ) {

                        CventMyd_QuoteLineGroupObject quoteLineGroupObject = new CventMyd_QuoteLineGroupObject();

                        quoteLineGroupObject.startDate = (year == quote.Current_Year__c) ? quote.SBQQ__StartDate__c : quoteObject.outyearMap.get(year).startDate;

                        quoteLineGroupObject.endDate = (year == quote.Current_Year__c) ? quote.SBQQ__EndDate__c : quoteObject.outyearMap.get(year).endDate;

                        quoteLineGroupObject.qleId = CventMyd_UtilityMethods.getQleId();

                        quoteLineGroupObject.clonedFromQleId = null;

                        quoteLineGroupObject.insertedWithApex = true;

                        String groupName = 'Year ' + String.valueOf(year) + ( (year==(Integer)quote.Current_Year__c) ? ' (Current Year)' : '');

                        SBQQ__QuoteLineGroup__c quoteLineGroup = new SBQQ__QuoteLineGroup__c(

                            Name = groupName,

                            SBQQ__Number__c = (year - (Integer)quote.Current_Year__c) + 1,

                            term__c = year,

                            SBQQ__Optional__c = (year > (Integer)quote.Current_Year__c) ? true : false,

                            groupType__c = 'Variable MYD Group',

                            SBQQ__Quote__c = quote.Id,

                            jsonString__c = JSON.serialize(quoteLineGroupObject)

                        );

                        quoteLineGroups.add(quoteLineGroup);                 

                        GroupWrapper groupWrapper = new GroupWrapper(quoteLineGroup);                    

                        quoteIdToQuoteWrapper.get(quoteLineGroup.SBQQ__Quote__c).yearToGroupWrapper.put((Integer)quoteLineGroup.term__c,groupWrapper);                

                    }

                }

            }

        }

        return quoteLineGroups;      

    }
    
    public  List<SBQQ__QuoteLineGroup__c> groupCurrentYearQuoteLines(Map<Id,SBQQ__Quote__c> mapQuote) {

        Map<Id,List<Integer>> quoteIdToCurrentYear = new Map<Id,List<Integer>>();

        for(Id quoteId : mapQuote.keySet()) {

            SBQQ__Quote__c quote = mapQuote.get(quoteId);

            if(!quoteIdToQuoteWrapper.containsKey(quoteId)) {quoteIdToQuoteWrapper.put(quoteId,new QuoteWrapper(quote));}

            quoteIdToQuoteWrapper.get(quoteId).quote = quote;

            if(quote.numberOfQuoteLineGroups__c == 0) {

                quoteIdToCurrentYear.put(quoteId,new List<Integer>{(Integer)quote.Current_Year__c});

            }

        }
        
        List<SBQQ__QuoteLineGroup__c> listQLGrp= getMydQuoteLineGroups(quoteIdToCurrentYear,true,mapQuote);
        return listQLGrp;
    }
    
    public class QuoteWrapper {

        public SBQQ__Quote__c quote {get;set;}

        public SBQQ__Quote__c previousQuote {get;set;}

        public Map<Integer,GroupWrapper> yearToGroupWrapper {get;set;}

        public QuoteWrapper(SBQQ__Quote__c quote) {

            this.quote = quote;

            this.yearToGroupWrapper = new Map<Integer,GroupWrapper>();

            this.highestUnhiddenLineNumber = 0;

            this.highestHiddenLineNumber = 2999;            

        }

        public Integer highestHiddenLineNumber {get;set;}

        public Integer highestUnhiddenLineNumber {get;set;}

    }

    public class GroupWrapper {

        public SBQQ__QuoteLineGroup__c quoteLineGroup {get;set;}

        public Map<String,QuoteLineWrapper> qleIdToQuoteLineWrapper {get;set;}

        public GroupWrapper(SBQQ__QuoteLineGroup__c quoteLineGroup) {

            this.quoteLineGroup = quoteLineGroup;

            this.qleIdToQuoteLineWrapper = new Map<String,QuoteLineWrapper>();

        }

    }
    
    public class QuoteLineWrapper {

        public SBQQ__QuoteLine__c quoteLine {get;set;}

        public String requiredByQleId {get;set;}

        public Set<String> optionQleIds {get;set;}

        public Id newQuoteId {get;set;}

        public Boolean quoteFieldSet {get;set;}

        public QuoteLineWrapper(SBQQ__QuoteLine__c quoteLine, Id newQuoteId) {

            this.quoteLine = quoteLine;

            this.optionQleIds = new Set<String>();

            this.newQuoteId = newQuoteId;

            if(quoteLine.jsonString__c != null) {

                CventMyd_QuoteLineObject quoteLineObject = CventMyd_UtilityMethods.getQuoteLineObject(quoteLine);

                this.requiredByQleId = quoteLineObject.requiredByQleId;

            }          

        }

    }

    /*
    DESC: delete the quote line item during the change of reassign ID
    */
    private void deleteQLItem(Set<Id> setReassignId){
        
        
            
        List<SBQQ__QuoteLine__c> listQLItem=new List<SBQQ__QuoteLine__c>();
        listQLItem=[Select id from SBQQ__QuoteLine__c where ReassignedFromOpportunityId__C in :setReassignId];
            
        
        if(!listQLItem.isEmpty()){
            
            delete listQLItem;
        }
        
    }   
}// end of class.