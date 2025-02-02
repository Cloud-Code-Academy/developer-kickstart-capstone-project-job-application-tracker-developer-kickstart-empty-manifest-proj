/*
* 
* The ApplicationContactTriggerhandler class executes the following actions:
* 
* - After Insert:
*    - setPrimaryContacts: If the Job Application for the Application Contact does not have a Primary Contact,
*         update the Primary_Contact__c field to the Contact on the Application Contact record.
* 
* - After Update:
*    - setPrimaryContacts: If the Job Application for the Application Contact does not have a Primary Contact,
*         update the Primary_Contact__c field to the Contact on the Application Contact record.
* 
* - After Undelete:
*    - setPrimaryContacts: If the Job Application for the Application Contact does not have a Primary Contact,
*         update the Primary_Contact__c field to the Contact on the Application Contact record.
* 
*/
public with sharing class ApplicationContactTriggerHandler extends TriggerHandler {
    // Create class variables
    private List<Application_Contact__c> newList;
    
    // Constructor sets the Trigger context variables to the correct SObject type    
    public ApplicationContactTriggerHandler() {
        this.newList = (List<Application_Contact__c>)Trigger.new;
    }

    /*
    * 
    * After Save Methods
    * 
    */

    // After Insert method updates Primary Contact field if null
    public override void afterInsert() {
        ApplicationContactUtils.setPrimaryContacts(newList);
    }

    // After Update method updates Primary Contact field if null
    public override void afterUpdate() {
        ApplicationContactUtils.setPrimaryContacts(newList);

    }

    // After Undelete method updates Primary Contact field if null
    public override void afterUndelete() {
        ApplicationContactUtils.setPrimaryContacts(newList);

    }
}