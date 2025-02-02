/*
* 
* JobApplicationTrigger will fire in the following circumstances:
* 
* - before insert
* - before update
* - after insert
* - after update
* 
* All logic and actions will be executed in the JobApplicationTriggerHandler.cls class
* 
*/

trigger JobApplicationTrigger on Job_Application__c (before insert, before update, after insert, after update) {
    // Create an instance of the JobApplicationTriggerHandler and run it
    JobApplicationTriggerHandler jobAppTrigger = new JobApplicationTriggerHandler();
    jobAppTrigger.run();
}