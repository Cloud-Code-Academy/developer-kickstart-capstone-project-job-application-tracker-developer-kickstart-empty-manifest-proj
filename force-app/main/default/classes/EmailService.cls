/**
 * EmailService
 * 
 * This service class provides a utility method to send emails in Salesforce. It is designed to handle 
 * various email-sending scenarios in a reusable and scalable way.
 */

public with sharing class EmailService {

    /**
     * Sends email(s) to the specified list of recipients.
     * 
     * This method constructs single email messages for each item in the parameter listwith a subject and body,
     * then sends it to all recipients provided. If the operation fails, an error message 
     * is logged to aid in debugging.
     * 
     * @param emailDataList -- A list of instances of the EmailData class, each holding the necessary
     * components (Subject, Body, List of email addresses) to send a single email to a list of recipients.
     */ 
    public static void sendEmail(List<EmailData> emailDataList){
        if(emailDataList.isEmpty()){
            return;
        }
    
        // Build Messaging.SingleEmailMessage instances and add to list to send
        List<Messaging.SingleEmailMessage> semList = new List<Messaging.SingleEmailMessage>();
        for(EmailData emailData : emailDataList){
            if(emailData.getAddresses().isEmpty()){
                continue;
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(emailData.getAddresses());
            mail.setSubject(emailData.getSubject());
            mail.setPlainTextBody(emailData.getBody());
            semList.add(mail);
        }
        if(semList.isEmpty()){
            return;
        }
        // Bulk send emails
        try{
            Messaging.SendEmailResult[] results = Messaging.sendEmail(semList, false);
            // Log success/failure for each email
            for(Integer i = 0; i < results.size(); i++){
                // pull in EmailData reference to access using non-static getter method
                EmailData emailData = emailDataList[i];
                if(results[i].isSuccess()){
                    System.debug('EmailService.sendEmail: ' + emailData.getSubject() + ' email sent successfully to ' +
                        emailData.getAddresses() + '.');
                } else{
                    System.debug('EmailService.sendEmail: ' + emailData.getSubject() + ' email FAILED to send to ' +
                        emailData.getAddresses() + '.\n- Error: ' + results[i].getErrors()[0].getMessage());
                }
            }
        } catch (Exception e){
            System.debug('EmailService.sendEmail: Error sending email - ' + e.getMessage());
        }
    }
}