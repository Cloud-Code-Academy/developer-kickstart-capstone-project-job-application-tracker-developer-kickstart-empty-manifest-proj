@isTest
private class TaxCalculationHandlerTest {
    
    // Utility method to create a Job Application record
    private static Job_Application__c createJobApp(Decimal salary) {
        Job_Application__c jobApp = new Job_Application__c();
        jobApp.Name = 'Test Application';
        jobApp.Salary__c = salary;
        return jobApp;
    }
    
    // Positive test to check all tax calculations and set values in each bracket
    @isTest static void testTaxCalculationAcrossBrackets() {
        List<Job_Application__c> jobApps = new List<Job_Application__c>{
            createJobApp(10000),  
            createJobApp(20000),  
            createJobApp(50000),  
            createJobApp(120000), 
            createJobApp(250000)  
        };
        insert jobApps;
        
        // Test the tax calculation logic
        Test.startTest();
        TaxCalculationHandler.calculateTaxesAndTakeHomePay(jobApps);
        Test.stopTest();
        
        // Check tax calculations and tax brackets
        for (Job_Application__c jobApp : jobApps) {
            Decimal expectedTax = TaxCalculationHandler.calculateFederalTax(jobApp.Salary__c);
            System.assertEquals(expectedTax, jobApp.Federal_Income_Tax__c, 'Incorrect federal tax calculation for salary ' + jobApp.Salary__c);
        }
    }  
    
    // Positive test to verify getSalary and getTaxBracketDetails methods
    @isTest static void testGetSalaryAndTaxDetails() {
        Job_Application__c jobApp = createJobApp(50000);
        insert jobApp;

        Decimal fetchedSalary = TaxCalculationHandler.getSalary(jobApp.Id);
        System.assertEquals(jobApp.Salary__c, fetchedSalary, 'Salary fetched incorrectly.');

        Map<String, String> taxDetails = TaxCalculationHandler.getTaxBracketDetails(fetchedSalary);
        System.assertEquals('22%', taxDetails.get('Rate'), 'Incorrect tax rate fetched for salary of ' + fetchedSalary);
        System.assertEquals('$47,151 to $100,525', taxDetails.get('Bracket'), 'Incorrect tax bracket fetched.');
    }

    // Test to dynamically fetch tax details based on current job application
    @isTest static void testDynamicTaxDetailsFetching() {
        Job_Application__c jobApp = createJobApp(85000); // Salary within the third tax bracket
        insert jobApp;

        Test.startTest();
        Map<String, String> taxDetails = TaxCalculationHandler.fetchTaxDetailsForApplication(jobApp.Id);
        Test.stopTest();

        System.assertNotEquals(null, taxDetails, 'Tax details should not be null.');
        System.assertEquals('22%', taxDetails.get('Rate'), 'Incorrect tax rate for dynamic fetching.');
        System.assertEquals('$47,151 to $100,525', taxDetails.get('Bracket'), 'Incorrect tax bracket for dynamic fetching.');
    }

    //  Positive test for payment intervals
    @isTest static void testGetPaymentIntervals() {
        Test.startTest();
        List<Map<String, Object>> intervals = TaxCalculationHandler.getPaymentIntervals();
        Test.stopTest();
    
        System.assertNotEquals(null, intervals, 'Payment intervals should not be null.');
        System.assert(intervals.size() > 0, 'Should retrieve at least one payment interval.');
        System.assertEquals('Annually', intervals[0].get('label'), 'First interval label should be Annually.');
    }

    // Negative test method for prevention of manual updates on calculated fields
    @isTest static void testPreventManualUpdatesOnCalculatedFields() {
        Job_Application__c jobApp = createJobApp(50000);
        insert jobApp;

        // Initial tax calculation
        TaxCalculationHandler.calculateTaxesAndTakeHomePay(new List<Job_Application__c>{jobApp});

        // Refresh jobApp from database to get calculated values
        jobApp = [SELECT Annually__c, Semi_annually__c, Monthly__c, Bi_weekly__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.debug('Calculated Annually: ' + jobApp.Annually__c);
        Decimal originalAnnually = jobApp.Annually__c;

        // Attempt to manually update the calculated fields
        jobApp.Annually__c = originalAnnually + 12345.67; // Random value to simulate manual input

        Test.startTest();
        update jobApp;
        Test.stopTest();
    
        // Re-query to verify that changes were not made
        Job_Application__c refreshedJobApp = [SELECT Annually__c FROM Job_Application__c WHERE Id = :jobApp.Id];
        System.assertEquals(originalAnnually, refreshedJobApp.Annually__c, 'Annually field should revert to system calculated value after manual update attempt.');
    }
}