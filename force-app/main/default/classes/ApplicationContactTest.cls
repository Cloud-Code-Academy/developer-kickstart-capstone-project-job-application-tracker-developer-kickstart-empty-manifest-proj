/*
* 
* ApplicationContactTest.cls contains test code for ApplicationContactTrigger.trigger as well as the following classes:
*      - ApplicationContactTriggerHandler.cls
*      - ApplicationContactUtils.cls
* 
* - testSetPrimaryContacts: Upon creation or update, if the related Job Application does not have a Primary_Contact__c,
*      use the related Contact to set the Job App's Primary_Contact__c
*  
*/
@isTest
public with sharing class ApplicationContactTest {
    /*
    * 
    * testSetPrimaryContact creates Contacts, Job Application and Application Contact records and checks the 
    * ApplicationContactUtils.setPrimaryContacts method.
    * 
    * The test method checks both that records are created and that duplicate records are not created.
    *  
    */
    @isTest
    public static void testSetPrimaryContacts() {
        // Create 2 Contacts: Contact 1 and Contact 2
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
        Job_Application__c app2 = new Job_Application__c();
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

        // Insert the Application Contacts
        Test.startTest();
        insert appConList;
        Test.stopTest();

        // Query the Job Applications by Primary Contact
        List<Job_Application__c> checkApp1 = [SELECT Id, Name, Primary_Contact__c FROM Job_Application__c WHERE Primary_Contact__c = :createdContacts[0].Id];
        List<Job_Application__c> checkApp2 = [SELECT Id, Name, Primary_Contact__c FROM Job_Application__c WHERE Primary_Contact__c = :createdContacts[1].Id];

        // Check that App 1 has not had its Primary Contact overwritten by making sure checkApp1 has exactly 1 record
        Assert.areEqual(1, checkApp1.size(), 'You have the wrong number of Job Applications with Contact 1');
        // Check that App 2 has not had its Primary Contact overwritten by making sure checkApp2 has exactly 1 record
        Assert.areEqual(1, checkApp2.size(), 'You have the wrong number of Job Applications with Contact 2');
    }
}