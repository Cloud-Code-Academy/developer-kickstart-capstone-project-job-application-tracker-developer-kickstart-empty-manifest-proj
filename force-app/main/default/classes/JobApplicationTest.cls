/*
* 
* JobApplicationTest.cls contains test code for JobApplicationTrigger.trigger as well as the following classes:
*      - JobApplicationTriggerHandler.cls
*      - JobApplicationUtils.cls
* 
* - testSetPrimaryContact: Checks that if Primary_Contact__c is null and the record is updated or undeleted, if the
*      record has any Application Contacts, use the first one to set Primary_Contact__c
* 
* - testCreateTasksCreation: Checks that the proper number of tasks have been created when record is created
* 
* - testCreateTasksUpdated: Checks that the proper number of tasks have been created when record is updated
* 
* - testCreateAppContact: If Primary_Contact__c is changed, make sure that a related contact record is created
*      without creating a duplicate
* 
* - testSetFollowUpDateCreation: Check when the App is created, the Follow-Up date is a week from today
*
* - testSetFollowUpDateUpdated: Check that if the Status has changed, the Follow-Up date is a week from today
* 
* - testSetName: Check that the Name was set correctly
*  
*/
@isTest
public with sharing class JobApplicationTest {
    /*
    * 
    * testSetPrimaryContact creates Contacts, Job Application and Application Contact records and checks the 
    * ApplicationContactUtils.setPrimaryContacts method.
    * 
    * The test method checks both that records are created and that duplicate records are not created.
    *  
    */
    @isTest
    public static void testSetPrimaryContact() {
        // Make 2 Contacts
        List<Contact> contactList = new List<Contact>();
        for (Integer i = 0; i<2; i++) {
            Contact con = new Contact();
            con.FirstName = String.valueOf(i+1);
            con.LastName = 'McTesty';
            contactList.add(con);
        }
        // Insert the Contacts
        insert contactList;

        // Query the created Contacts
        List<Contact> createdContacts = [Select Id, FirstName, LastName FROM Contact ORDER BY FirstName];

        // Make 2 Job Apps. Have Contact 1 as primary contact on App 1 and no primary on App 2
        Job_Application__c app1 = new Job_Application__c(Primary_Contact__c = createdContacts[0].Id);
        Job_Application__c app2 = new Job_Application__c(Primary_Contact__c = createdContacts[0].Id);
        List<Job_Application__c> appList = new List<Job_Application__c>{app1, app2};

        // Insert the Job Applications
        insert appList;
        
        // Query the created Job Applications
        List<Job_Application__c> createdApps = [SELECT Id, Name, Primary_Contact__c FROM Job_Application__c ORDER BY Name];

        // Make 2 App Contact records: Contact 2 for each Job App
        Application_Contact__c appCon1 = new Application_Contact__c();
        appCon1.Job_Application__c = createdApps[0].Id;
        appCon1.Contact__c = createdContacts[1].Id;
        Application_Contact__c appCon2 = new Application_Contact__c();
        appCon2.Job_Application__c = createdApps[1].Id;
        appCon2.Contact__c = createdContacts[1].Id;
        List<Application_Contact__c> appConList = new List<Application_Contact__c>{appCon1, appCon2};

        insert appConList;

        // Find the Application Contact record to remove
        List<Application_Contact__c> removeAppCons = [SELECT Id FROM Application_Contact__c WHERE Contact__c = :createdContacts[0].Id];
        delete removeAppCons;

        // Update app 1 to add a Company and update app 2 to remove the primary contact (make null) and its first Application Contact record. 
        createdApps[0].Company_Name__c = 'Test Company';
        createdApps[1].Primary_Contact__c = null;

        test.startTest();
        update createdApps;
        test.stopTest();

        // Check that App 1 is still Contact 1 and App 2 is now Contact 2 by checking each Contact has 1 Job App
        // Query the Job Applications by Primary Contact
        List<Job_Application__c> checkApp1 = [SELECT Id, Name, Primary_Contact__c FROM Job_Application__c WHERE Primary_Contact__c = :createdContacts[0].Id];
        List<Job_Application__c> checkApp2 = [SELECT Id, Name, Primary_Contact__c FROM Job_Application__c WHERE Primary_Contact__c = :createdContacts[1].Id];

        // Check that App 1 has not had its Primary Contact overwritten by making sure checkApp1 has exactly 1 record
        Assert.areEqual(1, checkApp1.size(), 'You have the wrong number of Job Applications with Contact 1');
        // Check that App 2 has not had its Primary Contact overwritten by making sure checkApp2 has exactly 1 record
        Assert.areEqual(1, checkApp2.size(), 'You have the wrong number of Job Applications with Contact 2');

    }

    /*
    * 
    * testCreateTasksCreation creates Job Application records and checks that Tasks are created.
    * 
    * The test method checks that the correct number of Tasks are created for each Status option.
    *  
    */
    @isTest
    public static void testCreateTasksCreation() {
        // Create a list of Job Apps to create
        List<Job_Application__c> jobApps= new List<Job_Application__c>();
        // Create list of Statuses
        List<String> appStatus = new List<String>{
            'Saved',
            'Applying',
            'Applied',
            'Interviewing',
            'Negotiating',
            'Accepted',
            'Closed',
            null
        };
        // Create 1 app with each status and 1 with no Status
        for (Integer i = 0; i < appStatus.size(); i++) {
            Job_Application__c app = new Job_Application__c(Status__c = appStatus[i]);
            jobApps.add(app);
        }

        test.startTest();
        insert jobApps;
        test.stopTest();

        // Query the created Job Apps with their Tasks
        List<Job_Application__c> createdApps = [SELECT Id, Name, Status__c, (SELECT Id, Subject FROM Tasks) FROM Job_Application__c];
        
        // Ensure that each app has the correct number of tasks
        for (Job_Application__c app : createdApps) {
            if (app.Status__c == 'Saved') {
                // 4 Tasks should be created when an App's Status is 'Saved'
                Assert.areEqual(4, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Applying') {
                // 5 Tasks should be created when an App's Status is 'Applying'
                Assert.areEqual(5, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Applied') {
                // 4 Tasks should be created when an App's Status is 'Applied'
                Assert.areEqual(4, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Interviewing') {
                // 5 Tasks should be created when an App's Status is 'Interviewing'
                Assert.areEqual(5, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Negotiating') {
                // 3 Tasks should be created when an App's Status is 'Negotiating'
                Assert.areEqual(3, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Accepted') {
                // 3 Tasks should be created when an App's Status is 'Accepted'
                Assert.areEqual(3, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Closed') {
                // 2 Tasks should be created when an App's Status is 'Closed'
                Assert.areEqual(2, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else {
                // No Tasks should be created when an App's Status is null or another value
                Assert.areEqual(0, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');
            }
        }
    }

    /*
    * 
    * testCreateTasksCreation creates Job Application records and checks that Tasks are created.
    * 
    * The test method checks that the correct number of Tasks are created for each Status option.
    *  
    */
    @isTest
    public static void testCreateTasksUpdated() {
        // Create a list of Job Apps to create
        List<Job_Application__c> jobApps= new List<Job_Application__c>();
        // Create list of Statuses
        List<String> appStatus = new List<String>{
            'Saved',
            'Applying',
            'Applied',
            'Interviewing',
            'Negotiating',
            'Accepted',
            'Closed',
            null
        };
        // Create 1 app with each status and 1 with no Status
        for (Integer i = 0; i < appStatus.size(); i++) {
            Job_Application__c app = new Job_Application__c();
            jobApps.add(app);
        }

        insert jobApps;

        // Query the created Job Apps and update Status
        List<Job_Application__c> createdApps = [SELECT Id, Name, Status__c FROM Job_Application__c];

        for (Integer i = 0; i < appStatus.size(); i++) {
            createdApps[i].Status__c = appStatus[i];
        }

        test.startTest();
        update createdApps;
        test.stopTest();

        // Query the created Job Apps with their Tasks
        List<Job_Application__c> updatedApps = [SELECT Id, Name, Status__c, (SELECT Id, Subject FROM Tasks) FROM Job_Application__c];
        
        // Ensure that each app has the correct number of tasks
        for (Job_Application__c app : updatedApps) {
            if (app.Status__c == 'Saved') {
                // 4 Tasks should be created when an App's Status is 'Saved'
                Assert.areEqual(4, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Applying') {
                // 5 Tasks should be created when an App's Status is 'Applying'
                Assert.areEqual(9, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Applied') {
                // 4 Tasks should be created when an App's Status is 'Applied'
                Assert.areEqual(8, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Interviewing') {
                // 5 Tasks should be created when an App's Status is 'Interviewing'
                Assert.areEqual(9, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Negotiating') {
                // 3 Tasks should be created when an App's Status is 'Negotiating'
                Assert.areEqual(7, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Accepted') {
                // 3 Tasks should be created when an App's Status is 'Accepted'
                Assert.areEqual(7, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else if (app.Status__c == 'Closed') {
                // 2 Tasks should be created when an App's Status is 'Closed'
                Assert.areEqual(6, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');

            } else {
                // No Tasks should be created when an App's Status is null or another value
                Assert.areEqual(4, app.Tasks.size(), 'An incorrect number of tasks were created for this Job Application');
            }
        }
    }

    /*
    * 
    * testCreateAppContact creates Contact, Job Application and Application Contact records.
    * 
    * The test method checks that Application Contact records are created via automation only if the 
    * needed junction object record does not already exist. It ensures that automation will not make 
    * duplicate records.
    *  
    */
    @isTest
    public static void testCreateAppContact() {
        // Make a contact
        Contact newCon = new Contact(FirstName = '1', LastName = 'McTesty');
        
        // Insert the Contact
        insert newCon;

        // Query the new Contact
        Contact createdContact = [SELECT Id FROM Contact LIMIT 1];

        // Make 2 Job Apps
        Job_Application__c jobApp1 = new Job_Application__c();
        Job_Application__c jobApp2 = new Job_Application__c();
        List<Job_Application__c> apps = new List<Job_Application__c>{jobApp1, jobApp2};
        
        // Insert the Job Apps
        insert apps;

        // Query the created Applications
        List<Job_Application__c> createdApps = [SELECT Id, Primary_Contact__c FROM Job_Application__c];

        // Make App Contact record for Contact and App 1
        Application_Contact__c appCon = new Application_Contact__c(Job_Application__c = createdApps[0].Id, Contact__c = createdContact.Id);

        // Insert the Application Contact
        insert appCon;

        // Add Contact to both Apps as Primary Contact
        for (Job_Application__c app : createdApps) {
            app.Primary_Contact__c = createdContact.Id;
        }

        // Update the Job Apps
        test.startTest();
        update createdApps;
        test.stopTest();

        // Query the Job Apps again
        List<Job_Application__c> updatedApps = [SELECT Id, Primary_Contact__c, (SELECT Id FROM Application_Contacts__r) FROM Job_Application__c];

        for (Job_Application__c app : updatedApps) {
            // Triggers if the Application Contact record is not created for App 2 via automation
            Assert.areNotEqual(0, app.Application_Contacts__r.size(), 'Your Application Contact record has not been created.');
            
            // Triggers if duplicate Application Contact is created for App 1 via automation
            Assert.areNotEqual(2, app.Application_Contacts__r.size(), 'You have created a duplicate Application Contact record.');
            
            // Final check for edge cases where multiple duplicates are made somehow
            Assert.areEqual(1, app.Application_Contacts__r.size(), 'You have not created the correct number of Application Contact records.');
        }
    }

    /*
    * 
    * testFollowUpDateCreation checks that Apps are created with a Follow-Up Date a week from today.
    *  
    */
    @isTest
    public static void testFollowUpDateCreation() {
        // Identify the correct date for the Follow-Up date field
        Date correctDate = Date.today().addDays(7);

        // Create test data
        List<Job_Application__c> apps = new List<Job_Application__c>();
        for (Integer i=0; i < 10; i++) {
            Job_Application__c newApp = new Job_Application__c();
            apps.add(newApp);
        }

        // Insert the records
        test.startTest();
        insert apps;
        test.stopTest();

        // Query the created Applications
        List<Job_Application__c> createdApps = [SELECT Id, Status__c, Follow_Up_Date__c FROM Job_Application__c];

        // Check that the automation worked correctly
        for (Job_Application__c app : createdApps) {
            Assert.areEqual(correctDate, app.Follow_Up_Date__c, 'The Follow-Up Date is incorrect.');
        }
    }

    /*
    * 
    * testFollowUpDateUpdated checks that the Follow-Up Date for Apps with updated Status is a week from today.
    * 
    * The method ensures that the date is only updated if the Status is changed.
    *  
    */
    @isTest
    public static void testFollowUpDateUpdated() {
        // Identify the correct date for the Follow-Up date field
        Date correctDate = Date.today().addDays(7);

        // Create test data
        List<Job_Application__c> apps = new List<Job_Application__c>();
        for (Integer i=0; i < 10; i++) {
            Job_Application__c newApp = new Job_Application__c();
            apps.add(newApp);
        }

        // Insert the records
        insert apps;

        // Query the created Applications
        List<Job_Application__c> createdApps = [SELECT Id, Status__c, Follow_Up_Date__c, Position_Title__c FROM Job_Application__c];

        // Remove the Follow-Up Date from all the apps
        for (Job_Application__c app : createdApps) {
            app.Follow_Up_Date__c = null;
        }

        // Update the Apps
        update createdApps;

        // Update the Status of half the records and the Position/Title of the other half
        for (Integer i = 0; i < createdApps.size(); i++) {
            if (Math.mod(i, 2) == 0) {
                createdApps[i].Status__c = 'Applied';
            } else {
                createdApps[i].Position_Title__c = 'Official Tester';
            }
        }

        // Update the Apps
        update createdApps;

        // Query the updated Apps
        List<Job_Application__c> updatedApps = [SELECT Id, Status__c, Follow_Up_Date__c, Position_Title__c FROM Job_Application__c];
        // Create counters for Asserts
        Integer statusCounter = 0;
        Integer positionCounter = 0;

        // Check that the automation worked correctly
        for (Integer i = 0; i < updatedApps.size(); i++) {
            if (Math.mod(i,2) == 0) {
                // Even records should have a correct Follow-Up Date
                Assert.areEqual(correctDate, updatedApps[i].Follow_Up_Date__c, 'The Follow-Up Date is incorrect.');
                // Increment the counter
                statusCounter++;
            } else {
                // Odd records should not have a Follow-Up Date as the Status was not updated
                Assert.areEqual(null, updatedApps[i].Follow_Up_Date__c, 'This record should not have a Follow-Up Date.');
                // Increment the counter
                positionCounter++;
            }
        }

        // Check that 5 of each record were processed
        Assert.areEqual(5, statusCounter, 'The Follow-Up date is not populated on the correct number of records.');
        Assert.areEqual(5, positionCounter, 'The Follow-Up date is not null on the correct number of records.');
    }

    /*
    * 
    * testSetName checks that the name was set correctly upon record creation.
    * 
    * Format: [Company Name] - [Role]
    *  
    */
    @isTest
    public static void testSetName() {
        // Create the test Job Applications
        List<Job_Application__c> appList = new List<Job_Application__c>();

        for (Integer i = 0; i < 10; i++) {
            Job_Application__c newApp = new Job_Application__c();
            newApp.Company_Name__c = 'Company #' + i;
            newApp.Position_Title__c = 'Official Tester #' + i;
            appList.add(newApp);
        }

        // Generate the list of desired App names
        List<String> appNames = new List<String>();

        for (Integer i = 0; i < 10; i++) {
            appNames.add('Company #' + i + ' - Official Tester #' + i);
        }

        // Insert the Apps
        test.startTest();
        insert appList;
        test.stopTest();

        // Query the created Apps
        List<Job_Application__c> createdApps = [SELECT Id, Name FROM Job_Application__c];

        // Check that the values of the App's names match those in the generated list of names
        for (Integer i = 0; i< 10; i++) {
            Assert.areEqual(appNames[i], createdApps[i].Name, 'The Name of this Job Application is incorrect.');
        }
    }
}