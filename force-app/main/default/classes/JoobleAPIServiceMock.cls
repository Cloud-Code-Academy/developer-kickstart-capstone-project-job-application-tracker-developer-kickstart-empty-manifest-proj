@isTest
private class JoobleAPIServiceMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"jobs": [{"title": "Salesforce Developer", "location": "Remote"}]}');
        res.setStatusCode(200);
        return res;
    }
}