/*
* 
* JobApplicationUtils class executes static methods called from the JobApplicationTriggerHandler.cls class:
* 
* - setPrimaryContact: For all Job Applications, if the Primary_Contact__c field is null, see if the Job Application has any 
*         Application Contact records. If so, use the first one to set a new Primary Contact
* 
* - checkStatus: Check if the Status of the Job App has been updated
* 
* - createTasks: For each possible Status, generate and insert specific Tasks
* 
* - taskCreation: Create a task and populate all fields
* 
* - createAppContact: check for existing Application Contact records and make one for the Job App's Primary Contact if none found
* 
* - setFollowUpDate: Set the Follow-Up Date to 1 week from run date
* 
*/
public with sharing class JobApplicationUtils {
    /*
    * 
    * setPrimaryContact identifies all Job Application records that are missing Primary_Contact__c.
    * It then finds Application Contact records for the Job Applications and saves the first one for
    * each of the Apps. If at least one was found, use that Contact as the App's Primary Contact
    * 
    * @param apps: list of Job Application records
    */
    public static void setPrimaryContact(List<Job_Application__c> apps) {
        // Create a list to hold the IDs of the Job Apps that are missing Primary Contact
        List<Id> appIds = new List<Id>();
        // Create a map to hold the App Id for each App Contact that will be used
        Map<Id, Id> contactsForApps = new Map<Id, Id>();
        // Create a list of the Apps to be updated
        List<Job_Application__c> jobApps = new List<Job_Application__c>();

        // Get the Id of every Job Application that needs a Primary Contact
        for (Job_Application__c app: apps) {
            if (app.Primary_Contact__c == null) {
                appIds.add(app.Id);
            }
        }

        if (!appIds.isEmpty()) {
            // Get all Application Contacts for Job Applications that need a Primary Contact
            List<Application_Contact__c> contacts = [SELECT Id, Name, Job_Application__c, Contact__c FROM Application_Contact__c WHERE Job_Application__c IN :appIds];
            if (!contacts.isEmpty()) {
                for (Application_Contact__c con : contacts) {
                    // If no contact has been found yet for an application, record this one
                    if (!contactsForApps.keySet().contains(con.Job_Application__c)) {
                        contactsForApps.put(con.Job_Application__c, con.Contact__c);
                    }
                }
            }

            if (!contactsForApps.isEmpty()) {
                // Get the records that need a Primary Contact and retrieve contact from map and set it on the Job App
                List<Job_Application__c> appToUpdate = [SELECT Id, Name, Primary_Contact__c FROM Job_Application__c WHERE Id IN :appIds];
                for (Job_Application__c app : appToUpdate) {
                    app.Primary_Contact__c = contactsForApps.get(app.Id);
                    jobApps.add(app);
                }
                // Update the Apps to have Primary Contact
                update jobApps;
            }
        }
    }

    /*
    * 
    * checkStatus takes a list of updated records and a map of the old values and returns a list of the
    * records in which the Status has been updated
    * 
    * @param newApps: a list of updated records. Example: Trigger.new
    * @param oldApps: a map of the newApps records prior to update. Example: Trigger.oldMap
    * 
    * @return appsWithNewStatus: a list of records whose Status has changed from oldApps to newApps
    * 
    */
    public static List<Job_Application__c> checkStatus(List<Job_Application__c> newApps, Map<Id, Job_Application__c> oldApps) {
        // Create a list to hold the Job Apps with changed Status
        List<Job_Application__c> appsWithNewStatus = new List<Job_Application__c>();

        // For each of the newApps apps, if the status has changed, add the Job App to the new list
        for (Job_Application__c app : newApps){
            if (app.Status__c != oldApps.get(app.Id).Status__c) {
                appsWithNewStatus.add(app);
            }
        }
        // Return the list of Job Applications whose Status has changed
        return appsWithNewStatus;
    }

    /*
    * 
    * createTasks creates and inserts tasks corresponding to the Status of each Job Application in the passed in list
    * 
    * @param apps: a list of Job Application records
    * 
    */
    public static void createTasks(List<Job_Application__c> apps) {
        // Create a list to hold the new Tasks to be inserted
        List<Task> newTasks = new List<Task>();

        // Loop through all Job Apps
        for (Job_Application__c app : apps) {
            // Create 4 Tasks if the record has Status "Saved"
            if (app.Status__c == 'Saved'){
                newTasks.add(taskCreation(app, 5, 'Confirm Salary', 'Normal','Check the job posting or company website to confirm the Salary and update it on the job Application.'));
                newTasks.add(taskCreation(app, 5, 'Check Job Description For Fit', 'High','Check if the job description aligns with your interests and values.'));
                newTasks.add(taskCreation(app, 5, 'Review Highlighted Skills for Fit', 'Normal','Review the highlighted skills to see if the role is a good fit.'));
                newTasks.add(taskCreation(app, 5, 'Research Company/Role and Rate Job', 'Low','Research the company or role and mark your excitement level.'));

            // Create 5 Tasks if the record has Status "Applying"
            } else if (app.Status__c == 'Applying'){
                newTasks.add(taskCreation(app, 5, 'Find Employee and Add as a Related Contact', 'Normal','Find and research someone who works at the company and add them as a contact.'));
                newTasks.add(taskCreation(app, 7, 'Set Up Informational Interview', 'Normal','Set up an informational interview to learn more about the role/company.'));
                newTasks.add(taskCreation(app, 5, 'Identify Potential Referrals', 'Low','Identify potential referrals to help get your application on the top of the pile.'));
                newTasks.add(taskCreation(app, 3, 'Customize Work Achievements', 'Normal','Customize your work achievements using the job description keywords.'));
                newTasks.add(taskCreation(app, 3, 'Submit Application', 'High','Submit your application, on the company website if possible.'));

            // Create 4 Tasks if the record has Status "Applied"    
            } else if (app.Status__c == 'Applied'){
                newTasks.add(taskCreation(app, 1, 'Make Contact', 'High','Reach out to the hiring manager or recruiter.'));
                newTasks.add(taskCreation(app, 7, 'Follow Up on Application', 'Normal','Follow up on your application via email weekly.'));
                newTasks.add(taskCreation(app, 4, 'Continue Applying', 'Low','Continue identifying and saving similar job opportunities.'));
                newTasks.add(taskCreation(app, 7, 'Set Up Weekly Networking Calls', 'Low','Set up weekly networking calls to explore similar companies/roles.'));

            // Create 5 Tasks if the record has Status "Interviewing"
            } else if (app.Status__c == 'Interviewing'){
                newTasks.add(taskCreation(app, 1, 'Prepare Blurb', 'High','Prepare your blurb or “tell me about yourself” response.'));
                newTasks.add(taskCreation(app, 1, 'Practice Answering Questions', 'High','Practice answering behavioral interview questions.'));
                newTasks.add(taskCreation(app, 1, 'Research Company', 'High','Research the company and your interviewers.'));
                newTasks.add(taskCreation(app, 1, 'Set Up Space and Test Tech', 'High','Set up your virtual interview space and test your tech.'));
                newTasks.add(taskCreation(app, 1, 'Send Thank You Email', 'High','Send thank you emails within 24 hours.'));

            // Create 3 Tasks if the record has Status "Negotiating"
            } else if (app.Status__c == 'Negotiating'){
                newTasks.add(taskCreation(app, 4, 'Research Market Value', 'Normal','Research your market value and know your numbers.'));
                newTasks.add(taskCreation(app, 4, 'Prepare Negotiation Script', 'Normal','Prepare your negotiation scripts.'));
                newTasks.add(taskCreation(app, 5, 'Evaluate Offer', 'High','Evaluate your offer and decline or accept.'));

            // Create 3 Tasks if the record has Status "Accepted"
            } else if (app.Status__c == 'Accepted'){
                newTasks.add(taskCreation(app, 7, 'Plan Resignation, if Applicable', 'Low','Plan your resignation if applicable.'));
                newTasks.add(taskCreation(app, 7, 'Relax and Recharge', 'High','Take some time to relax and recharge.'));
                newTasks.add(taskCreation(app, 7, 'Prepare for First Day', 'Normal','Prepare for your first day of onboarding.'));

            // Create 2 Tasks if the record has Status "Closed"
            } else if (app.Status__c == 'Closed'){
                newTasks.add(taskCreation(app, 1, 'Send Follow-Up Email', 'High','Send a follow-up email thanking the interviewer and asking for feedback.'));
                newTasks.add(taskCreation(app, 5, 'Review and Reflect', 'Normal','Review your notes and reflect on areas of improvement.'));
            }
        }

        if (!newTasks.isEmpty()) {
            try {
                // Insert the new Task records
                    insert newTasks;
            } catch (Exception e) {
                system.debug('Unable to create Tasks for Job Application. Error: ' + e.getMessage());
            }
        }
    }

    /*
    * 
    * taskCreation takes a Job Application and some field values and returns a Task related to that Job App
    * and with those custom field values.
    * 
    * @param app: a Job Application to which the Task will be related
    * @param days: the number of days from now until when the Task will be due
    * @param taskSubject: the Subject for the Task
    * @param taskPriority: the priority level of the Task
    * @param taskDescription: the description of what is need to complete the Task
    * 
    * @return newTask: a new Task
    * 
    */
    public static Task taskCreation (Job_Application__c app, Integer days, String taskSubject, String taskPriority, String taskDescription) {
        // Create a Task and populate its fields
        Task newTask = new Task();
        newTask.Subject = taskSubject;
        newTask.WhatId = app.Id;
        newTask.ActivityDate = Date.today().addDays(days);
        newTask.OwnerId = UserInfo.getUserId();
        newTask.Status = 'Not Started';
        newTask.Priority = taskPriority;
        newTask.description = Taskdescription;
        
        // If the Job App has a Primary Contact, use it for the WhoId on the Task
        if (app.Primary_Contact__c != null) {
            newTask.WhoId = app.Primary_Contact__c;
        }

        // Return the new Task
        return newTask;
    }

    /* 
    * checkForPrimaryChange takes a list of Applications and a map of their former values and if the Primary_Contact__c 
    * value has changed, it searches to see if the new Primary Contact already has an Application Contact record
    * for that Job App. It returns all that do not.
    * 
    * @param newApps: the updated Job Application records. Example: Trigger.new
    * @param oldApps: the previous values of the Job Apps. Example: Trigger.oldMap
    * 
    * @return newApps: the list of Job Applications that have had their Primary Contact changed
    * 
    */    
    public static List<Job_Application__c> checkForPrimaryChange (List<Job_Application__c> newApps, Map<Id, Job_Application__c> oldApps) {
        // Create a list and populate it with all App Contacts related to the passed in Apps
        List<Application_Contact__c> existingAppContacts = [SELECT Id, Contact__c, Job_Application__c FROM Application_Contact__c WHERE Job_Application__c IN :newApps];
        // Map to match Contacts with the Apps they are associated with
        Map<Id, List<Id>> contactWithApps = new Map<Id, List<Id>>();
        // List to hold the Job Apps with changed Primary Contacts
        List<Job_Application__c> newPrimaries = new List<Job_Application__c>();

        // Add each Contact with a App Contact record to a map with its Job Apps
        for (Application_Contact__c appCon : existingAppContacts) {
            // If The Contact is already in the map, add the Job App to the List of App IDs
            if (contactWithApps.keySet().contains(appCon.Contact__c)) {
                contactWithApps.get(appCon.Contact__c).add(appCon.Job_Application__c);
            // If the Contact is not in the map yet, add the Contact and a new List of App IDs to the map
            } else {
                List<Id> appId = new List<Id>();
                appId.add(appCon.Job_Application__c);
                contactWithApps.put(appCon.Contact__c, appId);
            }
        }

        // For each Job App, if the Primary is changed and not null, check if the map contains the new Primary
        for (Job_Application__c app : newApps) {
            if (app.Primary_Contact__c != oldApps.get(app.id).Primary_Contact__c && app.Primary_Contact__c != null) {
                // Check the Map keyset for the Primary Contact
                if (contactWithApps.containsKey(app.Primary_Contact__c)) {
                    // If the List for the new Primary contains the Job App, continue to the next loop iteration
                    if (contactWithApps.get(app.Primary_Contact__c).contains(app.Id)) {
                        continue;
                    }
                }
                // If the Map does not contain the Contact or if it does and the List does not have the App, 
                // add the App to the list to return
                newPrimaries.add(app);
            }
        }

        // Return the list of the Job Apps with a new Primary value and no corresponding App Contact
        return newPrimaries;
    }

    /* 
    * createAppContact takes a list of Applications that are either new or have just had their Primary Contact 
    * value changed, and it creates the new record.
    * 
    * @param apps: the updated Job Application records.
    * 
    */
    public static void createAppContact (List<Job_Application__c> apps) {
        // Create a list to hold the records that need to be created
        List<Application_Contact__c> applicationContactsToCreate = new List<Application_Contact__c>();

        // If the list of apps is not empty
        for (Job_Application__c jobApp : apps) {
            if (jobApp.Primary_Contact__c != null) {
                Application_Contact__c newAppContact = new Application_Contact__c();
                newAppContact.Contact__c = jobApp.Primary_Contact__c;
                newAppContact.Job_Application__c = jobApp.Id;
                newAppContact.Role__c = 'Primary Contact';
                applicationContactsToCreate.add(newAppContact);
            }
        }

        // Create any needed new Application Contact records
        if (!applicationContactsToCreate.isEmpty()) {
            try {
                // Insert the new Application Contact records
                insert applicationContactsToCreate;
            } catch (Exception e) {
                system.debug('Unable to create Application Contacts for Job Application. Error: ' + e.getMessage());
            }
            
        }
    }

    /* 
    * setFollowUpDate sets the Follow-Up Date field to 7 days from today.
    * 
    * @param apps: the updated Job Application records.
    * 
    */
    public static void setFollowUpDate (List<Job_Application__c> apps) {
        // For each Job Application, set the Follow-Up date to 10 days from today
        for (Job_Application__c app : apps) {
            app.Follow_Up_Date__c = Date.today().addDays(7);
            system.debug('follow-up date: ' + app.Follow_Up_Date__c);
        }
    }
}