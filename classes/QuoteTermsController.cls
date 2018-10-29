public class QuoteTermsController {
    
    public Id objId {get; set;}
    
    public List<DisplayWrapper> getQuoteTermList() {
        List<SBQQ__QuoteTerm__c> quoteTerms = [SELECT Id, SBQQ__Body__c FROM SBQQ__QuoteTerm__c WHERE SBQQ__Quote__c = :objId];
        
        List<DisplayWrapper> qlWrappers = new List<DisplayWrapper>();
        for(SBQQ__QuoteTerm__c quoteTerm: quoteTerms) {
            DisplayWrapper dWrapper = new DisplayWrapper();
            dWrapper.body = quoteTerm.SBQQ__Body__c;
            qlWrappers.add(dWrapper);
        }
        
		if (qlWrappers.isEmpty())
			return null;
        return qlWrappers;
    }
    
    public class DisplayWrapper {
        public String body {get; set;}        
    }

}