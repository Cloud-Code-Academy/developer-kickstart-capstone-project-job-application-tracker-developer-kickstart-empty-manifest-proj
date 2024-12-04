public with sharing class JobApplicationTriggerHandler extends TriggerHandler {
    public static final Map<String, String> STATUS_TO_DESCRIPTION = new Map<String, String>{
        'Saved' =>          '1. Check if the job description aligns with your interests and value' + '\n' +
                            '2. Review the highlighted skills to see if the role is a good fit' + '\n' +
                            '3. Research company or role and mark your excitement level',
        'Applying' =>       '1. Find and research someone who works at the company and add them as a contact' + '\n' +
                            '2. Set up an informational interview to learn more about the role/company' + '\n' +
                            '3. Identify potential referrals to help get your application on the top of the pile' + '\n' +
                            '4. Customize your work achievements using the job description keywords' + '\n' +
                            '5. Submit your application on the company website if possible',
        'Applied' =>        '1. Reach out to the hiring manager or recruiter' + '\n' +
                            '2. Follow up on your application via email weekly' + '\n' +
                            '3. Continue identifying and saving similar job opportunities' + '\n' +
                            '4. Set up weekly networking calls to explore similar companies/roles',
        'Interviewing' =>   '1. Prepare your blurb or “tell me about yourself” response' + '\n' +
                            '2. Practice answering behavioral interview questions' + '\n' +
                            '3. Research the company and your interviewers' + '\n' +
                            '4. Set up your virtual interview space and test your tech' + '\n' +
                            '5. Send thank you emails within 24 hours',
        'Negotiating' =>    '1. Research salary ranges for the role and location' + '\n' +
                            '2. Prepare your negotiation strategy' + '\n' +
                            '3. Practice your negotiation script' + '\n' +
                            '4. Set up a meeting with your manager to discuss your offer' + '\n' +
                            '5. Review the benefits package and ask questions',
        'Accepted' =>       '1. Plan your resignation if applicable' + '\n' +
                            '2. Take some time to relax and recharge' + '\n' +
                            '3. Prepare for your first day of onboarding',
        'Closed' =>         '1. Send a follow-up email thanking the interviewer and asking for feedback' + '\n' +
                            '2. Review your notes and reflect on areas of improvement'
    };

    public static void jobApplicationSetPrimaryContact(List<Job_Application__c> jobApps) {
        Map<Job_Application__c,Id> jobAppAccountMap = new Map<Job_Application__c,Id>();
        List<String> accountList = new List<String>();
        //Loop through job applications and add application Id and Company Id in map
        for (Job_Application__c jobApp : jobApps) {
            if(jobApp.Company_Name__c != null && jobApp.Primary_Contact__c == null) {
                accountList.add(jobApp.Company_Name__c);
                }
            }
            System.debug(accountList);
        //Find all accounts
        Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id, AccountId FROM Contact WHERE AccountId in :accountList]);
        System.debug(contactMap);
        Map<Id,Id> accountToContactMap = new Map<Id,Id>();

        //Loop through contact map
        for (Contact con : contactMap.values()) {
            String accId = con.AccountId;
            if(!accountToContactMap.containsKey(accId)) {
                accountToContactMap.put(accId,con.Id);
            }
        }

        System.debug(accountToContactMap);

        for (Job_Application__c jobApp : jobApps) {
            System.debug(jobApp);
            if(jobApp.Company_Name__c != null & jobApp.Primary_Contact__c == null & accountToContactMap.containskey(jobApp.Company_Name__c)) {
                String primaryContactId = accountToContactMap.get(jobApp.Company_Name__c);
                jobApp.Primary_Contact__c = primaryContactId;
            }
        }
    }

    public override void beforeInsert() {
            TaxCalculationHandler.calculateTaxesAndTakeHomePay (Trigger.new);
            jobApplicationSetPrimaryContact((List<Job_Application__c>) Trigger.new);
        }
    
    public override void beforeUpdate() {
        TaxCalculationHandler.calculateTaxesAndTakeHomePay (Trigger.new);
    }

    public override void afterInsert() {
        createTasksForStatusChange((List<Job_Application__c>) Trigger.new);
    }

    public override void afterUpdate() {
        createTasksForStatusChange((List<Job_Application__c>) Trigger.new);
        jobApplicationSetPrimaryContact((List<Job_Application__c>) Trigger.new);
        
    }

    public void createTasksForStatusChange(List<Job_Application__c> applications) {
        List<Task> tasksToCreate = new List<Task>();


        for(Job_Application__c app : applications) {
                String taskDescription = STATUS_TO_DESCRIPTION.get(app.Status__c);
                Date taskActivityDate = System.today().addDays(3);
                String taskPriority = 'Normal';
                String taskSubject = 'Application status has changed to ' + app.Status__c;
                System.debug(taskDescription);
                System.debug('Loop fired');

                if (taskDescription != null) {
                    if(Trigger.isInsert) {
                        tasksToCreate.add(createTask(app, taskDescription, taskActivityDate, taskPriority, taskSubject));
                    } else if(Trigger.isUpdate && Trigger.oldMap.get(app.Id).get('Status__c') != app.Status__c) {
                        tasksToCreate.add(createTask(app, taskDescription, taskActivityDate, taskPriority, taskSubject));
                    }
                }
            }

        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }

    public static Task createTask(Job_Application__c app, String description, Date ActivityDate, String priority, String subject) {
        Task t = new Task();
        t.Subject = subject;
        t.Description = description;
        t.Status = 'Not Started';
        t.ActivityDate = System.today().addDays(3);
        t.Priority = priority;
        t.WhoId = app.Applicant__c;
        t.WhatId = app.Id;
        return t;
    } 

}