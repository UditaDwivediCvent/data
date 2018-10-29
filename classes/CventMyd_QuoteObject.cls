public class CventMyd_QuoteObject {
    
    public Map<Integer,CventMyd_Outyear> outyearMap {get;set;}

    public Settings settings {get;set;}

    public String insertionId {get;set;}

    public Boolean currentYearSynced {get;set;}

    public CventMyd_QuoteAutomationStage automationStage {get;set;}

    public class Settings {

        public List<String> preCalculationFieldNames {get;set;}

        public List<String> calculatedFieldNames {get;set;}

        public List<String> numberFieldNames {get;set;}

        public Long msAtLastUpdate {get;set;}

    }

    public String previousQuoteType {get;set;}  

    // Ashwini: groupQleIds is no longer needed in this object. It was causing problems with calculation/trigger sequence so I removed it

}