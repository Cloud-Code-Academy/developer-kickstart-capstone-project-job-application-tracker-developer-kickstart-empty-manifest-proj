
/**
 * Mock class to simulate a valid Jooble API response.
 * Includes multiple salary formats and an existing company.
 */
public with sharing class JoobleCalloutMockResponse implements HttpCalloutMock{
    
    /**
     * Responds to an HTTP request with a simulation.
     * @param request The incoming HTTP request.
     * @return A mock HttpResponse containing job listings.
     */
    public HttpResponse respond(HttpRequest request) {
        
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        
        // Call method to create JSON, then set response body        
        response.setBody(getValidResponse());
        
        return response;
    }
    
    /**
     * Returns a mock response body with valid job postings
     * @return a JSON string with properly formatted job listing data
     */
    public static String getValidResponse(){

        // Create structure to hold build mock data records
        List<Map<String, Object>> jobList = new List<Map<String, Object>>();

        // Add job records using Maps
        jobList.add(new Map<String, Object>{
            'title' => 'Solution Architect',
            'location' => 'Miami, FL',
            'snippet' => 'Establish a sustainable technical architecture...',
            'salary' => '$150K - $160K',
            'source' => 'snapjobsearch.com',
            'link' => 'https://jooble.org/desc/386733306',
            'company' => 'First Solutions',
            'id' => '12345'
        });

        jobList.add(new Map<String, Object>{
            'title' => 'Salesforce Developer',
            'location' => 'Remote',
            'snippet' => 'Looking for an experienced Salesforce Developer...',
            'salary' => '$24 - $28 per hour',
            'source' => 'snapjobsearch.com',
            'link' => 'https://jooble.org/desc/78362221',
            'company' => 'Second Corporation',
            'id' => '67890'
        });

        jobList.add(new Map<String, Object>{
            'title' => 'Business Analyst',
            'location' => 'New York, NY',
            'snippet' => 'Work with clients on technical solutions...',
            'salary' => '$140k',
            'source' => 'jobfinder.com',
            'link' => 'https://jooble.org/desc/0987654321',
            'company' => 'Third Company',
            'id' => '11223'
        });

        jobList.add(new Map<String, Object>{
            'title' => 'Software Engineer',
            'location' => 'San Francisco, CA',
            'snippet' => 'Exciting role in a fast-growing company...',
            'salary' => '$100K',
            'source' => 'jobfinder.com',
            'link' => 'https://jooble.org/desc/44556677',
            'company' => '',  // Empty company name
            'id' => 'ABC123'
        });

        jobList.add(new Map<String, Object>{
            'title' => 'Project Manager',
            'location' => 'Austin, TX',
            'snippet' => 'Looking for an experienced PM...',
            'salary' => 'Negotiable',  // Invalid salary format
            'source' => 'jobpost.com',
            'link' => 'https://jooble.org/desc/99887766',
            'company' => 'DEF Inc.',
            'id' => 'XYZ789'
        });

        jobList.add(new Map<String, Object>{
            'title' => 'Marketing Specialist',
            'location' => 'Chicago, IL',
            'snippet' => 'Develop and execute marketing strategies...',
            'salary' => '$60K - $70K',
            'source' => 'jobhub.com',
            'link' => 'https://jooble.org/desc/55667788',
            'company' => 'Marketing Pros',
            'id' => null  // Missing job ID
        });

        // Wrap jobs inside a "jobs" key
        Map<String, Object> finalResponse = new Map<String, Object>();
        finalResponse.put('jobs', jobList);

        // Convert SF data to JSON and return
        return JSON.serializePretty(finalResponse);
    }
}     
