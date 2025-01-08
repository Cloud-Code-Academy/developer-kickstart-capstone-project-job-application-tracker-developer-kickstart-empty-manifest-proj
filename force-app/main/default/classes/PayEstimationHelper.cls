public class PayEstimationHelper {
    private static final Decimal SOCIAL_SECURITY_RATE = 0.062;
    private static final Decimal MEDICARE_RATE = 0.0145;

    public static void calculatePayEstimation(Job_Application__c application) {
        if (application.Salary__c == null || application.Salary__c <= 0) {
            application.Federal_Tax__c = 0;
            application.Social_Security_Tax__c = 0;
            application.Medicare_Tax__c = 0;
            application.Take_Home_Pay__c = 0;
            application.Take_Home_Breakdown__c = 'Salary not provided or invalid.';
            return;
        }

        Decimal federalTax = calculateFederalTax(application.Salary__c);
        Decimal socialSecurityTax = application.Salary__c * SOCIAL_SECURITY_RATE;
        Decimal medicareTax = application.Salary__c * MEDICARE_RATE;

        Decimal takeHomePay = application.Salary__c - (federalTax + socialSecurityTax + medicareTax);

        application.Federal_Tax__c = federalTax;
        application.Social_Security_Tax__c = socialSecurityTax;
        application.Medicare_Tax__c = medicareTax;
        application.Take_Home_Pay__c = takeHomePay;

        Decimal monthlyPay = (takeHomePay / 12).setScale(2);
        Decimal biWeeklyPay = (takeHomePay / 26).setScale(2);
        Decimal weeklyPay = (takeHomePay / 52).setScale(2);

        application.Take_Home_Breakdown__c = 
            'Yearly: $' + takeHomePay.format() + '\n' +
            'Monthly: $' + monthlyPay.format() + '\n' +
            'Bi-Weekly: $' + biWeeklyPay.format() + '\n' +
            'Weekly: $' + weeklyPay.format();

    }

    private static Decimal calculateFederalTax(Decimal salary) {
        if (salary <= 11000) {
            return (salary * 0.10).setScale(2);
        } else if (salary <= 44725) {
            return (1100 + ((salary - 11000) * 0.12)).setScale(2);
        } else if (salary <= 95375) {
            return (5147 + ((salary - 44725) * 0.22)).setScale(2);
        } else if (salary <= 182100) {
            return (16290 + ((salary - 95375) * 0.24)).setScale(2);
        } else if (salary <= 231250) {
            return (37104 + ((salary - 182100) * 0.32)).setScale(2);
        } else if (salary <= 578125) {
            return (52832 + ((salary - 231250) * 0.35)).setScale(2);
        } else {
            return (174238 + ((salary - 578125) * 0.37)).setScale(2);
        }
    }
}
