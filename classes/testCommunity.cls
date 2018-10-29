global class testCommunity{

    public string phoneNumber{get;set;}
    Public string selectedname{get;set;}
    
    public testCommunity(){
    
    }
    
    Public List<Selectoption> getCountryCode(){
            List<Selectoption> code = new List<selectoption>();
            code.add(new selectOption('', '- None -'));
            
            for(CountryCode__c c :[SELECT id,name,Code__c FROM CountryCode__c]){
            code.add(new selectoption(c.id,c.name));
            }
            return code; 
    }
        
    public void save(){
      
      system.debug('----phoneNumber'+this.phoneNumber);
      system.debug('----selectedname'+this.selectedname);
     
    }   
        
}