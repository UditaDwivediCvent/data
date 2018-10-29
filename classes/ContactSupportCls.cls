public class ContactSupportCls {
    public String searchTerm {get; set;}
    public String productSel {get; set;}
    public ContactSupportCls(ApexPages.StandardController controller) {
        searchTerm = '';
        productSel = '';
    }
    public PageReference search() {
        system.debug(searchTerm);
        system.debug(productSel);        
        PageReference pageRef = new PageReference('/apex/CommunitysearchResultPage?searchFor='+searchTerm+'&productSel='+productSel);
        pageRef.setRedirect(true);
        system.debug(pageRef);        
        return pageRef;
        
    }
}