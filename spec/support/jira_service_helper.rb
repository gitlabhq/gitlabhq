module JiraServiceHelper
  JIRA_URL = "http://jira.example.net".freeze
  JIRA_API = JIRA_URL + "/rest/api/2"

  def jira_service_settings
    properties = {
      title: "JIRA tracker",
      url: JIRA_URL,
      username: 'jira-user',
      password: 'my-secret-password',
      project_key: "JIRA",
      jira_issue_transition_id: '1'
    }

    jira_tracker.update_attributes(properties: properties, active: true)
  end

  def jira_issue_comments
    "{\"startAt\":0,\"maxResults\":11,\"total\":11,
      \"comments\":[{\"self\":\"http://0.0.0.0:4567/rest/api/2/issue/10002/comment/10609\",
      \"id\":\"10609\",\"author\":{\"self\":\"http://0.0.0.0:4567/rest/api/2/user?username=gitlab\",
      \"name\":\"gitlab\",\"emailAddress\":\"gitlab@example.com\",
      \"avatarUrls\":{\"16x16\":\"http://0.0.0.0:4567/secure/useravatar?size=xsmall&avatarId=10122\",
      \"24x24\":\"http://0.0.0.0:4567/secure/useravatar?size=small&avatarId=10122\",
      \"32x32\":\"http://0.0.0.0:4567/secure/useravatar?size=medium&avatarId=10122\",
      \"48x48\":\"http://0.0.0.0:4567/secure/useravatar?avatarId=10122\"},
      \"displayName\":\"GitLab\",\"active\":true},
      \"body\":\"[Administrator|http://localhost:3000/u/root] mentioned JIRA-1 in Merge request of [gitlab-org/gitlab-test|http://localhost:3000/gitlab-org/gitlab-test/merge_requests/2].\",
      \"updateAuthor\":{\"self\":\"http://0.0.0.0:4567/rest/api/2/user?username=gitlab\",\"name\":\"gitlab\",\"emailAddress\":\"gitlab@example.com\",
      \"avatarUrls\":{\"16x16\":\"http://0.0.0.0:4567/secure/useravatar?size=xsmall&avatarId=10122\",
      \"24x24\":\"http://0.0.0.0:4567/secure/useravatar?size=small&avatarId=10122\",
      \"32x32\":\"http://0.0.0.0:4567/secure/useravatar?size=medium&avatarId=10122\",
      \"48x48\":\"http://0.0.0.0:4567/secure/useravatar?avatarId=10122\"},\"displayName\":\"GitLab\",\"active\":true},
      \"created\":\"2015-02-12T22:47:07.826+0100\",
      \"updated\":\"2015-02-12T22:47:07.826+0100\"},
     {\"self\":\"http://0.0.0.0:4567/rest/api/2/issue/10002/comment/10700\",
        \"id\":\"10700\",\"author\":{\"self\":\"http://0.0.0.0:4567/rest/api/2/user?username=gitlab\",
        \"name\":\"gitlab\",\"emailAddress\":\"gitlab@example.com\",
        \"avatarUrls\":{\"16x16\":\"http://0.0.0.0:4567/secure/useravatar?size=xsmall&avatarId=10122\",
        \"24x24\":\"http://0.0.0.0:4567/secure/useravatar?size=small&avatarId=10122\",
        \"32x32\":\"http://0.0.0.0:4567/secure/useravatar?size=medium&avatarId=10122\",
        \"48x48\":\"http://0.0.0.0:4567/secure/useravatar?avatarId=10122\"},\"displayName\":\"GitLab\",\"active\":true},
        \"body\":\"[Administrator|http://localhost:3000/u/root] mentioned this issue in [a commit of h5bp/html5-boilerplate|http://localhost:3000/h5bp/html5-boilerplate/commit/2439f77897122fbeee3bfd9bb692d3608848433e].\",
        \"updateAuthor\":{\"self\":\"http://0.0.0.0:4567/rest/api/2/user?username=gitlab\",\"name\":\"gitlab\",\"emailAddress\":\"gitlab@example.com\",
        \"avatarUrls\":{\"16x16\":\"http://0.0.0.0:4567/secure/useravatar?size=xsmall&avatarId=10122\",
        \"24x24\":\"http://0.0.0.0:4567/secure/useravatar?size=small&avatarId=10122\",
        \"32x32\":\"http://0.0.0.0:4567/secure/useravatar?size=medium&avatarId=10122\",
        \"48x48\":\"http://0.0.0.0:4567/secure/useravatar?avatarId=10122\"},\"displayName\":\"GitLab\",\"active\":true},
        \"created\":\"2015-04-01T03:45:55.667+0200\",
        \"updated\":\"2015-04-01T03:45:55.667+0200\"
      }
      ]}"
  end

  def jira_project_url
    JIRA_API + "/project"
  end

  def jira_api_comment_url(issue_id)
    JIRA_API + "/issue/#{issue_id}/comment"
  end

  def jira_api_remote_link_url(issue_id)
    JIRA_API + "/issue/#{issue_id}/remotelink"
  end

  def jira_api_transition_url(issue_id)
    JIRA_API + "/issue/#{issue_id}/transitions"
  end

  def jira_api_test_url
    JIRA_API + "/myself"
  end

  def jira_issue_url(issue_id)
    JIRA_API + "/issue/#{issue_id}"
  end

  def stub_jira_urls(issue_id)
    WebMock.stub_request(:get, jira_project_url)
    WebMock.stub_request(:get, jira_api_comment_url(issue_id)).to_return(body: jira_issue_comments)
    WebMock.stub_request(:get, jira_issue_url(issue_id))
    WebMock.stub_request(:get, jira_api_test_url)
    WebMock.stub_request(:post, jira_api_comment_url(issue_id))
    WebMock.stub_request(:post, jira_api_remote_link_url(issue_id))
    WebMock.stub_request(:post, jira_api_transition_url(issue_id))
  end
end
