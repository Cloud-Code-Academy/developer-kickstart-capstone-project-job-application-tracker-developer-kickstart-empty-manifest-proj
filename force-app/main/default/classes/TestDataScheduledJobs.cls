/**
 * Utility class to generate test data for scheduled job testing
 */
public with sharing class TestDataScheduledJobs {
    
    /**
     * Generates test data, including a Contact, User, Job Application
     * and 3 related Events, 2 negative cases and 1 positive case
     * 
     * @return List<Event> A list of test Event records inserted
     */
    public static List<Event> generateData() {

        // Bypass EventTriggerHandler to prevent validation during test data setup
        TriggerHandler.bypass('EventTriggerHandler');
        
        // Create and insert test contact
        Contact cont = new Contact(
            FirstName = 'John',
            LastName = 'Doe'
            );
            insert cont;
            
            // Create and insert a test User
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            User testUser = new User(
                FirstName = 'Jane',
                LastName = 'Doe',
                Username = 'jane.doe@example.com.' + System.currentTimeMillis(),
                Email = 'jane.doe@example.com',
            Alias = 'jdoe',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/New_York',  
            LocaleSidKey = 'en_US',             
            EmailEncodingKey = 'UTF-8',    
            LanguageLocaleKey = 'en_US' 
            );
            insert testUser;
            
            // Create and insert a test Job Application record linked to the test user and test contact
            Job_Application__c testApp = new Job_Application__c(
                Position_Title__c = 'Salesforce Developer',
                Company_Name__c = 'Cloud Code Academy',
                Primary_Contact__c = cont.id,
                OwnerId = testUser.Id
        );
        insert testApp;
        
        // Create and insert 3 Events, 2 negative and 1 positive to test query
        List<Event> eventList = new List<Event>();
        for(Integer i = 0; i < 3; i++){
            Event newEvent = new Event(
                Subject = 'Technical Interview ' + i,
                WhoId = cont.Id,
                WhatId = testApp.Id,
                StartDateTime = datetime.now().addDays(i),
                OwnerId = testUser.Id
                );
                newEvent.EndDateTime = newEvent.StartDateTime.addHours(2);
                eventList.add(newEvent);
            }
            insert eventList;

            // **Clear the bypass after inserting test data**
            TriggerHandler.clearBypass('EventTriggerHandler');
            
            return eventList;
            
        }
        
    /**
     * Generate additional data to more thoroughly test EmailService functionality
     * - Add a valid event where Owner has no email to test handling that gracefully
     * - Add Multiple valid events to test Bulk Email Sending
     */
        
    public static List<Event> generateMoreData(){
            
            
        // Pull in standard data
        List<Event> baseEvents = generateData();

        // Bypass EventTriggerHandler to prevent validation during test data setup
        TriggerHandler.bypass('EventTriggerHandler');

        // Retrieve test Contact & Job Application
        Id contactId = baseEvents[0].WhoId;
        Id jobAppId = baseEvents[0].WhatId;
        Id ownerId = baseEvents[0].OwnerId; // has valid email
        
        // Create and insert another Event Owner with separate Email
        Profile ownerProfile = [Select Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User secondEmailUser = new User(
            FirstName = 'anotherEmail',
            LastName = 'User',
            UserName = 'aEmail@example.com.' + System.currentTimeMillis(),
            Email = 'aemail@example.com',
            Alias = 'auser',
            ProfileId = ownerProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
            );
        insert secondEmailUser;
            
        // Initialize Event list 
        List<Event> newEvents = new List<Event>();
            
        // Generate event owned by a separate user with separate email address
        Event secondEmailEvent = new Event(
            Subject = 'Secondary User Email',
            WhoId = contactId,
            WhatId = jobAppId,
            OwnerId = secondEmailUser.Id,
            StartDateTime = DateTime.now().addDays(1)
            );
        secondEmailEvent.EndDateTime = secondEmailEvent.StartDateTime.addHours(1);
        newEvents.add(secondEmailEvent);
            
        // Create additional valid Events for Bulk Testing
        for(Integer i = 0; i < 25; i++){
            Event bulkEvent = new Event(
                Subject = 'Bulk Event ' + i,
                WhoId = contactId,
                WhatId = jobAppId,
                ownerId = ownerId,
                StartDateTime = DateTime.now().addDays(1)
                );
                bulkEvent.EndDateTime = bulkEvent.StartDateTime.addHours(1);
                newEvents.add(bulkEvent);
            }
        // Insert events
        insert newEvents;
                
        // **Clear the bypass after inserting test data**
        TriggerHandler.clearBypass('EventTriggerHandler');

        return newEvents;
    }
}