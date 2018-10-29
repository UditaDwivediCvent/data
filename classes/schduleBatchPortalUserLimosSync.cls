/**=====================================================================
    * Cvent
    * Name: schduleBatchPortalUserLimosSync
    * Description: Schedule Class for PortalUserLimosSyncBatch Batch Class
    * Created Date: [11/23/2017]
    * Created By: Hemant Rana
    * 
    * Date Modified                Modified By                  Description of the update
    * [MON DD, YYYY]               [FirstName LastName]         [Short description for changes]
**======================================================================
*/
global class schduleBatchPortalUserLimosSync implements Schedulable {
    global void execute(SchedulableContext ctx) {
        PortalUserLimosSyncBatch p = new PortalUserLimosSyncBatch();
        database.executeBatch(p);
    }   
}