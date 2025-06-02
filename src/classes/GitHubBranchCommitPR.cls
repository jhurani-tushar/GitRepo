public with sharing class GitHubBranchCommitPR {
    // Step 1: Get the SHA of the base branch (e.g., main)
    private static String getBranchSHA(String owner, String repo, String branch) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GitHubAPI/repos/' + owner + '/' + repo + '/git/ref/heads/' + branch);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/vnd.github+json');
        Http http = new Http();
        HttpResponse res = http.send(req);
        if(res.getStatusCode() == 200) {
            Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            Map<String, Object> objectMap = (Map<String, Object>)resp.get('object');
            return (String)objectMap.get('sha');
        }
        throw new AuraHandledException('Error fetching base branch SHA: ' + res.getBody());
    }

    // Step 2: Create a new branch from SHA
    private static void createBranch(String owner, String repo, String newBranch, String baseSHA) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GitHubAPI/repos/' + owner + '/' + repo + '/git/refs');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/vnd.github+json');
        Map<String, Object> body = new Map<String, Object>{
            'ref' => 'refs/heads/' + newBranch,
            'sha' => baseSHA
        };
        req.setBody(JSON.serialize(body));
        Http http = new Http();
        HttpResponse res = http.send(req);
        if(res.getStatusCode() >= 300 && res.getBody() != null && !res.getBody().containsIgnoreCase('Reference already exists')) {
            throw new AuraHandledException('Error creating branch: ' + res.getBody());
        }
        // If branch exists, ignore error and proceed
    }

    // Step 3: Commit a file to the new branch!
    private static void commitFile(
        String owner,
        String repo,
        String branch,
        String filePath,
        String fileContent,
        String commitMessage
    ) {
        // GitHub API requires base64-encoded file content
        String encodedContent = EncodingUtil.base64Encode(Blob.valueOf(fileContent));

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GitHubAPI/repos/' + owner + '/' + repo + '/contents/' + filePath);
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/vnd.github+json');
        Map<String, Object> body = new Map<String, Object>{
            'message' => commitMessage,
            'content' => encodedContent,
            'branch'  => branch
        };
        req.setBody(JSON.serialize(body));
        Http http = new Http();
        HttpResponse res = http.send(req);
        if(res.getStatusCode() >= 300) {
            throw new AuraHandledException('Error committing file: ' + res.getBody());
        }
    }

    // Step 4: Create the Pull Request
    private static String createPullRequest(String owner, String repo, String head, String base, String title, String body) {
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
        if(res.getStatusCode() >= 300) {
            throw new AuraHandledException('Error creating PR: ' + res.getBody());
        }
        return res.getBody();
    }

    // Utility: Complete Flow (Create branch, commit file, create PR)
    public static String createBranchCommitAndPR(
        String owner,
        String repo,
        String newBranchName,
        String filePath,
        String fileContent,
        String commitMessage,
        String prTitle,
        String prBody,
        String baseBranch // usually "main"
    ) {
        // 1. Get base branch SHA
        String baseSHA = getBranchSHA(owner, repo, baseBranch);
        // 2. Create new branch from base (ignore if exists)
        createBranch(owner, repo, newBranchName, baseSHA);
        // 3. Commit file to new branch
        commitFile(owner, repo, newBranchName, filePath, fileContent, commitMessage);
        // 4. Create PR
        return createPullRequest(owner, repo, newBranchName, baseBranch, prTitle, prBody);
    }
}