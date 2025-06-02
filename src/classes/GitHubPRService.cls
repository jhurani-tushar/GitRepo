public with sharing class GitHubPRService {
    // Create a new Pull Request
    public static String createPullRequest(String owner, String repo, String head, String base, String title, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GitHubAPI/repos/' + owner + '/' + repo + '/pulls');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/vnd.github+json');
        
        Map<String, Object> payload = new Map<String, Object>{
            'title' => title,
            'head' => head,
            'base' => base,
            'body' => body
        };
        req.setBody(JSON.serialize(payload));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res.getBody();
    }

    // Update an existing Pull Request
    public static String updatePullRequest(String owner, String repo, Integer pullNumber, String title, String body, String state) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GitHubAPI/repos/' + owner + '/' + repo + '/pulls/' + pullNumber);
        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/vnd.github+json');
        
        // Only set fields that are provided (null values won't update)
        Map<String, Object> payload = new Map<String, Object>();
        if(title != null) payload.put('title', title);
        if(body != null) payload.put('body', body);
        if(state != null) payload.put('state', state); // 'open' or 'closed'
        
        req.setBody(JSON.serialize(payload));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res.getBody();
    }
}