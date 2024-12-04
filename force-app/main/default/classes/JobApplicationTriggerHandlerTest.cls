@isTest
public with sharing class JobApplicationTriggerHandlerTest {

    @isTest
    static void jobApplicationPrimaryContactPositive() {
        Account acc1 = new Account(Name='account1');
        insert acc1;
        Contact con1 = new Contact(LastName='con1',AccountId=acc1.Id);
        insert con1;
        Job_Application__c jobApp1 = new Job_Application__c(Name='jobapp1',Company_Name__c=acc1.Id);
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        jobApps.add(jobApp1);

        Test.startTest();
            insert jobApps;
        Test.stopTest();

        List<Job_Application__c> jobAppsNew = [SELECT Id,Primary_Contact__c FROM Job_Application__c];
    
        System.assertEquals(con1.Id,jobAppsNew[0].Primary_Contact__c,'No Contact should be attached.');
    }

    @isTest
    static void jobApplicationPrimaryContactNegative() {
        Account acc1 = new Account(Name='account1');
        insert acc1;
        Contact con1 = new Contact(LastName='con1',AccountId=acc1.Id);
        insert con1;
        Job_Application__c jobApp1 = new Job_Application__c(Name='jobapp1');
        List<Job_Application__c> jobApps = new List<Job_Application__c>();
        jobApps.add(jobApp1);

        Test.startTest();
            insert jobApps;
        Test.stopTest();

        List<Job_Application__c> jobAppsNew = [SELECT Id,Primary_Contact__c FROM Job_Application__c];

        System.assertEquals(null,jobAppsNew[0].Primary_Contact__c,'no contact should be populated');

    }

    // Test method for initial insert and task creation
    @isTest
    static void testInsertJobApplication(){
        // Setup test data
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        insert newAccount;

        Contact newContact = new Contact();
        newContact.FirstName = 'Test';
        newContact.LastName = 'Contact';
        newContact.AccountId = newAccount.Id;
        insert newContact;

        Job_Position__c newJob = new Job_Position__c();
        newJob.Name = 'Test Job';
        newJob.Account__c = newAccount.Id;
        insert newJob;

        // Create a new Job Application record
        Job_Application__c newApp = new Job_Application__c();
        newApp.Status__c = 'Saved';
        newApp.Applicant__c = newContact.Id;
        newApp.Job_Position__c = newJob.Id;
        newApp.Name = 'Test Application';
        
        Test.startTest();
        insert newApp;
        Test.stopTest();

        List<Task> tasks = 
            [SELECT 
                Subject, 
                Description, 
                Status,
                WhatId,
                WhoId 
            FROM Task
            WHERE WhatId = :newApp.Id];

        // Assert task creation
        System.assertEquals(1, tasks.size(), 'There should be one task created, actual created: ' + tasks.size());
        System.assertEquals('Application status has changed to Saved', tasks[0].Subject, 'The task subject should be "Application status has changed to Saved", actual: ' + tasks[0].Subject);
        
        String expectedSavedDescription =   '1. Check if the job description aligns with your interests and value' + '\n' +
                                            '2. Review the highlighted skills to see if the role is a good fit' + '\n' +
                                            '3. Research company or role and mark your excitement level';
        System.assertEquals(expectedSavedDescription, tasks[0].Description, 'The task description should be ' + expectedSavedDescription + ', actual: ' + tasks[0].Description);
        System.assertEquals(newContact.Id, tasks[0].WhoId, 'The task should be associated with the correct Contact record');
        System.assertEquals(newApp.Id, tasks[0].WhatId, 'The task should be associated with the correct Job Application record');
    }

    // Test method for updating job application without status change
    @isTest
    static void testUpdateJobApplicationWithoutStatusChange(){
        // Setup test data
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        insert newAccount;

        Contact newContact = new Contact();
        newContact.FirstName = 'Test';
        newContact.LastName = 'Contact';
        newContact.AccountId = newAccount.Id;
        insert newContact;

        Job_Position__c newJob = new Job_Position__c();
        newJob.Name = 'Test Job';
        newJob.Account__c = newAccount.Id;
        insert newJob;

        Job_Application__c newApp = new Job_Application__c();
        newApp.Status__c = 'Saved';
        newApp.Applicant__c = newContact.Id;
        newApp.Job_Position__c = newJob.Id;
        newApp.Name = 'Test Application';
        insert newApp;

        // Update the record but keep the status the same
        newApp.Description__c = 'Test Description';

        Test.startTest();
        update newApp;
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject, Description, Status, WhatId, WhoId FROM Task WHERE WhatId = :newApp.Id];

        // Assert no new task created
        System.assertEquals(1, tasks.size(), 'No task should be created after the update');
    }

    // Test method for updating job application with status change
    @isTest
    static void testUpdateJobApplicationWithStatusChange(){
        // Setup test data
        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        insert newAccount;

        Contact newContact = new Contact();
        newContact.FirstName = 'Test';
        newContact.LastName = 'Contact';
        newContact.AccountId = newAccount.Id;
        insert newContact;

        Job_Position__c newJob = new Job_Position__c();
        newJob.Name = 'Test Job';
        newJob.Account__c = newAccount.Id;
        insert newJob;

        Job_Application__c newApp = new Job_Application__c();
        newApp.Status__c = 'Saved';
        newApp.Applicant__c = newContact.Id;
        newApp.Job_Position__c = newJob.Id;
        newApp.Name = 'Test Application';
        insert newApp;

        // Update status to Negotiating
        newApp.Status__c = 'Negotiating';

        Test.startTest();
        update newApp;
        Test.stopTest();

        List<Task> tasks = [SELECT Subject, Description, Status, WhatId, WhoId FROM Task WHERE WhatId = :newApp.Id];

        // Assert that two tasks have been created
        System.assertEquals(2, tasks.size(), 'There should be two tasks created, actual created: ' + tasks.size());
        System.assertEquals('Application status has changed to Negotiating', tasks[1].Subject, 'The task subject should be "Application status has changed to Negotiating", actual: ' + tasks[1].Subject);

        String expectedNegotiatingDescription = '1. Research salary ranges for the role and location' + '\n' +
                                                '2. Prepare your negotiation strategy' + '\n' +
                                                '3. Practice your negotiation script' + '\n' +
                                                '4. Set up a meeting with your manager to discuss your offer' + '\n' +
                                                '5. Review the benefits package and ask questions';
        System.assertEquals(expectedNegotiatingDescription, tasks[1].Description, 'The task description should be ' + expectedNegotiatingDescription + ', actual: ' + tasks[1].Description);
        System.assertEquals(newContact.Id, tasks[1].WhoId, 'The task should be associated with the correct Contact record');
        System.assertEquals(newApp.Id, tasks[1].WhatId, 'The task should be associated with the correct Job Application record');
    }
}
