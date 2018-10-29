//******************Developed by Rishi Ojha
//******************Dated : 05/08/2013
//******************Unit test for the Account Status update
//******************Test class for AccountStatus trigger on Contact***************
    
   @Istest(SeeAllData=True)
    
    private class TestAccountstatustrigger
    
   {
       static testmethod void testAccountStatusUpdate()
          {
                    
        Integer num = 5;
        String aName = 'Test acc';
        String aMailingStreet = 'Test add';
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < num; i++)
        {
            aName = aName + String.valueof(i);
            accList.add(new Account(Name = aName, Event_Account_Status__c='test1'));
            aName = 'Test acc';
        }
        insert accList;
        
        String cName = 'Test-con-';
        List<Contact> conList = new List<Contact>();
        for (Integer i = 0; i < num; i++)
        {
            cName = cName + String.valueof(i);
            conList.add(new Contact(AccountId = accList[i].Id, LastName = 'Test-con-lastname', Mailingstreet = 'testaddress'));
            cName = 'Test con';
        }
        insert conList;
        Delete conList;
        
        //assert 
        List <Account> accounts= [Select id, Name, Event_Account_Status__c from Account where Name = 'testName'];
        update accounts;
        System.assert(accounts!= null);    
        
     }
     
  }