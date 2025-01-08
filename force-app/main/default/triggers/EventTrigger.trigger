trigger EventTrigger on Event (before insert, before update) {
    EventTriggerHandler.validateMeetings(Trigger.new);
}