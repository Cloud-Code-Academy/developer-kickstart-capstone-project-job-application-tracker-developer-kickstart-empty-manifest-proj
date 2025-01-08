public class JoobleAPIQueueable implements Queueable, Database.AllowsCallouts{
    private String keywords;
    private String location;

    public JoobleAPIQueueable(String keywords, String location) {
        this.keywords = keywords;
        this.location = location;

    }

    public void execute(QueueableContext context) {
        JoobleAPIService.fetchJobs(keywords, location);
    }

    //getters for testing
    public String getKeywords() {
        return keywords;
    }

    public String getLocation() {
        return location;
    }
}