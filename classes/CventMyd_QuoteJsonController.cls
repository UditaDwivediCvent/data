public class CventMyd_QuoteJsonController {

    public SBQQ__Quote__c quote {get;set;}

    public String quoteLinesJson {get;set;}

    public List<SBQQ__QuoteLine__c> quoteLines {get;set;}

    public CventMyd_QuoteJsonController (ApexPages.StandardController standardController) {

        Id quoteId = (ApexPages.currentPage().getParameters().get('quoteId') != null) ? ApexPages.currentPage().getParameters().get('quoteId') : ((SBQQ__Quote__c)standardController.getRecord()).Id;

        this.quote = [SELECT

            Id,jsonString__c,Current_Year__c,Contract_Term_Years__c,

            (SELECT

            Id,jsonString__c,term__c,SBQQ__ProductCode__c,SBQQ__Number__c

            FROM SBQQ__LineItems__r

            WHERE SBQQ__Number__c < 3000

            ORDER BY SBQQ__Number__c ASC

            LIMIT 70)

            FROM SBQQ__Quote__c

            WHERE Id =: quoteId

        ];

        this.quoteLines = new List<SBQQ__QuoteLine__c>();

        if(this.quote.SBQQ__LineItems__r.size() <= 7) {

            this.quoteLines = this.quote.SBQQ__LineItems__r;

        }

        else {

            this.quoteLines.add(this.quote.SBQQ__LineItems__r[0]);

            List<Integer> years = new List<Integer>();

            years.add(Integer.valueOf(this.quote.SBQQ__LineItems__r[0].term__c));

            for(SBQQ__QuoteLine__c ql : this.quote.SBQQ__LineItems__r) {

                if(!years.contains(Integer.valueOf(ql.term__c))) {

                    this.quoteLines.add(ql);

                    years.add(Integer.valueOf(ql.term__c));

                }

            }            

        }

        this.quoteLinesJson = JSON.serialize(this.quoteLines);
        
    }
}