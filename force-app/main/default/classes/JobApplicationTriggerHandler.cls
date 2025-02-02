/*
* 
* The JobApplicationTriggerHandler class executes the following actions:
* 
* - Before Update:
*    - setPrimaryContact: use associated Application Contact records to 
*         ensure records have a Primary Contact
* 
* - After Insert:
*   - createTasks: create tasks whenever the status of an application changes
*   - createAppContact: when Primary Contact is set or updated, make sure there
*         is an Application Contact record for that Contact and Application
* 
* - After Update:
*   - createTasks: create tasks whenever the status of an application changes
*   - createAppContact: when Primary Contact is set or updated, make sure there
*         is an Application Contact record for that Contact and Application
* 
*/
public with sharing class JobApplicationTriggerHandler extends TriggerHandler{
    // Create class variables
    private List<Job_Application__c> newList;
    private Map<Id, Job_Application__c> oldMap;

    // Constructor sets the Trigger context variables to the correct SObject type
    public JobApplicationTriggerHandler() {
        this.newList = (List<Job_Application__c>)Trigger.new;
        this.oldMap = (Map<Id,Job_Application__c>)Trigger.oldMap;
    }

    /*
    * 
    * Before Save Methods
    * 
    */

    // Before Insert method sets the Follow-Up Date field and sets the Job App Name
    public override void beforeInsert() {
        for (Job_Application__c app : newList) {
            String fullName = app.Company_Name__c + ' - ' + app.Position_Title__c;
            // Ensure that the name is not more than 150 characters
            if (fullName.length() > 80) {
                app.Name = fullName.substring(0, 80);
            } else {
                app.Name = fullName;
            }
        }
        JobApplicationUtils.setFollowUpDate(newList);
    }

    // Before Update method sets the Follow-Up Date field for Apps with changed Status
    public override void beforeUpdate() {
        List<Job_Application__c> appsWithNewStatus = JobApplicationUtils.checkStatus(newList, oldMap);
        if (!appsWithNewStatus.isEmpty()) {
            JobApplicationUtils.setFollowUpDate(appsWithNewStatus);
        }
    }

    /*
    * 
    * After Save Methods
    * 
    */
    
    // After Insert methods create Tasks and App Contact related records
    public override void afterInsert() {
        JobApplicationUtils.createTasks(newList);
        JobApplicationUtils.createAppContact(newList);
    }

    // After Update methods create Tasks and App Contact related records and set Primary Contact
    public override void afterUpdate() {
        // Set Primary Contact if it is null
        JobApplicationUtils.setPrimaryContact(newList);
        
        // Use checkStatus to only create tasks for Job Apps with changed Status
        List<Job_Application__c> appsWithNewStatus = JobApplicationUtils.checkStatus(newList, oldMap);
        if (!appsWithNewStatus.isEmpty()) {
            JobApplicationUtils.createTasks(appsWithNewStatus);
        }
        // Use checkForPrimaryChange to only create Application Contacts who have new Primary Contacts
        List<Job_Application__c> appsWithNewPrimary = JobApplicationUtils.checkForPrimaryChange(newList, oldMap);
        if (!appsWithNewPrimary.isEmpty()) {
            JobApplicationUtils.createAppContact(appsWithNewPrimary);
        }
    }
}