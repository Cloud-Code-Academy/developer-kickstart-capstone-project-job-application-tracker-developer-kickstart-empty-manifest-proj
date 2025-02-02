/*
* 
* EventUtils class executes static methods called from the EventTriggerHandler.cls class:
* 
* - eventOverlapValidate: Ensures that any Event does not overlap with any other
*  
*/
public with sharing class EventUtils {
    /*
    * 
    * eventOverlapValidate checks all current and future events to ensure that the new Events do not
    * conflict/overlap with existing events.
    * 
    * @param newEvents: list of Event records. Example: Trigger.new
    */
    public static void eventOverlapValidate(List<Event> newEvents) {
        Datetime rightNow = Datetime.now();
        List<Event> existingEvents = [SELECT Id, Subject, StartDateTime, EndDateTime FROM Event WHERE EndDateTime > :rightNow];

        // Compare each new/updated Event with existing Events
        for (Event newEvent : newEvents) {
            for (Event existingEvent : existingEvents) {
                if (newEvent.StartDateTime >= existingEvent.StartDateTime && newEvent.StartDateTime <= existingEvent.EndDateTime) {
                    // Error saying that it starts during existing event
                    newEvent.addError('The event is set to start during an existing event.');
                    
                    // Exit the loop
                    break;

                } else if (newEvent.EndDateTime >= existingEvent.StartDateTime && newEvent.EndDateTime <= existingEvent.EndDateTime) {
                    // Error saying that it ends during an existing event
                    newEvent.addError('The event is set to end during an existing event.');
                    
                    // Exit the loop
                    break;

                } else if (newEvent.StartDateTime <= existingEvent.StartDateTime && newEvent.EndDateTime >= existingEvent.EndDateTime) {
                    // Error saying that it encompasses an existing event
                    newEvent.addError('The event is set to start before an existing event and end after it.');

                    // Exit the loop
                    break;
                }
            }
        }
    }

    /*
    * 
    * checkEventTimeChange checks if either the start or end time for an Event is fine
    * 
    * @param newEvents: list of Event records. Example: Trigger.new
    * @param oldEvents: map of previous Event values. Example: Trigger.oldMap
    * 
    * @return newTimes: a list of Events whose times have changed
    */
    public static List<Event> checkEventTimeChange (List<Event> newEvents, Map<Id, Event> oldEvents) {
        // List to hold Events whose Start and/or End time has changed
        List<Event> newTimes = new List<Event>();

        // Add any Events with changed times to the the list
        for (Event e : newEvents) {
            if (e.StartDateTime != oldEvents.get(e.Id).StartDateTime || e.EndDateTime != oldEvents.get(e.Id).EndDateTime) {
                newTimes.add(e);
            }
        }

        // Return the Events with changed times
        return newTimes;
    }
}