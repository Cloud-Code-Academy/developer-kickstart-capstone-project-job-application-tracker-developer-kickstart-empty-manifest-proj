@isTest
public class JoobleAPIServiceTest {
    
    @isTest
    static void test_scheduleJoobleAPIService() {
        // Arrange
        String cronExp = '0 0 12 * * ?'; // Example cron expression for daily run at noon
        
        //Mock Service
        Test.setMock(HttpCalloutMock.class, new JoobleAPIServiceMock());

        Test.startTest();
        // Act - Schedule the job
        System.schedule('JoobleAPIJobTest', cronExp, new JoobleAPIService());
        Test.stopTest();

        // Assert - Check that a scheduled job exists
        CronTrigger[] cronTriggers = [SELECT Id, CronExpression, State FROM CronTrigger WHERE CronExpression = :cronExp];
        System.assertEquals(1, cronTriggers.size(), 'Expected one scheduled job.');

        // Check if the Queueable job was enqueued by the scheduler
        AsyncApexJob[] jobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'JoobleAPIQueueable'];
        System.assertEquals(1, jobs.size(), 'Expected one Queueable job to be enqueued.');
    }

    // Mock class to simulate API response
    private class JoobleAPIServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{\n' +
                '  "jobs": [\n' +
                '    {"title": "Salesforce Developer", "snippet": "Build Salesforce solutions.", "link": "http://example.com/job1", "salary": "80000", "company": "TechCorp"}\n' +
                '  ]\n' +
                '}');
            res.setStatusCode(200);
            return res;
        }
    }
}
