public with sharing class JobBoardService {
    
    /**
     * Fetches job search parameters for given job board (e.g., "Jooble")
     * @param jobBoard The name of the job board to be used (e.g., "Jooble")
     * @return Map containing json key-value pairs for specific job board 
     */
    public static Map<String,String> getJobSearchParams(String jobBoard){

        // Initialize return map
        Map<String, String> paramMap = new Map<String, String>();

        // Query Job App Settings to pull back settings for callout
        List<Job_App_Settings__c> settingsList = [SELECT Id, Desired_Location__c, Desired_Salary__c, Keyword__c
            FROM Job_App_Settings__c
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];

        Job_App_Settings__c settings;
        if (settingsList.isEmpty()){
            // No Job App Settings record exists, create new record with default settings
            settings = createDefaultSettingsRecord();            
        } else {
            settings = settingsList[0];
        }

        // Configure map according to Specific Job Board. This is a placeholder for future job board integrations.
        // Currently supports only Jooble, but if extended to other job boards, custom metadata/settings would be used.
        if(jobBoard == 'Jooble'){
            // Store parameters in map
            if(!String.isBlank(settings.Desired_Location__c)){
                paramMap.put('location', settings.Desired_Location__c);
            }
            if(!String.isBlank(settings.Keyword__c)){
                paramMap.put('keywords', settings.Keyword__c);
            }
            if(settings.Desired_Salary__c != null){
                paramMap.put('salary', String.valueOf((Integer)settings.Desired_Salary__c));
            }
        }
        return paramMap;        
    } 
    
    /**
     * Creates and inserts a default Job App Settings record if none exists
     * @return The newly created Job_App_Settings__c record to be used in the immediate callout
     */
    private static Job_App_Settings__c createDefaultSettingsRecord(){

        Job_App_Settings__c settings = new Job_App_Settings__c(
            Desired_Location__c = 'Remote',
            Keyword__c = 'Salesforce Administrator Developer'
        );
        insert settings;
        return settings;
    }
}
