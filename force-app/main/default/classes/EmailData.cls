/**
 * Class to enable smooth transport of email data from various pieces of code to the EmailService class
 * where emails are sent.
 */

public with sharing class EmailData {
    
    private String subject;
    private String body;
    private List<String> addresses;

    // Constructor with parameters
    public EmailData(String subject, String body, List<String> addresses) {
        this.subject = subject;
        this.body = body;
        this.addresses = addresses;
    }

    // Create public getter methods to access private class variables from other classes
    public String getSubject(){
        return subject;
    }
    
    public String getBody(){
        return body;
    }
    
    public List<String> getAddresses(){
        return addresses;
    }
}