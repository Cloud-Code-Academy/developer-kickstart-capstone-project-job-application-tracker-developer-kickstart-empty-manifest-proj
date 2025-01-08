global class InterviewReminderScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        // Query events for interviews scheduled tomorrow
        List<Event> events = [
            SELECT Id, Subject, WhatId, StartDateTime
            FROM Event
            WHERE StartDateTime = NEXT_N_DAYS:1
            AND Subject Like 'Interview%'
        ];

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for(Event event : events){
            //Retrieve related Job Applications
            Job_Application__c application = [
                SELECT Id, Owner.Email
                FROM Job_Application__c
                WHERE Id = :event.WhatId
                LIMIT 1
            ];

            String ownerEmail = application.Owner.Email;

            if(ownerEmail != null){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{ ownerEmail});
                email.setSubject('Interview Reminder '+ event.Subject);
                email.setPlainTextBody('You have an interview scheduled on ' + event.StartDateTime + '.\n\nDetails: ' + event.Subject);
                emailsToSend.add(email);
            } 
        }

        if(!emailsToSend.isEmpty()){
            Messaging.sendEmail(emailsToSend);
        }
    }
}