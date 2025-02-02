@isTest
public with sharing class InterviewReminderTests {
    
    /**
     * Tests the queryInterviews method to ensure the proper events are retrieved with the right data.
     * Specifically makes sure method is able to get into the various lookup relationships to pull the right data.
     */
    @isTest
    private static void testQueryInterviews() {

        // Generate Data
        List<Event> eventList = TestDataScheduledJobs.generateData();

        // Test query
        List<Event> results;
        Test.startTest();
        results = InterviewReminderJob.queryInterviews();
        Test.stopTest();
        System.debug(results);

        // Verify Results
        Assert.areEqual(1, results.size(), 'Only 1 Event Record should have been returned by the query');
        Assert.areEqual('John Doe', results[0].Who.Name, 'Contact information did not pull in properly');
        Assert.areEqual('Technical Interview 1', results[0].Subject, 'Wrong event returned by the query');
        // Cast What results properly
        Job_Application__c job = (Job_Application__c)results[0].What;
        Assert.areEqual('Salesforce Developer', job.Position_Title__c, 'Job Application record (What) not properly related to Event');
        Assert.areEqual('jane.doe@example.com', results[0].Owner.Email, 'Event owner email is incorrect');
    }


    /**
     * Test the buildEmailComponents method.
     */

    @isTest
    private static void testBuildEmailComponents(){

        // Generate Mock Data
        List<Event> eventList = TestDataScheduledJobs.generateData();
        // Query for interviews
        List<Event> interviews = InterviewReminderJob.queryInterviews();

        // Test Method
        EmailData components;
        Test.startTest();
        components = InterviewReminderJob.buildEmailComponents(interviews[0]);
        Test.stopTest();

        // Verify Results
        Assert.areEqual('Reminder: Upcoming Interview', components.getSubject(), 'Incorrect email subject returned');
        Assert.areEqual('jane.doe@example.com', components.getAddresses()[0], 'Incorrect email address');
        Assert.isTrue(components.getBody().contains('Salesforce Developer'), 'Incorrect email body');
    }

    /**
     * Tests whole process with 27 emails sent to 2 different email addresses.
     * Process includes the runJob method and the EmailService class.
     */

    @isTest
    private static void testRunJob(){

        // Generata Full Data
        List<Event> eventList = TestDataScheduledJobs.generateMoreData();        

        // Run Test
        Test.startTest();
        InterviewReminderJob.runJob();
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        
        // Verify Results, because these are in bulk, the 27 emails sent should return 1 invocation
        Assert.areEqual(1, emailInvocations, 'No emails were sent!');
    }
    
    /**
     * Test for gracefully handling a missing email field in the Email Service as well as an empty EmailData object
     */
    @isTest
    private static void testMissingEmail(){
        
        // Generate data
        List<EmailData> emailDataList = new List<EmailData>();
        emailDataList.add(new EmailData('Test Subject', 'Test Body', new List<String>()));
        
        Test.startTest();
        EmailService.sendEmail(emailDataList);
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        
        // Verify Results, because no emails are sent, should return 0 invocations
        Assert.areEqual(0, emailInvocations, 'No emails should have been sent');
    }

    /** 
     * Tests that the scheduleJob method properly schedules the job 
     */
    @isTest
    private static void testScheduleJob(){

        Test.startTest();
        InterviewReminderJobScheduler.scheduleJob();
        InterviewReminderJobScheduler.scheduleJob(); // Schedule Job twice to test the duplicate check functionality.
        Test.stopTest();

        // Verify job was scheduled
        List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Interview Reminder Job'
        ];
        // Assert that exactly one job is scheduled with the name "Interview Reminder Job"
        Assert.isTrue(jobs.size() == 1, 'Scheduler should have exactly one scheduled job');
    }

    /**
     * Test that the scheduler class will properly kick off the functionality
     */
    @isTest
    private static void testExecuteJob(){

        // Create Data
        List<Event> eventList = TestDataScheduledJobs.generateData();
        // Execute code
        Test.startTest();
        new InterviewReminderJobScheduler().execute(null);        
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        // Verify Results
        Assert.areEqual(1, emailInvocations, 'No emails were sent!');
    }
}