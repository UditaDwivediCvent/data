global class HelphomeCls {
    public String search { get; set; }
    public String searchTerm {get; set;}
    public String productSel {get; set;}
    public List<What_s_New_Data__c> lstWhatsNew{get;set;}
    Public String primeString{get;set;}
    public Boolean showPrime{get;set;}
    public List<DataList> dataLst{get;set;}
    public List<Announcements__c> lstAnnounce = new List<Announcements__c>();
    public Boolean announcementCheck{get;set;}
    User userObj ;
    public List<Popular_Article__c> articleObj{get;set;} 
    public List<String> productName {get;set;}
    
    public Map<String,List<Popular_Article__c>> CProdVsArticleMap{get;set;} 
    public Boolean isSiteUser {get;set;}
    public String callUsURL {get;set;}
    public HelphomeCls(){
        //HSR: 02/12/2018 : Putting condition for the site users
        isSiteUser = false;
        if(UserInfo.getUserId() =='005o0000001zagpAAA')
            isSiteUser =  true;
        articleObj = new List<Popular_Article__c>();
    
        CProdVsArticleMap = new Map<String,List<Popular_Article__c>>();
        userObj = [SELECT Announcement_Clicked_Dev__c,Contact.Account.Service_Tier__c FROM User WHERE Id = : UserInfo.getUserId() LIMIT 1];
        callUsURL = 'http://www.cvent.com/en/contact/support-hours-and-numbers.shtml';
        if(String.IsNotBlank(userObj.Contact.Account.Service_Tier__c)){
            callUsURL = callUsURL+'?st='+userObj.Contact.Account.Service_Tier__c;
        }
        announcementCheck = userObj.Announcement_Clicked_Dev__c;
        lstWhatsNew = new List<What_s_New_Data__c>();
        lstWhatsNew = [SELECT Id, Link__c,Link_Label__c FROM What_s_New_Data__c WHERE Active__c =true ORDER BY Order__c ASC NULLS FIRST LIMIT 5];
        System.debug('lstWhatsNew**********'+lstWhatsNew);
        productName = new List<String>();
        For(Cvent_product__c cProdObj : [SELECT Id,Name,(SELECT Id,Article_URL__c,Name,Cvent_Product__c FROM Popular_Articles__r WHERE IsActive__c=TRUE ORDER BY Order__c ASC NULLS FIRST) FROM Cvent_product__c WHERE IsActive__c=TRUE ORDER BY Order__c ASC NULLS FIRST])
        {
            productName.add(cProdObj.Name);
            if(!CProdVsArticleMap.containsKey(cProdObj.Name))
            {
                articleObj = new List<Popular_Article__c>();
                articleObj.addALL(cProdObj.Popular_Articles__r);
                CProdVsArticleMap.put(cProdObj.Name,articleObj);
            }
            else
            {
                CProdVsArticleMap.get(cProdObj.Name).addALL(cProdObj.Popular_Articles__r);
            }
            
        }
        System.debug('CProdVsArticleMap******'+CProdVsArticleMap);
        lstAnnounce = new List<Announcements__c>();
        lstAnnounce = [SELECT Id,Data__c,Is_it_Pime__c FROM Announcements__c WHERE Is_Active__c = true ORDER BY CreatedDate ASC];
        dataLst = new List<DataList>();
        Integer counter=0;
        for(Announcements__c instA : lstAnnounce){
            counter++;
            DataList instDatList = new DataList('*'+' '+instA.Data__c);
            if(instA.Is_it_Pime__c == false)
            dataLst.add(instDatList);
            
            if(instA.Is_it_Pime__c == true && instA.Data__c!= '' && instA.Data__c!=null){
                showPrime = true;
                primeString = instA.Data__c;
            }
        }
    }
    public class DataList{  
        public String Announcement{get; set;}
        public DataList(String Announcement){
            this.Announcement = Announcement;
        }
    }
    public PageReference search() {
        PageReference pageRef = new PageReference('/apex/CommunitysearchResultPage?searchFor='+searchTerm+'&productSel='+productSel);
        //system.debug();
        pageRef.setRedirect(true);
        return pageRef;
    }
    
 //Calling remote method to update the checkbox in the User Object to show/hide the announcement....
    @RemoteAction
    global static String updateAnnouncement() {
        User userRec=new User(Id=UserInfo.getUserId());
        userRec.Announcement_Clicked_Dev__c =True;
        update userRec;
        return userRec.Id;
    }


}