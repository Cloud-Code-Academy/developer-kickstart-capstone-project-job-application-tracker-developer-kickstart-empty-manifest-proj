/**
 * JobApplicationService
 *
 * This service class handles the processing and management of Job_Application__c records.
 * Responsibilities include:
 * - Creating new Account records based on company names pulled in from integration.
 * - Inserting Job_Application__c records into Salesforce.
 * 
 * This class is designed to work with data parsed from external job board integrations,
 * ensuring proper deduplication and efficient database operations.
 */

public with sharing class JobApplicationService {

    /**
     * Processes new Job Applications by:
     * - Removing the applications that already exist in the org
     * - Creating (where necessary) new Accounts and linking Accounts to Apps
     * - Inserting new Job_Application__c records
     * @param companyNames A set of unique company names from new Job Applications
     * @param idToJobAppMap A map of external job application IDs to job application records 
     */
    public static void processJobApplications(Set<String> companyNames, Map<String, Job_Application__c> idToJobAppMap) {

        // Remove existing Job Applications to prevent duplicates
        List<Job_Application__c> jobApplications = removeExistingJobApps(idToJobAppMap);
        
        // Create Accounts from company names and insert Account Records
        Map<String,Id> accNameToIdMap = prepareAccounts(companyNames);

        // Relate Job Applications to respective Accounts
        for(Job_Application__c app : jobApplications){
            app.Company__c = accNameToIdMap.get(app.Company_Name__c);
        }

        // Insert Job Application Records
        insertRecords(jobApplications, 'Job Application');
    }
    
    /**
     * Removes job applications that alrady exist in Salesforce, preventing duplicates
     * @param idToJobAppMap A map of external job application IDs to job application records
     * @return A list of job application records that do not already exist in Salesforce
     */
    private static List<Job_Application__c> removeExistingJobApps(Map<String, Job_Application__c> idToJobAppMap){

        for(Job_Application__c app : [SELECT Job_Integration_ID__c FROM Job_Application__c WHERE Job_Integration_ID__c IN :idToJobAppMap.keySet()]){
            // Remove Job Applications that are known duplicates from Map
            Job_Application__c removedApp = idToJobAppMap.remove(app.Job_Integration_ID__c);
        }        
        return idToJobAppMap.values();
    }
    
    /**
     * Prepares Account records by:
     * - Checking if the companies already exist in Salesforce
     * - Creating new Account records for those that do not yet exist in Salesforce
     * @param companyNames A set of unique company names.
     * @return A map of company names to Account IDs.
     */
    public static Map<String, Id> prepareAccounts(Set<String> companyNames){
        
        // Query for existing accounts
        List<Account> existingAccounts = [SELECT Id, Name FROM Account WHERE Name IN :companyNames];
        Map<String,Id> accNameToIdMap = new Map<String,Id>();
        for(Account acc : existingAccounts){
            if(companyNames.contains(acc.Name)){
                // Existing Accounts are mapped, name to Id, to facilitate relating them to corresponding job applications
                accNameToIdMap.put(acc.Name,acc.Id);
                // companyNames Set is reduced to only companies that do not yet exist in Salesforce
                companyNames.remove(acc.Name);
            }             
        }
        // If new companies exist, create and insert Account Records, then add to accNameToIdMap 
        if (!companyNames.isEmpty()){
            processNewCompanies(companyNames, accNameToIdMap);
        }        
        return accNameToIdMap;        
    }

    /**
     * Creates and inserts new Account records for companies that do not already exist in Salesforce.
     * Updates accompanying Account map with the new Accounts
     * @param companyNames A set of company names to create new Accounts for.
     * @param accNameToIdMap A map of existing (in SF) account names to account IDs.
     */    
    public static void processNewCompanies(Set<String> companyNames, Map<String,Id> accNameToIdMap){
        
        // Create Account Records for new companies 
        List<Account> accountsToCreate = new List<Account>();
        for(String company : companyNames){
            accountsToCreate.add(new Account(Name = company));
        }
        
        // Insert created Account Records        
        insertRecords(accountsToCreate, 'Account');

        // Add newly created Accounts to accNameToIdMap
        for(Account a : accountsToCreate){
            accNameToIdMap.put(a.Name, a.Id);
        }
    }

    /**
     * Sends an error notification email to System Admins.
     * @param subject The subject of the error email.
     * @param errorMessage Teh detailed error message to be sent
     */    
    public static void sendErrorEmail(String subject, String errorMessage){
        // Retrieve first System Admin Email (sorted alphabetically by LastName)
        List<User> admins = [SELECT Email
            FROM User
            WHERE Profile.Name = 'System Administrator' AND isActive = true AND Email != null
            ORDER BY LastName ASC
            LIMIT 1
        ];
        
        // Pull email into a List<String>
        List<String> adminEmails = new List<String>();
        if (!admins.isEmpty()){
            adminEmails.add(admins[0].Email);
        } else {
            return;
        }
        
        // Build EmailData object and send via EmailService
        String body = 'An error occurred: \n\n' + errorMessage;
        EmailData emailData = new EmailData(subject, body, adminEmails);
        EmailService.sendEmail(new List<EmailData>{emailData});    
    }

    /**
     * Inserts a list of sObjects and handles failures by logging and notifying admins
     * Used to insert the Accounts and Job Applications
     * @param records The list of records to insert.
     * @param recordType A label indicating the type of records being inserted (e.g., 'Account')
     * 
     */
    private static void insertRecords(List<SObject> records, String recordType){
        // Insert records of specified type and handle potential errors
        Database.SaveResult[] recordsResults = Database.insert(records, false);
        
        // Check results and log failures
        String errorMessage = '';
        Integer failureCount = 0;
        for(Integer i = 0; i< recordsResults.size(); i++){
            if(!recordsResults[i].isSuccess()){
                errorMessage += 'Record ' + (i+1) + ' failed:' + 
                                recordsResults[i].getErrors()[0].getMessage() + '\n';
                failureCount++;
            }
        }
        // If failures occurred, send an error notification
        if(failureCount > 0){
            String subject = failureCount + ' ' + recordType + 
                            (failureCount == 1 ? 'Record Failed' : 'Records Failed') +
                            ' to insert';            
            sendErrorEmail(subject, errorMessage);
        }
    }
}