public class JoobleSettingsCalloutService {

    /**
     * Invocable method that is triggered when Job Application Settings are updated within 
     *      the Job App Settings Aduster Flow
     * This enacts a one-time Jooble callout, immediately thereafter, to pull in data corresponding
     *      to the new settings.
     *
     * @param settingsIds List of Job Application Setting record IDs that were updated.
     *                    This will always contain one ID because the Flow updates only one setting at a time.
     */
    @InvocableMethod(label='Trigger Jooble Callout' description='Calls Jooble API when Job Application Settings are updated')
    public static void triggerJoobleCallout() {

        // Get the search parameters from JobBoardService class
        Map<String, String> searchParams = JobBoardService.getJobSearchParams('Jooble');
        Integer daysBack = 14; // fetches jobs posted within this time frame

        // Execute the callout
        System.enqueueJob(new JoobleCallout(searchParams, daysBack));
    }
}