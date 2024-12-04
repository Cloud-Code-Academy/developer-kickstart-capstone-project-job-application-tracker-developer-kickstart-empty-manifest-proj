import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
//import getPaymentIntervals from '@salesforce/apex/TaxCalculationHandler.getPaymentIntervals';
import getTaxBracketDetails from '@salesforce/apex/TaxCalculationHandler.getTaxBracketDetails'; 

// Define the fields to wire from the Job_Application__c object 
const fields = [
    'Job_Application__c.Salary__c',
    'Job_Application__c.Federal_Income_Tax__c',
    'Job_Application__c.Social_Security__c',
    'Job_Application__c.Medicare_Withholding__c',
    'Job_Application__c.Take_Home_Pay__c',
    'Job_Application__c.Annually__c',
    'Job_Application__c.Semi_annually__c',
    'Job_Application__c.Monthly__c',
    'Job_Application__c.Bi_weekly__c'
];

export default class TakeHomePayEstimatorCalculator extends LightningElement {
    @api recordId;
    incomeData = [];
    taxDetails = {}; // To store tax rate and bracket details


    // Wire the job application record using the recordId and specified fields
    @wire(getRecord, { recordId: '$recordId', fields })
    jobApplication;

    // Process income data and fetch tax details from Job Application data
    @wire(getRecord, { recordId: '$recordId', fields })
    wiredJobApplication({ error, data }) {
        if (data) {
            this.incomeData = [
                {
                    label: 'Annually',
                    amount: getFieldValue(data, 'Job_Application__c.Annually__c')
                },
                {
                    label: 'Semi-annually',
                    amount: getFieldValue(data, 'Job_Application__c.Semi_annually__c')
                },
                {
                    label: 'Monthly',
                    amount: getFieldValue(data, 'Job_Application__c.Monthly__c')
                },
                {
                    label: 'Bi-weekly',
                    amount: getFieldValue(data, 'Job_Application__c.Bi_weekly__c')
                }
            ];
            this.fetchTaxDetails(); // Fetch tax details after data is available
        } else if (error) {
            console.error('Error fetching job application record:', error);
            this.incomeData = []; // Clear data on error
        }
    }

    // Fetch tax bracket details based on the salary
    fetchTaxDetails(data) {
        if(data) {
            getTaxBracketDetails({ salary: getFieldValue(data, 'Job_Application__c.Salary__c') })
                .then(result => {
                    this.taxDetails = result;
                })
                .catch(error => {
                    console.error('Error fetching tax details:', error);
                    this.taxDetails = {}; // Reset on error
                });
        }
    }

    // Getter to return if the job application data is loaded
    get loaded() {
        return this.jobApplication.data;
    }

    // Getter to check if there is income data available
    get hasData() {
        return this.incomeData.length > 0;
    }
}