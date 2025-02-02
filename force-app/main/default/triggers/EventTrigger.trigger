/*
* 
* EventTrigger will fire in the following circumstances:
* - before insert
* - before update
* 
* All logic and actions will be exeuted in the EventTriggerhandler.cls class
* 
*/

trigger EventTrigger on Event (before insert, before update) {
    // Create an instance of the EventTriggerhandler and run it
    EventTriggerHandler eventTriggerInstance = new EventTriggerHandler();
    eventTriggerInstance.run();
}