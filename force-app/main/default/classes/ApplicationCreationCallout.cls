public with sharing class ApplicationCreationCallout {
    @TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
    private static void createApplicationsFromJson(String jsonResponse) {
        // Deserialize the JSON string into map of primitive data types.
        Map<String,Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonResponse);
        List<Object> applications = (List<Object>) jsonMap.get('jobs');
        List<Job_Application__c> applicationRecords = new List<Job_Application__c>();

        //Create map of sobject (application) and company name
        Map<Job_Application__C,String> appToCompanyNameMap = new Map<Job_Application__C,String>();

        //Create set of account names
        Set<String> accountNameSet = new Set<String>(); 

        //Create a map of account names to Ids
        Map<String,Id> accountNameToIdMap = new Map<String,Id>();
        
        //Loop through application items to create applications and add them to list
        if(!applications.isEmpty()) {
            for(Object applicationItem : applications) {
                Map<String,Object> applicationMap = (Map<String,Object>) applicationItem;
                Job_Application__c applicationRecord = new Job_Application__c();
                String externalId = String.valueOf(applicationMap.get('id'));
                applicationRecord.External_Id__c = externalId;
                applicationRecord.Name = String.valueOf(applicationMap.get('title'));
                applicationRecord.Position_Title__c = String.valueOf(applicationMap.get('title'));
                applicationRecord.URL__c = String.valueOf(applicationMap.get('link'));
                applicationRecord.Location__c = String.valueOf(applicationMap.get('location'));
                String salary = String.valueOf(applicationMap.get('salary'));
                if(salary != null & salary != '' & salary.isNumeric()) {
                        applicationRecord.Salary__c = Integer.valueOf(salary);
                    }
                applicationRecord.Status__c = 'Saved';
                applicationRecords.add(applicationRecord);
                String companyName = String.valueOf(applicationMap.get('company'));
                accountNameSet.add(companyName);
                appToCompanyNameMap.put(applicationRecord,companyName);
            }
            
            //Convert accountNameSet to list
            List<String> accountNameList = new List<String>(accountNameSet);

            //Make a list of which accounts are in the system
            List<Account> existingAcctList = new List<Account>([SELECT Id, Name FROM Account WHERE Name in :accountNameList]);
            Map<String,Id> accountNamesThatExistMap = new Map<String,Id>();
            for (Account acc : existingAcctList) {
                accountNamesThatExistMap.put(acc.Name,acc.Id);
            }

            List<Account> newAccountList = new List<Account>();

            //Create accounts that are not in the system
            for (String acctName : accountNameList) {
                if (!accountNamesThatExistMap.containsKey(acctName)) {
                    Account newAcct = new Account(Name=acctName);
                    newAccountList.add(newAcct);
                }
            }
            insert newAccountList;
            
            //add all new accounts to Existing Accounts Map
            for (Account acc : newAccountList) {
                accountNamesThatExistMap.put(acc.Name,acc.Id);
            }

            //Loop through applications again and attach accounts to applications
            for (Job_Application__c applicationRecord : applicationRecords) {
                String companyName = appToCompanyNameMap.get(applicationRecord);
                applicationRecord.Company_Name__c = accountNamesThatExistMap.get(companyName);
            }
            
            
            }

                Database.upsert(applicationRecords,Job_Application__c.External_Id__c);
        }

    @future(callout = true)
    public static void getJobs() {
        Map<String,String> keywordMap = new Map<String,String>();
        // Create HTTP request to send.
        HttpRequest request = new HttpRequest();
        // Set the endpoint URL. Use direct URL or for best practices use Named Credential.
        request.setEndpoint('https://jooble.org/api/e5d2ae19-17e9-4c4a-aa0f-6f1946d66fb2');
        //Set header
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Set the HTTP method to POST.
        request.setMethod('POST');
        //Set the body of th request.
        request.setBody('{"keywords":"Salesforce Developer"}');
        System.debug(request);
        // Send the HTTP request and get the response.
        Http http = new Http();
        HttpResponse response = http.send(request);
        String responseBody = response.getBody();
        System.debug(responseBody);
        Integer statusCode = response.getStatusCode();
        System.debug(statusCode);
        if(statusCode >= 200 && statusCode <= 299) {
            createApplicationsFromJson(responseBody);
        }

    }
}