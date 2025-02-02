public with sharing class StaleJobCleanupScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        // Execute the StaleJobCleanupBatch with a batch size of 200
        Database.executeBatch(new StaleJobCleanupBatch(), 200);
    }

    public static void scheduleJob(){
        
        String jobName = 'Stale Job Cleanup';
        String cronExpression = '0 0 1 * * ?'; // 1:00 AM daily

        // Abort duplicate jobs if they exist
        for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]){
            System.abortJob(ct.Id);
        }

        // Schedule the new job
        System.schedule(jobName, cronExpression, new StaleJobCleanupScheduler());
    }
}