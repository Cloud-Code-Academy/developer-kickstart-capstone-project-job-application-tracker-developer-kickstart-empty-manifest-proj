trigger JobApplicationTrigger on Job_Application__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        JobApplicationTriggerHandler.beforeInsertUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter) {
        JobApplicationTriggerHandler.afterInsertUpdate(Trigger.new, Trigger.oldMap);
    }
}
