public class StaleJobCleanupBatch implements Database.Batchable<sObject>, Database.stateful {

    private List<Job_Application__c> closedJobs = new List<Job_Application__c>();
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query for stale Job_Application__c records and return the query locator.
        return Database.getQueryLocator([SELECT Id, Status__c, Follow_up_Date__c, Notes__c
                                        FROM Job_Application__c
                                        WHERE Status__c NOT IN ('Closed', 'Accepted')
                                            AND Follow_up_Date__c <= :Date.today().addDays(-30)]);
    }

    public void execute(Database.BatchableContext bc, List<Job_Application__c> scope){

        for(Job_Application__c app : scope){
            app.Status__c = 'Closed';
            if(String.isBlank(app.Notes__c)){
                app.Notes__c = 'Job Application was closed by an automated process on ' + Date.today().format();
            } else {
                app.Notes__c = 'Job Application was closed by an automated process on ' + Date.today().format() + '\n\n' + app.Notes__c;
            }
        }
        // Update records
        update scope;
        // Add records to closedJobs list
        closedJobs.addAll(scope);        
    }

    public void finish(Database.BatchableContext bc){
        // Log closed Jobs
        System.debug('Batch Job Completed. Closed ' + closedJobs.size() + ' Job Applications: ' + closedJobs);
    }
}