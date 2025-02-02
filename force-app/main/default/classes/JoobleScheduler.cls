public with sharing class JoobleScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        // Fetch the callout parameters from Job App Settings record
        Map<String, String> paramMap = JobBoardService.getJobSearchParams('Jooble');
        // Enqueue callout with parameters        
        JoobleCallout job = new JoobleCallout(paramMap, 1);
        System.enqueueJob(job);
    }

    /**
     * Schedule the job to run nightly at midnight.
     *  
     * If this job is ever deleted, it can be reregistered by executing the following Anonymous Apex"
     *      JoobleScheduler.scheduleJob();
     * This will create a new scheduled job to run nightly at midnight.  
     */ 
    public static void scheduleJob(){
        String jobName = 'Nightly Jooble Callout';
        String cronExpression = '0 0 0 * * ?'; // every night at midnight
        
        // Check if a job with this name is already scheduled
        for(CronTrigger ct : [Select Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]) {
            System.abortJob(ct.Id);  // Abort existing duplicated job
        }
        
        // Schedule new job
        System.schedule(JobName, cronExpression, new JoobleScheduler());
    }
}