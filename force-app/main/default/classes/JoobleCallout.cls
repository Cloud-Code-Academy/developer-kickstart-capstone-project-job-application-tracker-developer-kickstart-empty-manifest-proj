public with sharing class JoobleCallout implements Queueable, Database.AllowsCallouts {
    
    // Class variables
    private Map<String, String> paramMap; //Map containing parameters
    private Integer days;    // how many days ago for a job created date

    // Class constructor
    public JoobleCallout (Map<String, String> paramMap, Integer days){
        this.paramMap = paramMap;
        this.days = days;
    }
    
    // Execute method for Queueable
    public void execute(QueueableContext context){        
        
        //Set up the HTTP request to send
        HttpRequest request = new HttpRequest();
        // Named Credential 'JoobleCallout' used for authentication, header and endpoint management       
        request.setEndpoint('callout:JoobleCallout');
        request.setMethod('POST');
        // Set body with generatePayload method
        request.setBody(generateJooblePayload(paramMap, days));
        
        // Send the HTTP request and get the response.  In case of failure, send email to System Admins
        Http http = new Http();
        String failMessage;
        try{
            HttpResponse response = http.send(request);    
            // Check Response
            if(response.getStatusCode() >= 200 && response.getStatusCode() <= 299){
                String jsonResponseBody = response.getBody();
                JobParser.parseJoobleApps(jsonResponseBody);
            } else {
                failMessage = 'HTTP Error: ' + response.getStatusCode() + ' - ' + response.getBody();
                JobApplicationService.sendErrorEmail('HTTP Error', failMessage);
            }
        } catch (Exception e){
            failMessage = 'Callout failed: ' + e.getMessage();
            JobApplicationService.sendErrorEmail('Jooble Callout Error', failMessage);
        }
    }

    private static String generateJooblePayload(Map<String, String> paramMap, Integer days){

        // Calculate and format the date X days ago
        String formattedDate = Date.today().addDays(-days).format();

        // Build payload map
        Map<String,Object> jsonMap = new Map<String,Object>();
        // Always include the datecreatedfrom parameter
        jsonMap.put('datecreatedfrom', formattedDate);
        for(String key : paramMap.keySet()){
            // Dynamically fill jsonMap from user defined settings
            jsonMap.put(key, paramMap.get(key));
        }
        // Serialize and return the payload
        return JSON.serialize(jsonMap);        
    }
}