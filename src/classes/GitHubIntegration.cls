public class GitHubIntegration {
    
    @AuraEnabled
    public static string callFromSFDC(String repoName, String owner, String filePath){
        
        Http htp = new Http();
        
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        String endpoint = 'callout:GitHubInteg/repos/' + owner + '/' + repoName + '/contents/' + filePath;
        string encoded = EncodingUtil.urlDecode(repoName, 'UTF-8');
        req.setEndpoint(endpoint);
        req.setHeader('Accept', 'application/vnd.github.v3.raw');

        try{
            HttpResponse res = htp.send(req);
            System.debug('Response :- ' + res.getBody());
            System.debug('Response Staus Code : ' + res.getStatusCode());
            System.debug('Response Status' + res.getStatus());
            return res.getBody();
        }
        catch(Exception ex){
            system.debug(ex.getMessage());
            return ex.getMessage();
            
        }
    
    }
    
}