@isTest
private class PayEstimationHelperTest {
    @isTest
    static void testCalculatePayEstimation_ValidSalary() {
        // Create a test Job Application with a valid salary
        Job_Application__c jobApp = new Job_Application__c(
            Name = 'Test Application',
            Salary__c = 100000
        );

        // Perform the calculation
        PayEstimationHelper.calculatePayEstimation(jobApp);

        // Assertions
        System.assertEquals(17400, jobApp.Federal_Tax__c, 'Federal Tax should be correctly calculated');
        System.assertEquals(6200, jobApp.Social_Security_Tax__c, 'Social Security Tax should be correctly calculated');
        System.assertEquals(1450, jobApp.Medicare_Tax__c, 'Medicare Tax should be correctly calculated');
        System.assertEquals(74950, jobApp.Take_Home_Pay__c, 'Take Home Pay should be correctly calculated');
        System.assert(jobApp.Take_Home_Breakdown__c.contains('Yearly: $74,950'), 'Breakdown should include yearly pay');
    }

    @isTest
    static void testCalculatePayEstimation_ZeroSalary() {
        // Create a test Job Application with a salary of 0
        Job_Application__c jobApp = new Job_Application__c(
            Name = 'Test Application',
            Salary__c = 0
        );

        // Perform the calculation
        PayEstimationHelper.calculatePayEstimation(jobApp);

        // Assertions
        System.assertEquals(0, jobApp.Federal_Tax__c, 'Federal Tax should be 0 for zero salary');
        System.assertEquals(0, jobApp.Social_Security_Tax__c, 'Social Security Tax should be 0 for zero salary');
        System.assertEquals(0, jobApp.Medicare_Tax__c, 'Medicare Tax should be 0 for zero salary');
        System.assertEquals(0, jobApp.Take_Home_Pay__c, 'Take Home Pay should be 0 for zero salary');
        System.assertEquals('Salary not provided or invalid.', jobApp.Take_Home_Breakdown__c, 'Breakdown should indicate invalid salary');
    }

    @isTest
    static void testCalculatePayEstimation_NullSalary() {
        // Create a test Job Application without a salary
        Job_Application__c jobApp = new Job_Application__c(
            Name = 'Test Application'
        );

        // Perform the calculation
        PayEstimationHelper.calculatePayEstimation(jobApp);

        // Assertions
        System.assertEquals(0, jobApp.Federal_Tax__c, 'Federal Tax should be 0 for null salary');
        System.assertEquals(0, jobApp.Social_Security_Tax__c, 'Social Security Tax should be 0 for null salary');
        System.assertEquals(0, jobApp.Medicare_Tax__c, 'Medicare Tax should be 0 for null salary');
        System.assertEquals(0, jobApp.Take_Home_Pay__c, 'Take Home Pay should be 0 for null salary');
        System.assertEquals('Salary not provided or invalid.', jobApp.Take_Home_Breakdown__c, 'Breakdown should indicate invalid salary');
    }    
}