import { LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getCalculateNetTakeHomePay from '@salesforce/apex/TaxCalculationHandler.getCalculateNetTakeHomePay';
import getPaymentIntervals from '@salesforce/apex/TaxCalculationHandler.getPaymentIntervals'; 

export default class PaycheckBreakdown extends LightningElement {
    // Initialize to 0
    @track salary = 0;
    @track taxRate = 0;
    @track netPayAnnual = 0; 
    @track netPaySemiAnnual = 0; 
    @track netPayMonthly = 0; 
    @track netPayBiWeekly = 0; 

    @track paymentOptions = []; // For storing payment interval options
@wire(getPaymentIntervals)
paymentIntervals({ error, data }) {
    if (data) {
        this.paymentOptions = data.map(item => ({
            label: item.label,
            value: item.value
        }));
    } else if (error) {
        console.error('Error fetching payment intervals:', error);
        this.paymentOptions = [];  
    }
}

    // Handle changes in salary input and reinitialize pay breakdowns
    handleSalaryChange(event) {
        this.salary = parseFloat(event.target.value); // Parse input as float to ensure correct data type
        this.resetPayBreakdown(); // Reset pay breakdown values to 0
    }

    // Reset all computed pay breakdowns to zero
    resetPayBreakdown() {
        this.netPayAnnual = 0;
        this.netPaySemiAnnual = 0;
        this.netPayMonthly = 0;
        this.netPayBiWeekly = 0;
    }

handleCalculate() {
    getCalculateNetTakeHomePay({ salary: this.salary })
        .then(result => {
            if (result) {
                this.netPayAnnual = result.Take_Home_Pay__c;
                this.netPaySemiAnnual = result.Take_Home_Pay__c / 2;
                this.netPayMonthly = result.Take_Home_Pay__c / 12;
                this.netPayBiWeekly = result.Take_Home_Pay__c / 26;
            } else {
                this.resetPayBreakdown(); // Resets if no result returned
            }
        })
        .catch(error => {
            console.error('Calculation error:', error);
            this.resetPayBreakdown();
        });
}

    // Format values as currency for display
    get salaryInputFormatted() {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.salary);
    }
    get netPayAnnualFormatted() {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.netPayAnnual);
    }
    get netPaySemiAnnualFormatted() {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.netPaySemiAnnual);
    }
    get netPayMonthlyFormatted() {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.netPayMonthly);
    }
    get netPayBiWeeklyFormatted() {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(this.netPayBiWeekly);
    }
    
}