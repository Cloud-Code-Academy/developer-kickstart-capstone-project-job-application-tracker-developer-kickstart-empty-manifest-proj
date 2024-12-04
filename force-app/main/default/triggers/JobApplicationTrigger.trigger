trigger JobApplicationTrigger on Job_Application__c (before insert, before update, after insert, after update) {
    System.debug('Trigger executed');
    JobApplicationTriggerHandler handler = new JobApplicationTriggerHandler();
    handler.run();
    }
