/**
 * InterviewScheduler
 * Schedules the InterviewReminderJob to run nightly at 3:00 AM.
 * This needs to be "primed" by manually running the following line of code in Apex Anonymous:
 *      InterviewReminderJobScheduler.scheduleJob();
 * Once primed, the job will run nightly until deleted manually
 */
public with sharing class InterviewReminderJobScheduler implements Schedulable{
    
    /**
     * Kicks off the InterviewReminderJob when executed by the scheduler
     * @param sc The SchedulableContext
     */
    public void execute(SchedulableContext sc) {

        InterviewReminderJob.runJob();        
    }

    /**
     * Schedules the InterviewReminderJob to run daily at 3:00 Am
     */
    public static void scheduleJob(){

        String jobName = 'Interview Reminder Job';
        String cronExpression = '0 0 3 * * ?'; // 3:00 AM daily

        // Check for existing scheduled jobs with same name and abort them to prevent duplicates
        for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]){
            System.abortJob(ct.Id);
        }

        // Schedule a new instance of the InterviewReminderJobScheduler
        System.schedule(jobName, cronExpression, new InterviewReminderJobScheduler());
    }
}