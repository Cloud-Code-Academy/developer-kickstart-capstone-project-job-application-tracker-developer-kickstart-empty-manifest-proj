import { LightningElement, wire, api } from 'lwc';  // 

import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';  // bring in the record to use in calculations

import { RefreshEvent } from 'lightning/refresh'; 


    // CONSTANTS BELOW

    const fieldsFromRecord                  = ['Job_Application__c.Salary__c'];     // field api name that is be pulled from record
    const medicareWithholdingRate           = 0.0145;
    const socialSecurityWithholdingRate     = 0.062;

    const federalWithholdingRate = [       

        // fed rate  information found @ https://taxfoundation.org/data/all/federal/2025-tax-brackets/
        // assuming client is Single Filer. Can add more options later if we have time.
        
        {minEarnings: 0,       maxEarnings: 11925,    rate: 0.10},
        {minEarnings: 11926,   maxEarnings: 48475,    rate: 0.12},
        {minEarnings: 48476,   maxEarnings: 103350,   rate: 0.22},
        {minEarnings: 103351,  maxEarnings: 197300,   rate: 0.24},
        {minEarnings: 197301,  maxEarnings: 250525,   rate: 0.32},
        {minEarnings: 250526,  maxEarnings: 626350,   rate: 0.35},
        {minEarnings: 626351,  maxEarnings: Infinity, rate: 0.37},
    ];

    // CONSTANTS ABOVE


export default class TaxCalculator extends LightningElement {

    salaryFromRecord                    = 0;
    formattedSalaryFromRecord           = 0;
    weeklyPay                           = 0;
    formattedWeeklyPay                  = 0;
    biWeeklyPay                         = 0;
    formattedBiWeeklyPay                = 0;
    monthlyPay                          = 0;
    formattedMonthlyPay                 = 0;
    sixMonthPay                         = 0;
    formattedSixMonthPay                = 0;
    yearlyPay                           = 0;
    formattedYearlyPay                  = 0;
    socialSecurityTaxOwed               = 0;
    formattedSocialSecurityTaxOwed      = 0;
    medicareTaxOwed                     = 0;
    formattedMedicareTaxOwed            = 0;
    fedTaxOwed                          = 0;
    formattedFedTaxOwed                 = 0;
    totalTaxes                          = 0;
    formattedTotalTaxes                 = 0;

    




    @api recordId;



    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: ['Job_Application__c.Salary__c'] 
    })

    wiredRecord({ error, data }) {
        if (data) {
            console.log("Record Data:", data);
            this.salaryFromRecord = data.fields.Salary__c.value;
            this.handleCalculations();
        } else if (error) {
            console.error('Error retrieving record:', error);
        }
    }


    // This is part of what makes the LWC update upon changes
    handleRecordUpdate() {

        // Update record logic 

        getRecordNotifyChange([this.recordId]); // Notify changes to the record

    }


    // This is also part of what makes the LWC update upon changes
    refreshView() {

        const refreshEvent = new RefreshEvent();

        this.dispatchEvent(refreshEvent); 

    }

    // Perform salary-related calculations below
    // These calculations do NOT currently apply 'progressive tax calculations'
    handleCalculations() {
        /*
        So, if you earned an annual income of $50,000 in 2024 and your status is single, 
        you fall into the 22% tax bracket. But, this doesn’t mean your entire income is taxed
        at 22%. Instead, each portion of your income that falls into each bracket is taxed at
        that rate. The first $11,600 is taxed at 10%, the amount over $11,600 and up to 
        $47,150 is taxed at 12%, and only the income above $47,150 up to your total income 
        of $50,000 is taxed at 22%.      
        https://embers.banzai.org/wellness/resources/tax-brackets-and-statuses
        */

        console.log("Running handleCalculations...");
        console.log(`Salary from record: ${this.salaryFromRecord}`);


        let fedTaxOwed = 0;
        let remainingSalary = this.salaryFromRecord; // Start with full salary
        
    


        for (const bracket of federalWithholdingRate) {
            if (remainingSalary > bracket.minEarnings) {
                let taxableAmount = Math.min(remainingSalary, bracket.maxEarnings) - bracket.minEarnings;
                let taxForBracket = taxableAmount * bracket.rate;

                fedTaxOwed += taxForBracket;  // Accumulate tax across all brackets
            } else {
                break; // Stop when salary is fully processed
            }
        }


        // raw (tax) numbers not formatted. better for calculations
        this.fedTaxOwed = fedTaxOwed;   
        this.socialSecurityTaxOwed = this.salaryFromRecord * socialSecurityWithholdingRate; //calculate social security tax owed
        this.medicareTaxOwed = this.salaryFromRecord * medicareWithholdingRate; //calculate medicare tax owed
        this.totalTaxes = this.medicareTaxOwed + this.socialSecurityTaxOwed + this.fedTaxOwed //calculate Total Tax Owed


        //  raw (pay) numbers not formatted. better for calculations
    
        this.yearlyPay = this.salaryFromRecord - this.totalTaxes;
        this.sixMonthPay = this.yearlyPay / 2;
        this.monthlyPay = this.yearlyPay / 12;
        this.biWeeklyPay = this.yearlyPay / 26;
        this.weeklyPay = this.yearlyPay / 52; 

        // formatted (tax) numbers for super duper pretty LWC

        this.formattedSocialSecurityTaxOwed = this.socialSecurityTaxOwed.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
        this.formattedMedicareTaxOwed = this.medicareTaxOwed.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
        this.formattedFedTaxOwed = this.fedTaxOwed.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
        this.formattedYearlyPay = this.yearlyPay.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
        this.formattedTotalTaxes = this.totalTaxes.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });

        // formatted (pay) numbers for super duper pretty LWC
        this.formattedYearlyPay = this.yearlyPay.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
        this.formattedSixMonthPay = this.sixMonthPay.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
        this.formattedMonthlyPay = this.monthlyPay.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
        this.formattedBiWeeklyPay = this.biWeeklyPay.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
        this.formattedWeeklyPay = this.weeklyPay.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });
        this.formattedSalaryFromRecord = this.salaryFromRecord.toLocaleString(undefined, { maximumFractionDigits: 2, minimumFractionDigits: 2 });


        console.log(`Fed Tax Owed: ${this.fedTaxOwed}, Social Security: ${this.socialSecurityTaxOwed}, Medicare: ${this.medicareTaxOwed}`);



        
        


    }


    updateSalary(event) {
        this.salaryFromRecord = event.target.value;
        this.handleCalculations();  // Recalculate everything when salary changes
    }

}




