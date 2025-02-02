/*
* 
* ApplicationContactUtils class executes static methods called from the ApplicationContactTriggerHandler.cls class:
* 
* - setPrimaryContacts: For all records, if the Primcary_Contact__c field on the parent Job Application is null,
*        set the parent Contact as the Primary COntact on the Job App 
*  
*/
public with sharing class ApplicationContactUtils {
    /*
    * 
    * setPrimaryContacts identifies all parent Job Application records that are missing Primary_Contact__c.
    * It then using the parent Contact from the Application Contact record as the App's Primary Contact
    * 
    * @param appContacts: list of Application Contact records
    */
    public static void setPrimaryContacts (List<Application_Contact__c> appContacts) {
        // Create a map to hold the parent App IDs matches with the Contacts
        Map<Id, Id> appIdsByContact = new Map<Id, Id>();
        // Create a list to hold the Apps that need to be updated with the new Primary Contact
        List<Job_Application__c> appsToUpdate = new List<Job_Application__c>();

        // For each passed in record, match its parent App record ID with the parent Contact ID
        for (Application_Contact__c con : appContacts){
            appIdsByContact.put(con.Job_Application__c, con.Contact__c);
        }

        // Get all the Application records for the App Contacts that are elligible to become Primary Contact
        List<Job_Application__c> apps = [SELECT Id, Name, Primary_Contact__c FROM Job_Application__c WHERE Id IN :appIdsByContact.keySet() AND Primary_Contact__c = null];

        // Prepare to update the Primary Contact field
        if (!apps.isEmpty()) {
            for (Job_Application__c app : apps) {
                app.Primary_Contact__c = appIdsByContact.get(app.Id);
                appsToUpdate.add(app);
            }
        }
        
        // Update the Job Applications if at least 1 of them has a new Primary Contact
        if(!appsToUpdate.isEmpty()){
            try {
                // Update the Job Apps
                update appsToUpdate;
            } catch (Exception e) {
                system.debug('Unable to update Primary Contact for Job Application. Error: ' + e.getMessage());
            }
        }
    }
}