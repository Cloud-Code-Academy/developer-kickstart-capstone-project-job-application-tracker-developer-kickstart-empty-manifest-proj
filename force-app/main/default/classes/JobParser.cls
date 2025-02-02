public with sharing class JobParser {
    
    /**
     * Parses the JSON response from the Jooble job board and converts it into a list of Job_Application__c records.
     * @param jsonResponse The JSON response from the API.
     * @return A list of Job_Application__c records.
     */
    public static void parseJoobleApps(String jsonResponseBody){        
        
        Map<String,Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonResponseBody);
        // If callout pulled back any jobs, iterate through to build Job Applications
        if(jsonMap.containsKey('jobs')){
            List<Object> jobs = (List<Object>) jsonMap.get('jobs');
            
            // Initialize a set to hold unique Account names and a map fro Job Application ext Ids = Job Application Record
            Set<String> companyNames = new Set<String>();
            Map<String, Job_Application__c> idToJobAppMap = new Map<String, Job_Application__c>();
                        
            // Build Job_Application__c records from jsonMap's jobs
            for(Object jobObject : jobs){
                Map<String,Object> job = (Map<String,Object>) jobObject;
                
                // Reject Jobs with null or blank company names
                if(String.isBlank((String)job.get('company'))){
                    continue;
                }
                
                // Create new Job_Application__c record from job
                Job_Application__c jobApp = new Job_Application__c();
                jobApp.Status__c = 'Saved';
                jobApp.Company_Name__c = (String)job.get('company');
                jobApp.Position_Title__c = (String)job.get('title');
                jobApp.Job_Posting_URL__c = (String)job.get('link');

                // Add External ID when present
                if(job.containsKey('id') && job.get('id') != null){
                    Object jobId = job.get('id');
                    // Handle multiple types
                    if(jobId instanceof String){
                        jobApp.Job_Integration_ID__c = (String)jobId;
                    } else if(jobId instanceof Integer){
                        jobApp.Job_Integration_ID__c = String.valueOf((Integer)jobId);
                    } else if(jobId instanceof Long){
                        jobApp.Job_Integration_ID__c = String.valueOf((Long)jobId);
                    } else{
                        System.debug('Unexpected job ID type: ' + jobId);
                        continue; // Skip this record, which has corrupted data
                    }                
                }
                
                // Clean Job Description Snippet of HTML tags and entities and set jobApp job description field
                String rawSnippet = (String)job.get('snippet');
                jobApp.Job_Description__c = rawSnippet
                    .replaceAll('<.*?>',' ')
                    .replaceAll('&amp;', ' ')
                    .replaceAll('&nbsp;', ' ')
                    .replaceAll('&lt;',' ')
                    .replaceAll('&gt;',' ')
                    .normalizeSpace();

                // Set salary only if present and valid
                if(job.containsKey('salary') && !String.isBlank((String)job.get('salary'))){
                   // jobApp.Salary__c = (Decimal)Integer.valueOf((String)job.get('salary'));                    
                    jobApp.Salary_Text__c = (String)job.get('salary');
                    // Send Text Salary to parsing subMethod to pull back a number
                    jobApp.Salary__c = parseSalary(jobApp.Salary_Text__c);                    
                }
                // Add current iterating jobApp and companyName to respective containers
                companyNames.add(jobApp.Company_Name__c);
                idToJobAppMap.put(jobApp.Job_Integration_ID__c, jobApp);
                
            }
            // Send Set of companyNames, then map of new Job Ids to jobApplications to be processed in Service Class
            JobApplicationService.processJobApplications(companyNames, idToJobAppMap);
        }
    }

    /**
     * Parses the raw salary text and calculates the approximate highest salary as a Decimal.
     * @param salaryText The raw salary text pulled back in the callout.
     * @return The approximate highest salary as a Decimal, or null if parsing fails.
     */
    private static Decimal parseSalary(String salaryText){

        // Check for error in transmitted Salry_Text__c field.
        if(String.isBlank(salaryText)){
            return null;
        }
        // Standardize input and initialize return variable
        salaryText = salaryText.trim().toLowerCase();
        Decimal annualSalary = null;

        // Process salary conversion in a Try-Catch block to account for non-standard information coming back from integration.
        try {
            if(salaryText.contains('-')){
                List<String> salaryBounds = salaryText.split('-');
                String upperBound = salaryBounds[1].trim();
                annualSalary = parseSingleSalary(upperBound);
            } else{
                annualSalary = parseSingleSalary(salaryText);
            }
        } catch (Exception e){
            System.debug('Error parsing salary: ' + salaryText + ' - ' + e.getMessage());
        }
        return annualSalary;
    }

    /**
     * Parses a single salary (text) and converts it to an annual salary (Decimal).
     * @param salaryText single salary to parse (e.g., "$80k" or "$50/hr")
     * @return annualSalary - a Decimal representation of the highest expected annual salary.
     */

    private static Decimal parseSingleSalary(String salaryText){

        // If salary pattern is unworkable return null
        if (String.isBlank(salaryText) || salaryText.containsNone('0123456789')) {
            return null;
        }

        // Initialize return variable and standardize input
        Decimal annualSalary;
        salaryText = salaryText.replace('$', '').replace(',', '').trim();
        

        // Handle known patterns
        if(salaryText.contains('hour') || salaryText.contains('hr')) {
            Decimal hourlyRate = Decimal.valueOf(salaryText.replaceAll('[^0-9.]', '').trim());            
            annualSalary = hourlyRate * 40 * 50; // Hourly Rate * 40 hours/week * 50 weeks/year
        } else if(salaryText.contains('k')){
            annualSalary = Decimal.valueOf(salaryText.replaceAll('[^0-9.]', '').trim()) * 1000;
        } else {
            annualSalary = Decimal.valueOf(salaryText.replaceAll('[^0-9.]', '').trim());
        }
        return annualSalary;
    }
}