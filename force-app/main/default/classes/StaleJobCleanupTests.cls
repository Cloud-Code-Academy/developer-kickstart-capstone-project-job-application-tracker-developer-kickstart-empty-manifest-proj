@isTest
public with sharing class StaleJobCleanupTests {
    
    @isTest
    public static void testStaleJobCleanupWithMultipleBatches() {

        // Bypass JobApplicationTriggerHandler to prevent validation during test data setup
        TriggerHandler.bypass('JobApplicationTriggerHandler');        
        // Create stale records to test process when completing multiple batch runs
        Integer staleRecords = 200;
        List<Job_Application__c> staleApps = new List<Job_Application__c>();
        for(Integer i = 0; i < staleRecords; i++){
            Job_Application__c newStale = new Job_Application__c(
                Status__c = 'Saved',
                Follow_up_Date__c = Date.today().addDays(-31)
            );
            staleApps.add(newStale);
        }
        // Include one app with Filled out Notes section to test functionality
        staleApps[8].Notes__c = 'Notes has some text already in it';

        // Insert stale records
        insert staleApps;

        // Create fresh records for negative test
        Integer freshRecords = 25;
        List<Job_Application__c> freshApps = new List<Job_Application__c>();
        for(Integer i = 0; i < freshRecords; i++){
            Job_Application__c newFresh = new Job_Application__c(
                Status__c = 'Saved',
                Follow_up_Date__c = Date.today()
            );
            freshApps.add(newFresh);
        }

        // Insert fresh records
        insert freshApps;

        // Start the batch job
        Test.startTest();
        Database.executeBatch(new StaleJobCleanupBatch(), 200);
        Test.stopTest();

        // Verify stale records were updated
        List<Job_Application__c> updatedStaleApps = [
            SELECT Id, Status__c, Notes__c
            FROM Job_Application__c
            WHERE Id IN :staleApps
        ];

        for (Job_Application__c app : updatedStaleApps){
            Assert.areEqual('Closed', app.Status__c, 'Stale record status should be Closed');
            Assert.isTrue(app.Notes__c.contains('Job Application was closed by an automated process'),
                                                'Notes field should be updated with automation details');
        }
        
        // Verify fresh records were untouched
        List<Job_Application__c> untouchedFreshApps = [
            SELECT Id, Status__c, Notes__c
            FROM Job_Application__c
            WHERE Id IN :freshApps
            ];
            
        for (Job_Application__c app : untouchedFreshApps){
            Assert.areEqual('Saved', app.Status__c, 'Fresh record status should be Saved');
            Assert.isTrue(String.isBlank(app.Notes__c), 'Notes field for fresh records should remain empty');
        }
        // **Clear the bypass after inserting test data**
        TriggerHandler.clearBypass('EventTriggerHandler');        
    }

    @isTest
    public static void testStaleJobCleanupScheduler(){

        // Schedule the job within the test context
        Test.startTest();
        StaleJobCleanupScheduler.scheduleJob();
        StaleJobCleanupScheduler.scheduleJob();  // Schedule job twice to test the duplicate check functionality
        Test.stopTest();

        // Verify the scheduled job was created
        List<CronTrigger> scheduledJob = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Stale Job Cleanup'
        ];

        // Verify exactly one job exists (scheduler works and duplicate check works)
        Assert.isTrue(scheduledJob.size() == 1, 'Exactly one scheduled job should exist');
    }
}