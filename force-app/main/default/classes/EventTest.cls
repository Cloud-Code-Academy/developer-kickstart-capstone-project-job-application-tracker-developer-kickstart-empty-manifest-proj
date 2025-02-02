/*
* 
* EventTest.cls contains test code for EventTrigger.trigger as well as the following classes:
*      - EventTriggerHandler.cls
*      - EventUtils.cls
* 
* - testEventOverlapValidateCreation: Checks that new Events do not overlap with existing Events
* 
* - testEventOverlapValidateUpdated: Checks that updated Events do not overlap with other Events
*  
*/
@isTest
public with sharing class EventTest {
    /*
    * 
    * testEventOverlapValidateCreation attempts to make multiple Events, many of which overlap. Each
    * overlap is caught by the try-catch block
    * 
    */
    @isTest
    public static void testEventOverlapValidateCreation() {
        // Create Date (1 year from today) and Time (7 am) as base values
        Date eventDate = Date.today().addYears(1);
        Time baseTime = Time.newInstance(7, 0, 0, 0);

        // Make 1 Event that will be pre-existing. 1 Year from today, 8-10 AM
        Event existingEvent = new Event(Subject = 'Existing Event');
        existingEvent.StartDateTime = Datetime.newInstance(eventDate, baseTime.addHours(1));
        existingEvent.EndDateTime = Datetime.newInstance(eventDate, baseTime.addHours(3));

        // Insert that initial Event
        insert existingEvent;

        // Make an event that starts during that event, 9-11 AM
        Event invalidStart = new Event(Subject = 'Invalid Start Event');
        invalidStart.StartDateTime = Datetime.newInstance(eventDate, baseTime.addHours(2));
        invalidStart.EndDateTime = Datetime.newInstance(eventDate, baseTime.addHours(4));

        // Make an event that ends during that event, 7-9 AM
        Event invalidEnd = new Event(Subject = 'Invalid End Event');
        invalidEnd.StartDateTime = Datetime.newInstance(eventDate, baseTime);
        invalidEnd.EndDateTime = Datetime.newInstance(eventDate, baseTime.addHours(2));

        // Make an event that encompasses that event, 7-11 AM
        Event invlaidEncompass = new Event(Subject = 'Invalid Encompass Event');
        invlaidEncompass.StartDateTime = Datetime.newInstance(eventDate, baseTime);
        invlaidEncompass.EndDateTime = Datetime.newInstance(eventDate, baseTime.addHours(4));

        // Make an event that does not overlap with that event, 11-12 AM
        Event successfulEvent = new Event(Subject = 'Valid Event');
        successfulEvent.StartDateTime = Datetime.newInstance(eventDate, baseTime.addHours(4));
        successfulEvent.EndDateTime = Datetime.newInstance(eventDate, baseTime.addHours(5));

        // Make variable counters for unsuccessful inserts
        Integer failedEventCounter = 0;

        test.startTest();

        // Use a try-catch block to do the insert for invald Start time
        try {
            // Try to insert the events
            insert invalidStart;
        } catch (Exception e) {
            // Increment the failedEventCounter
            failedEventCounter++;
        }

        // Use a try-catch block to do the insert for invald End time
        try {
            // Try to insert the events
            insert invalidEnd;
        } catch (Exception e) {
            // Increment the failedEventCounter
            failedEventCounter++;
        }

        // Use a try-catch block to do the insert for the encompassing
        try {
            // Try to insert the events
            insert invlaidEncompass;
        } catch (Exception e) {
            // Increment the failedEventCounter
            failedEventCounter++;
        }

        // Use a try-catch block to do the insert for valid Event. This one SHOULD succeed.
        try {
            // Try to insert the events
            insert successfulEvent;
        } catch (Exception e) {
            // Increment the failedEventCounter
            failedEventCounter++;
        }

        test.stopTest();

        // Check that 3 Events were unable to be inserted. 
        Assert.areEqual(3, failedEventCounter, 'Did not find the correct number of failed event inserts');

    }

    /*
    * 
    * testEventOverlapValidateUpdated attempts to update multiple Events, many of which will overlap. Each
    * overlap is caught by the try-catch block
    * 
    */
    @isTest
    public static void testEventOverlapValidateUpdated() {
        // Create list of additional Events whose dates and times will be updated later
        List<Event> initialEvents = new List<Event>();

        // Create Date (1 year from today) and Time (7 am) as base values
        Date eventDate = Date.today().addYears(1);
        Time baseTime = Time.newInstance(7, 0, 0, 0);

        // Make 1 Event that will be pre-existing. 1 Year from today, 8-10 AM
        Event existingEvent = new Event(Subject = 'Existing Event');
        existingEvent.StartDateTime = Datetime.newInstance(eventDate, baseTime.addHours(1));
        existingEvent.EndDateTime = Datetime.newInstance(eventDate, baseTime.addHours(3));
        initialEvents.add(existingEvent);

        // Create 4 other initial events that will not overlap with the already created one
        for (Integer i = 0; i < 3; i++) {
            Event newEvent = new Event(Subject = 'New Event ' + i);
            newEvent.StartDateTime = Datetime.newInstance(eventDate.addYears(i), baseTime);
            newEvent.EndDateTime = Datetime.newInstance(eventDate.addYears(i), baseTime.addHours(1));
            initialEvents.add(newEvent);
        }

        // Insert those 5 initial Events
        insert initialEvents;

        // Query the created Events
        List<Event> createdEvents = [SELECT Id, Subject, StartDateTime, EndDateTime FROM Event];

        // Update an event so it starts during that initial event, 9-11 AM
        createdEvents[1].StartDateTime = Datetime.newInstance(eventDate, baseTime.addHours(2));
        createdEvents[1].EndDateTime = Datetime.newInstance(eventDate, baseTime.addHours(4));

        // Update an event so it ends during that initial event, 7-9 AM
        createdEvents[2].StartDateTime = Datetime.newInstance(eventDate, baseTime);
        createdEvents[2].EndDateTime = Datetime.newInstance(eventDate, baseTime.addHours(2));

        // Update an event so it encompasses that initial event, 7-11 AM
        createdEvents[3].StartDateTime = Datetime.newInstance(eventDate, baseTime);
        createdEvents[3].EndDateTime = Datetime.newInstance(eventDate, baseTime.addHours(4));

        // Make variable counters for unsuccessful inserts
        Integer failedEventCounter = 0;

        test.startTest();

        // Use a try-catch block to do the insert for invald Start time
        try {
            // Try to insert the events
            insert createdEvents[1];
        } catch (Exception e) {
            // Increment the failedEventCounter
            failedEventCounter++;
        }

        // Use a try-catch block to do the insert for invald End time
        try {
            // Try to insert the events
            insert createdEvents[2];
        } catch (Exception e) {
            // Increment the failedEventCounter
            failedEventCounter++;
        }

        // Use a try-catch block to do the insert for the encompassing
        try {
            // Try to insert the events
            insert createdEvents[3];
        } catch (Exception e) {
            // Increment the failedEventCounter
            failedEventCounter++;
        }

        test.stopTest();

        // Check that 3 Events were unable to be inserted. 
        Assert.areEqual(3, failedEventCounter, 'Did not find the correct number of failed event inserts');

    }
 
}