public class JoobleAPIService implements Schedulable {

    //Endpoint URL and API Key
    private static final String ENDPOINT_URL = 'https://jooble.org/api/';
    private static final String API_KEY = '582b4f21-15e5-4540-b872-4c6519d9f781';

    /**
     * Fetches job posting from Jooble API based on search criteria.
     * @param keywards Search keywords.
     * @param location Search location.
     */
    public static void fetchJobs(String keywords, String location) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        //set request URL and method
        request.setEndpoint(ENDPOINT_URL + API_KEY);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        Date lastSyncDate = Date.today().addDays(-2);

        //Create JSON request body
        String requestBody = JSON.serialize(new Map<String, String>{
            'keywords' => keywords,
            'location' => location,
            'datecreatedfrom' => lastSyncDate.format()   
        });

        request.setBody(requestBody);

        try{
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200){
                //Parse JSON response
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                //Parse Job Data
                List<Object> jobs = (List<Object>) result.get('jobs');
                List<Job_Application__c> jobApplications = new List<Job_Application__c>();
                Map<String, Id> companyAccounts = new Map<String, Id>();

                for(Object jobObj : jobs){
                    Map<String, Object> job = (Map<String, Object>) jobObj;

                    //Check if company already exists, or create it
                    String companyName = (String) job.get('company');
                    Id accountId;
                    if(companyAccounts.containsKey(companyName)){
                        accountId = companyAccounts.get(companyName);
                    }else{
                        List<Account> existingAccounts = [
                            SELECT Id FROM Account
                            WHERE Name = :companyName
                            LIMIT 1
                        ];
                        if(!existingAccounts.isEmpty()){
                            accountId = existingAccounts[0].Id;
                        }else{
                            Account newAccount = new Account(Name = companyName);
                            insert newAccount;
                            accountId = newAccount.Id;
                        }
                        companyAccounts.put(companyName, accountId);
                    }

                    //check for duplicates
                    String jobTitle = (String) job.get('title'); //cast to string
                    List<Job_Application__c> existingApplications = [
                        SELECT Id FROM Job_Application__c
                        WHERE Name = :jobTitle AND Company_Account__c = :accountId LIMIT 1
                    ];
                    if(!existingApplications.isEmpty()){
                        continue;
                    }

                    Job_Application__c jobApp = new Job_Application__c();
                    jobApp.Name = (String) job.get('title');
                    jobApp.Status__c = 'Saved';
                    jobApp.Company_Account__c = accountId;
                    String snippet = (String) job.get('snippet');
                    jobApp.Description__c = snippet.stripHtmlTags();
                    jobApp.URL__c = (String) job.get('link');

                    if(job.containsKey('salary') && String.isNotBlank((String)job.get('salary'))){
                        string salaryStr = (String)job.get('salary');

                        //validate salary is numeric
                        if(!String.isBlank(salaryStr) && Pattern.matches('^[0-9]+(\\.[0-9]{1,2})?$', salaryStr)){
                            jobApp.Salary__c = Decimal.valueOf(salaryStr);
                        }else{
                            jobApp.Salary__c = null;
                        }
                    }
                    
                    jobApplications.add(jobApp);
                }

                //Insert Job Applications
                if(!jobApplications.isEmpty()){
                    insert jobApplications;
                }
            }else{
                System.debug('Error: ' + response.getStatus());
            }

        }catch(Exception e){
            System.debug('Error: ' + e.getMessage());

        }
    }
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new JoobleAPIQueueable('Salesforce', 'Remote'));
    }
}