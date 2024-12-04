public with sharing class TaxCalculationHandler {

    // Calculate taxes and net take-home pay for each job application
    public static void calculateTaxesAndTakeHomePay(List<Job_Application__c> jobApps) {
        for (Job_Application__c jobApp : jobApps) {
            try {
                 // Check if the user has read access to the Salary__c field
                if (!Schema.sObjectType.Job_Application__c.fields.Salary__c.isAccessible()) {
                    throw new System.NoAccessException();
                }
                Decimal salary = jobApp.Salary__c != null ? jobApp.Salary__c : 0;
                jobApp.Federal_Income_Tax__c = calculateFederalTax(salary); // Calculate federal income tax based on salary
                jobApp.Social_Security__c = salary * 0.062; // 6.2% for Social Security
                jobApp.Medicare_Withholding__c = salary * 0.0145; // 1.45% for Medicare

                // Calculate take home pay by subtracting taxes from the salary
                jobApp.Take_Home_Pay__c = salary - (jobApp.Federal_Income_Tax__c + jobApp.Social_Security__c + jobApp.Medicare_Withholding__c);
                jobApp.Annually__c = jobApp.Take_Home_Pay__c; // Net yearly take-home pay
                jobApp.Semi_annually__c = jobApp.Take_Home_Pay__c / 2; // Net semi-annual take-home pay
                jobApp.Monthly__c = jobApp.Take_Home_Pay__c / 12; // Net monthly take-home pay
                jobApp.Bi_weekly__c = jobApp.Take_Home_Pay__c / 26; // Net bi-weekly take-home pay
                
            } catch (Exception e) {
                System.debug('Error calculating taxes and take-home pay: ' + e.getMessage());
            }
        }
    }

    // Helper method to calculate federal tax based on tax brackets
    public static Decimal calculateFederalTax(Decimal salary) {
        if (salary <= 11600) {
            return salary * 0.10;
        } else if (salary <= 47150) {
            return 1160 + ((salary - 11600) * 0.12);
        } else if (salary <= 100525) {
            return 5446 + ((salary - 47151) * 0.22);
        } else if (salary <= 191950) {
            return 16930.5 + ((salary - 100526) * 0.24);
        } else {
            return 38871.5 + ((salary - 191950) * 0.32);
        }
    }

    // Method to provide tax bracket details
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getTaxBracketDetails(Decimal salary) {
        Map<String, String> details = new Map<String, String>();
        if (salary <= 11600) {
            details.put('Rate', '10%');
            details.put('Bracket', 'Up to $11,600');
        } else if (salary <= 47150) {
            details.put('Rate', '12%');
            details.put('Bracket', '$11,601 to $47,150');
        } else if (salary <= 100525) {
            details.put('Rate', '22%');
            details.put('Bracket', '$47,151 to $100,525');
        } else if (salary <= 191950) {
            details.put('Rate', '24%');
            details.put('Bracket', '$100,526 to $191,950');
        } else {
            details.put('Rate', '32%');
            details.put('Bracket', 'Above $191,950');
        }
        return details;
    }

    @AuraEnabled(cacheable=true) // Used to show salary 
    public static Decimal getSalary(String recordId) {
        if (!Schema.sObjectType.Job_Application__c.isAccessible()) {
            throw new System.NoAccessException();
        }
        // Get the record based on the record Id
        Job_Application__c jobApp = [SELECT Salary__c FROM Job_Application__c WHERE Id = :recordId];
        return jobApp.Salary__c;
    }

    // Method to dynamically fetch tax details based on current salary from a job application
    @AuraEnabled(cacheable=true)
    public static Map<String, String> fetchTaxDetailsForApplication(Id recordId) {
        // Fetch the current job application to determine the appropriate tax details
        Job_Application__c jobApp = [SELECT Salary__c FROM Job_Application__c WHERE Id = :recordId LIMIT 1];
        if (jobApp != null && jobApp.Salary__c != null) {
            return getTaxBracketDetails(jobApp.Salary__c);
        }
        return null; // Return null if no data is available
    }

@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getPaymentIntervals() {
    List<Map<String, Object>> paymentIntervals = new List<Map<String, Object>>();
    paymentIntervals.add(new Map<String, Object>{'label' => 'Annually', 'value' => 'annually'});
    paymentIntervals.add(new Map<String, Object>{'label' => 'Semi-annually', 'value' => 'semi-annually'});
    paymentIntervals.add(new Map<String, Object>{'label' => 'Monthly', 'value' => 'monthly'});
    paymentIntervals.add(new Map<String, Object>{'label' => 'Bi-weekly', 'value' => 'bi-weekly'});
    return paymentIntervals;
}

    @AuraEnabled(cacheable=true)
public static Job_Application__c getCalculateNetTakeHomePay(Decimal salary) {
    List<Job_Application__c> jobApps = new List<Job_Application__c>{
        new Job_Application__c(Salary__c = salary)
    };
    calculateTaxesAndTakeHomePay(jobApps); // Call existing method
    return jobApps.isEmpty() ? null : jobApps[0];
}

}

 //https://www.nerdwallet.com/article/taxes/federal-income-tax-brackets