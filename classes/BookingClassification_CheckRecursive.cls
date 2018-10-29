public class BookingClassification_CheckRecursive{
    private static boolean runAfterInsert = true;
    private static boolean runAfterUpdate = true;
    private static boolean runAfterDelete = true;
    
    public static boolean runAfterInsert(){
        if(runAfterInsert){
            runAfterInsert = false;
            return true;
        }else{
            return runAfterInsert;
        }
    } 
    public static boolean runAfterUpdate(){
        if(runAfterUpdate){
            runAfterUpdate = false;
            return true;
        }else{
            return runAfterUpdate;
        }
    }
    public static boolean runAfterDelete(){
        if(runAfterDelete){
            runAfterDelete = false;
            return true;
        }else{
            return runAfterDelete;
        }
    }
}