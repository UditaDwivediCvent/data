//========================Created By Rishi Ojha dated 22/07/13====================================

//=======================This test class is created to test the Trigger >>FirstActivityevent

//modified by Vaibhav Jain on 27/5/14 for updateAvgMoodOnAccount

@istest(SeeAllData=True)

private class TestActivityTriggerEvent

{
        public static List<Contact> CreateContacts(){
        Account a = new Account(name='test1');
        insert a;
        List<Contact> con = new List<Contact>{ new contact(
        FirstName = 'test con 1',
        LastName = 'xyz',
        LeadSource = 'Web',
        Mood_Level__c=3,
        AccountId=a.id)};
        return con;
}
static testMethod void testFirstActivityEvent()

{
    
        List<Contact> con = CreateContacts();                              
        /*insert con;
        con[0].Mood_Level__c=5;
        update con;*/
                
        List<event> e = new List<event>{ new event(
        WhoID = con[0].id,
        Subject='Newtask',
        Source__c='test',
        DurationInMinutes=60,
        ActivityDatetime=System.Today(),
        Mood__c='1 - Irate',
        Primary_Reason_for_Mood_Driver__c = 'Sales',
        Reason__c = 'Oversold',
        Description='test test'
        )};

        insert e;  
        
        
        
        //List<event> eventstoupdate = New List<event>{ [select id from event where id in :e]};
        //for(event eOK:eventstoupdate){
        List<event> eventstoupdate = New List<event>();
        for(event eOK:[select id from event where id in :e]){
        eOK.Activitydate = System.Today();
        eOK.Mood__c='2 - Frustrated';
        eOK.Primary_Reason_for_Mood_Driver__c = 'Sales';
        eOK.Reason__c = 'Oversold';
        eventstoupdate.add(eOK);
        }
        Update eventstoupdate;
        
       /*Contact[] cons = [select id from Contact where id in :con];
       delete con;*/

}

}