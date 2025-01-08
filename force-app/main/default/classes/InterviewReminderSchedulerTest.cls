@isTest
private class InterviewReminderSchedulerTest {
    // Scheduler sends reminder emails for interviews scheduled on weekdays
    @isTest
    static void testInterviewReminderScheduler_Weekday() {
        //compute a valid weekday date(skip weekends)
        Date activityDate = System.today().addDays(1);
        Integer dayOfWeek = activityDate.toStartOfWeek().daysBetween(activityDate);
        while(dayOfWeek == 0 || dayOfWeek == 6) {
            activityDate = activityDate.addDays(1);
            dayOfWeek = activityDate.toStartOfWeek().daysBetween(activityDate);
        }

        //create test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.JMHARRIS12345',
            Alias = 'jmharris',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Job_Application__c testApplication = new Job_Application__c(
            Name = 'Test Job Application',
            Company_Account__c = testAccount.Id,
            OwnerId = testUser.Id
        );
        insert testApplication;

        // Create a test Event scheduled for tomorrow
        Event testEvent = new Event(
            WhatId = testApplication.Id,
            Subject = 'Interview - Technical Round',
            startDateTime = activityDate,
            DurationInMinutes = 60
        );
        insert testEvent;

        // Execute scheduler
        Test.startTest();
        InterviewReminderScheduler scheduler = new InterviewReminderScheduler();
        scheduler.execute(null);
        Test.stopTest();

        //Asset event exists and no errors occurred
        Event[] events = [
        SELECT Id, Subject, ActivityDate
        FROM Event
        WHERE WhatId = :testApplication.Id
        ];

        System.assertEquals(1, events.size(), 'There should be one event related to the application.');
    }
    
        // Handle case when no interview events are found for tomorrow
    @isTest
    private static void test_no_emails_sent_when_no_interviews() {
        // Arrange - no events created for tomorrow
        
        Test.startTest();
        
        InterviewReminderScheduler scheduler = new InterviewReminderScheduler();
        scheduler.execute(null);
        
        Test.stopTest();
    
        // Assert
        Integer emailInvocations = Limits.getEmailInvocations();
        System.assertEquals(0, emailInvocations, 'No emails should be sent when no interviews exist');
    }
    

}