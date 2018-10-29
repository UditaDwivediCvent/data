trigger OnboardingTrg on Onboarding__c (after update) {
    set<id> onboardingIDs = new set<id>();
    OnboardingTrgHelperClass  handler = new OnboardingTrgHelperClass();
   
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap); 
    }  
}