trigger DG_DFR_Lead_Trigger on Lead (after insert, after update, before insert, before update) {
       
       Boolean Disable_DFR = false;
       
       try{
          if(System.Label.Disable_DFR == '1'){
                 Disable_DFR = true;
          }
       }catch(exception e){}
       
       if(!Disable_DFR){
              
              if(trigger.isInsert && trigger.isAfter){
             DG_DFR_Class.CreateLeadDFR(Trigger.new);      
           }        
              
              
           if(Trigger.isUpdate && trigger.isAfter){
                     if(DG_DFR_Class.LeadAfterUpdate_FirstRun || test.isRunningTest()){                    
                           DG_DFR_Class.DFR_LeadStatusChange(trigger.new,trigger.oldMap);    
                     DG_DFR_Class.LeadAfterUpdate_FirstRun=false;
                     }      
                     
                     
                     if(DG_DFR_Class.LeadConversion_FirstRun || test.isRunningTest()){                     
                           DG_DFR_Class.DFR_LeadConversion(trigger.new,trigger.oldMap);                                  
                     DG_DFR_Class.LeadConversion_FirstRun=false;
                     }
                     
              }
              
       }
       
       if(trigger.isBefore){
       
           if(trigger.isInsert){
               if(CheckRecursive.runTwentyNine() && Label.PhoneNumberValidator == 'True')
               PhoneNumberValidator_Clone.updateLeadPhoneNumber(trigger.new,new Map<Id,Lead>());
               trg_GDPRContactTrg.OnBeforeInsert(Trigger.new);   // Added by udita : 05/17/2018 [When a lead is marked GDPR this method is called]
               
           }else if(trigger.isUpdate){
               if(CheckRecursive.runThirtyThree() && Label.PhoneNumberValidator == 'True')
               PhoneNumberValidator_Clone.updateLeadPhoneNumber(trigger.new, Trigger.newMap);
               trg_GDPRContactTrg.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);  // Added by udita : 05/17/2018 [When a lead is marked GDPR this method is called]     
           }
       
       }
       
        if(Trigger.isUpdate && trigger.isAfter){
           trg_GDPRContactTrg.insertGDPR_Lead(Trigger.oldMap, Trigger.newMap);  // Added by udita : 05/17/2018 [When a lead is marked GDPR this method is called to insert its record in GDPR Repository]
        }
}