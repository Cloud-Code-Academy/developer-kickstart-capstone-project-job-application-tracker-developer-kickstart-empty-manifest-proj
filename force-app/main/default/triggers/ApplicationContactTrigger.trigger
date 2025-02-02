/*
* 
* ApplicationContactTrigger will fire in the following circumstances:
* - after insert
* - after update
* - after undelete
* 
* All logic and actions will be exeuted in the ApplicationContactTriggerhandler.cls class
* 
*/

trigger ApplicationContactTrigger on Application_Contact__c (after insert, after update, after undelete) {
    // Create an instance of the ApplicationContactTriggerHandler class and run it
    ApplicationContactTriggerHandler conAppTrigger = new ApplicationContactTriggerHandler();
    conAppTrigger.run();
}