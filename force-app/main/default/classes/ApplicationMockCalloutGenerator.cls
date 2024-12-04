public with sharing class ApplicationMockCalloutGenerator implements HttpCalloutMock {
	public HTTPResponse respond(HTTPRequest req) {
		// Create a fake response
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');

		// Check if the request is a POST request
		if (req.getMethod() == 'POST') {
			// Return a success response for the POST request
			res.setBody('{"totalCount": "1","jobs": [{"company":"V2","updated":"2024-11-15T00:00:00.0000000","location":"Columbus, OH","title":"Senior Salesforce Developer","id":"111222333","salary":"60000","url":"https://google.com"}]}');
		}
		res.setStatusCode(200);
		return res;
	}
}

//Sample response: {"totalCount":134583,"jobs":[{"title":"Salesforce / AWS Lead Software Engineer","location":"Columbus, OH","snippet":"&nbsp;...leading-edge technologies \r\n Adds to team culture of diversity, equity, inclusion, and respect \r\n Codes in (Java, Talend, SQL, and <b>Salesforce </b>CRM) \r\n Leads varying levels of Software Engineers in an Agile environment \r\n \r\n \r\n Required qualifications, capabilities, and...&nbsp;","salary":"","source":"ziprecruiter.com","type":"","link":"https://jooble.org/away/6543676382721084105?p=1&pos=1&cid=3958&ckey=salesforce&jobAge=283&brelb=115&scr=132.86147&bscr=132.86147&aq=1254713807859732920&elckey=-6709324918557645577","company":"JPMorganChase","updated":"2024-11-10T00:00:00.0000000","id":6543676382721084105}