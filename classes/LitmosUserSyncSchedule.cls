/*Schedule class for calling the "AccountServiceTierAssignment_Batch" class*/
global class LitmosUserSyncSchedule implements Schedulable {
   global void execute(SchedulableContext SC) {
        LitmosUserSync_Batch accService=new LitmosUserSync_Batch();
        Database.executeBatch(accService,200);
   }
}