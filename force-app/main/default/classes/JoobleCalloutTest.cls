@isTest
public with sharing class JoobleCalloutTest {

    /**
     * Test processing a valid API response with multiple records returning.
     * Ensures that Job applications are created correctly with valid data. 
     */
    @isTest
    static void testValidJoobleResponse() {

        // Set up mock for valid response
        HttpRequest request = new HttpRequest();

        Test.setMock(HttpCalloutMock.class, new JoobleCalloutMockResponse());

        // Run test
        Test.startTest();
        JoobleCallout callout = new JoobleCallout(new Map<String, String>(), 1);
        System.enqueueJob(callout);
        Test.stopTest();

        // Query records
        List<Job_Application__c> createdJobs = [SELECT Job_Integration_ID__c, Company_Name__c, Position_Title__c,
            Salary__c, Salary_Text__c
            FROM Job_Application__c];
    
        Assert.areEqual(5, createdJobs.size(), 'Three Job Applications should have been inserted into the database');
    
        // Validate proper formatting for salaries
        for(Job_Application__c job : createdJobs){
            if(job.Position_Title__c == 'Solution Architect'){
                Assert.areEqual(160000.00, job.Salary__c, 'Parsed salary should be 160k');
                Assert.areEqual('$150K - $160K', job.Salary_Text__c, 'Salary (Reported) is not coming through properly');
            } else if(job.Position_Title__c == 'Salesforce Developer'){
                Assert.areEqual(56000.00, job.Salary__c, 'Parsed salary should be 160k');
                Assert.areEqual('$24 - $28 per hour', job.Salary_Text__c, 'Salary (Reported) is not coming through properly');
            } else if(job.Position_Title__c == 'Business Analyst'){
                Assert.areEqual(140000.00, job.Salary__c, 'Parsed salary should be 160k');
                Assert.areEqual('$140k', job.Salary_Text__c, 'Salary (Reported) is not coming through properly');
            }
        }
    }

    /**
     * Test duplication preventions.  Job Applications coming in:
     * 1. Should correctly handle creation for both new and existing Accounts
     * 2. Should not duplicate if the same job has already pulled into the system.
     */
    @isTest
    static void testDuplicationPrevention() {

        // Create system data to interact with the data pulled in by callout
        List<Account> existingAccounts = new List<Account>{
            new Account(Name = 'First Solutions'), // Test for adding Job Application to existing Account
            new Account(Name = 'Second Corporation') // Associated with duped Job App
        };
        insert existingAccounts;
        // Create a duplicated Job Application to test rejecting dupes
        Job_Application__c app = new Job_Application__c(
            Position_Title__c = 'Salesforce Developer',
            Job_Description__c = 'Looking for an experienced Salesforce Developer...',
            Salary_Text__c = '$24 - $28 per hour',
            Salary__c = 56000.00,
            Company_Name__c = 'Second Corporation',
            Company__c = existingAccounts[1].Id,
            Job_Integration_ID__c = '67890'
        );
        insert app;

    
        // Set up mock for valid response
        HttpRequest request = new HttpRequest();

        Test.setMock(HttpCalloutMock.class, new JoobleCalloutMockResponse());

        // Run test
        Test.startTest();
        JoobleCallout callout = new JoobleCallout(new Map<String, String>(), 1);
        System.enqueueJob(callout);
        Test.stopTest();

        // Validate that the Job app was still created, though the Account was not duplicated
        Integer jobAppsForExistingAccount = [SELECT COUNT() FROM Job_Application__c WHERE Company__c = :existingAccounts[0].Id];
        Assert.areEqual(1, jobAppsForExistingAccount, 'Job Application should still insert for an existing Account');

        // Validate that An existing Job Application will not be duplicated
        Integer jobAppsForExistingApp  = [SELECT COUNT() FROM Job_Application__c WHERE Company__c = :existingAccounts[1].Id];
        Assert.areEqual(1, jobAppsForExistingApp , 'Applications should not be duplicated');
    }



    /** 
     * Tests that the scheduleJob method properly schedules the job 
     */
    @isTest
    static void testScheduleJob(){

        Test.startTest();
        JoobleScheduler.scheduleJob();
        JoobleScheduler.scheduleJob(); // Schedule Job twice to test the duplicate check functionality.
        Test.stopTest();

        // Verify job was scheduled
        List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Nightly Jooble Callout'
        ];
        // Assert that exactly one job is scheduled with the name "Interview Reminder Job"
        Assert.isTrue(jobs.size() == 1, 'Scheduler should have exactly one scheduled job');
    }

    /**
     * Test the JoobleSettingsCalloutService, ensuring that it properly enqueues a job when invoked.
     */
    @isTest
    static void testJoobleSettingsCalloutService(){

        // Run test
        Test.startTest();
        JoobleSettingsCalloutService.triggerJoobleCallout();
        Test.stopTest();

        // Verify job was enqueued
        Integer jobsEnqueued = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'];
        Assert.areEqual(1, jobsEnqueued, 'Queueable job should have been enqueued');
    }
}