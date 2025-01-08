public class JobApplicationTriggerHandler {

    public static void beforeInsertUpdate(List<Job_Application__c> newRecords, Map<Id, Job_Application__c> oldMap) {
         for(Job_Application__c application : newRecords) {
            //Perform Pay Estimation Calculation
            PayEstimationHelper.calculatePayEstimation(application);

            //Handle Primary Contact Assignment
            if(String.isBlank(application.Primary_Contact__c)){
                List<Contact> relatedContacts =[
                    SELECT Id FROM Contact
                    Where AccountId = :application.Company_Account__c
                    LIMIT 1
                ];
                if(!relatedContacts.isEmpty()){
                    application.Primary_Contact__c = relatedContacts[0].Id;
                }
            }
        }
    }

    Public static void afterInsertUpdate(List<Job_Application__c> newRecords, Map<Id, Job_Application__c> oldRecords){ 
        //Handle Task Creation on Status Change
        List<Task> tasksToInsert = new List<Task>();

        for(Job_Application__c application : newRecords){
            String newStatus = application.Status__c;
            String oldStatus = oldRecords != null ? oldRecords.get(application.Id)?.Status__c : null;

            //skip if status is blank or unchanged
            if(String.isBlank(newStatus) || (oldStatus != null && oldStatus.equalsIgnoreCase(newStatus))){
                continue;
            }

            //Add task based on the new status
            tasksToInsert.addAll(createTasksforStatus(newStatus, application.Id));
        }

        if(!tasksToInsert.isEmpty()){
            insert tasksToInsert;
        }
    }

    /**
     * Create a list of tasks based on the job application status.
     * @param status The new Status of the job application.
     * @param application.Id The Id of the Job Application record.
     * @return List of tasks to be created
     */
    private static List<Task> createTasksForStatus(String status, Id applicationId){
        List<Task> tasks = new List<Task>();

        if (status == 'Saved') {
            tasks.add(new Task(WhatId = applicationId, Subject = 'Check job description alignment', Priority = 'Normal', ActivityDate = System.today().addDays(2)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Review highlighted skills', Priority = 'Normal', ActivityDate = System.today().addDays(2)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Research the company and mark excitement level', Priority = 'Normal', ActivityDate = System.today().addDays(2)));
        } else if (status == 'Applying') {
            tasks.add(new Task(WhatId = applicationId, Subject = 'Review highlighted skills', Priority = 'Normal', ActivityDate = System.today().addDays(2)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Set up informational interview', Priority = 'Normal', ActivityDate = System.today().addDays(3)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Identify potential referrals', Priority = 'High', ActivityDate = System.today().addDays(3)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Find and research someone at the company', Priority = 'High', ActivityDate = System.today().addDays(3)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Customize achievements using keywords', Priority = 'Normal', ActivityDate = System.today().addDays(3)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Submit application on company website', Priority = 'High', ActivityDate = System.today().addDays(3)));
        } else if (status == 'Applied') {
            tasks.add(new Task(WhatId = applicationId, Subject = 'Reach out to hiring manager or recruiter', Priority = 'High', ActivityDate = System.today().addDays(4)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Follow up on application weekly', Priority = 'Normal', ActivityDate = System.today().addDays(7)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Identify and save similar job opportunities', Priority = 'Normal', ActivityDate = System.today().addDays(4)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Set up networking calls weekly', Priority = 'Normal', ActivityDate = System.today().addDays(7)));
        } else if (status == 'Interviewing') {
            tasks.add(new Task(WhatId = applicationId, Subject = 'Prepare \"Tell me about yourself\" response', Priority = 'High', ActivityDate = System.today().addDays(5)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Practice behavioral interview questions', Priority = 'High', ActivityDate = System.today().addDays(5)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Research company and interviewers', Priority = 'High', ActivityDate = System.today().addDays(5)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Set up virtual interview space', Priority = 'Normal', ActivityDate = System.today().addDays(5)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Send thank-you emails post-interview', Priority = 'High', ActivityDate = System.today().addDays(6)));
        } else if (status == 'Negotiating') {
            tasks.add(new Task(WhatId = applicationId, Subject = 'Research market value', Priority = 'High', ActivityDate = System.today().addDays(7)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Prepare negotiation scripts', Priority = 'High', ActivityDate = System.today().addDays(7)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Evaluate offer and decide', Priority = 'Normal', ActivityDate = System.today().addDays(8)));
        } else if (status == 'Accepted') {
            tasks.add(new Task(WhatId = applicationId, Subject = 'Plan your resignation', Priority = 'Normal', ActivityDate = System.today().addDays(10)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Take time to recharge', Priority = 'Normal', ActivityDate = System.today().addDays(10)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Prepare for onboarding', Priority = 'Normal', ActivityDate = System.today().addDays(10)));
        } else if (status == 'Closed') {
            tasks.add(new Task(WhatId = applicationId, Subject = 'Send follow-up email and ask for feedback', Priority = 'Normal', ActivityDate = System.today().addDays(2)));
            tasks.add(new Task(WhatId = applicationId, Subject = 'Review notes and reflect on improvements', Priority = 'Normal', ActivityDate = System.today().addDays(2)));
        }


        return tasks;
    }
}