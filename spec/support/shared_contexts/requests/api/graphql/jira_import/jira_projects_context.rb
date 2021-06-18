# frozen_string_literal: true

RSpec.shared_context 'Jira projects request context' do
  let(:url) { 'https://jira.example.com' }
  let(:username) { 'jira-username' }
  let(:password) { 'jira-password' }
  let!(:jira_integration) do
    create(:jira_integration,
      project: project,
      url: url,
      username: username,
      password: password
    )
  end

  let_it_be(:jira_projects_json) do
    '{
          "self": "https://your-domain.atlassian.net/rest/api/2/project/search?startAt=0&maxResults=2",
          "nextPage": "https://your-domain.atlassian.net/rest/api/2/project/search?startAt=2&maxResults=2",
          "maxResults": 2,
          "startAt": 0,
          "total": 7,
          "isLast": false,
          "values": [
            {
              "self": "https://your-domain.atlassian.net/rest/api/2/project/EX",
              "id": "10000",
              "key": "EX",
              "name": "Example",
              "avatarUrls": {
                "48x48": "https://your-domain.atlassian.net/secure/projectavatar?size=large&pid=10000",
                "24x24": "https://your-domain.atlassian.net/secure/projectavatar?size=small&pid=10000",
                "16x16": "https://your-domain.atlassian.net/secure/projectavatar?size=xsmall&pid=10000",
                "32x32": "https://your-domain.atlassian.net/secure/projectavatar?size=medium&pid=10000"
              },
              "projectCategory": {
                "self": "https://your-domain.atlassian.net/rest/api/2/projectCategory/10000",
                "id": "10000",
                "name": "FIRST",
                "description": "First Project Category"
              },
              "simplified": false,
              "style": "classic",
              "insight": {
                "totalIssueCount": 100,
                "lastIssueUpdateTime": "2020-03-31T05:45:24.792+0000"
              }
            },
            {
              "self": "https://your-domain.atlassian.net/rest/api/2/project/ABC",
              "id": "10001",
              "key": "ABC",
              "name": "Alphabetical",
              "avatarUrls": {
                "48x48": "https://your-domain.atlassian.net/secure/projectavatar?size=large&pid=10001",
                "24x24": "https://your-domain.atlassian.net/secure/projectavatar?size=small&pid=10001",
                "16x16": "https://your-domain.atlassian.net/secure/projectavatar?size=xsmall&pid=10001",
                "32x32": "https://your-domain.atlassian.net/secure/projectavatar?size=medium&pid=10001"
              },
              "projectCategory": {
                "self": "https://your-domain.atlassian.net/rest/api/2/projectCategory/10000",
                "id": "10000",
                "name": "FIRST",
                "description": "First Project Category"
              },
              "simplified": false,
              "style": "classic",
              "insight": {
                "totalIssueCount": 100,
                "lastIssueUpdateTime": "2020-03-31T05:45:24.792+0000"
              }
            }
          ]
        }'
  end

  let_it_be(:all_jira_projects_json) do
    '[{
      "expand": "description,lead,issueTypes,url,projectKeys,permissions,insight",
      "self": "https://gitlab-jira.atlassian.net/rest/api/2/project/10000",
      "id": "10000",
      "key": "EX",
      "name": "Example",
      "avatarUrls": {
        "48x48": "https://gitlab-jira.atlassian.net/secure/projectavatar?pid=10000&avatarId=10425",
        "24x24": "https://gitlab-jira.atlassian.net/secure/projectavatar?size=small&s=small&pid=10000&avatarId=10425",
        "16x16": "https://gitlab-jira.atlassian.net/secure/projectavatar?size=xsmall&s=xsmall&pid=10000&avatarId=10425",
        "32x32": "https://gitlab-jira.atlassian.net/secure/projectavatar?size=medium&s=medium&pid=10000&avatarId=10425"
      },
      "projectTypeKey": "software",
      "simplified": false,
      "style": "classic",
      "isPrivate": false,
      "properties": {
      }
    },
    {
      "expand": "description,lead,issueTypes,url,projectKeys,permissions,insight",
      "self": "https://gitlab-jira.atlassian.net/rest/api/2/project/10001",
      "id": "10001",
      "key": "ABC",
      "name": "Alphabetical",
      "avatarUrls": {
        "48x48": "https://gitlab-jira.atlassian.net/secure/projectavatar?pid=10001&avatarId=10405",
        "24x24": "https://gitlab-jira.atlassian.net/secure/projectavatar?size=small&s=small&pid=10001&avatarId=10405",
        "16x16": "https://gitlab-jira.atlassian.net/secure/projectavatar?size=xsmall&s=xsmall&pid=10001&avatarId=10405",
        "32x32": "https://gitlab-jira.atlassian.net/secure/projectavatar?size=medium&s=medium&pid=10001&avatarId=10405"
      },
      "projectTypeKey": "software",
      "simplified": true,
      "style": "next-gen",
      "isPrivate": false,
      "properties": {
      },
      "entityId": "14935009-f8aa-481e-94bc-f7251f320b0e",
      "uuid": "14935009-f8aa-481e-94bc-f7251f320b0e"
    }]'
  end

  let_it_be(:empty_jira_projects_json) do
    '{
          "self": "https://your-domain.atlassian.net/rest/api/2/project/search?startAt=0&maxResults=2",
          "nextPage": "https://your-domain.atlassian.net/rest/api/2/project/search?startAt=2&maxResults=2",
          "maxResults": 2,
          "startAt": 0,
          "total": 7,
          "isLast": false,
          "values": []
    }'
  end

  let(:server_info_json) do
    '{
      "baseUrl": "https://gitlab-jira.atlassian.net",
      "version": "1001.0.0-SNAPSHOT",
      "versionNumbers": [
        1001,
        0,
        0
      ],
      "deploymentType": "Cloud",
      "buildNumber": 100128,
      "buildDate": "2020-06-03T01:58:44.000-0700",
      "serverTime": "2020-06-04T06:15:13.686-0700",
      "scmInfo": "e736ab140ddb281c7cf5dcf9062c9ce2c08b3c1c",
      "serverTitle": "Jira",
      "defaultLocale": {
        "locale": "en_US"
      }
    }'
  end

  let(:test_url) { "#{url}/rest/api/2/project/search?maxResults=50&query=&startAt=0" }
  let(:start_at_20_url) { "#{url}/rest/api/2/project/search?maxResults=50&query=&startAt=20" }
  let(:start_at_1_url) { "#{url}/rest/api/2/project/search?maxResults=50&query=&startAt=1" }
  let(:max_results_1_url) { "#{url}/rest/api/2/project/search?maxResults=1&query=&startAt=0" }
  let(:all_projects_url) { "#{url}/rest/api/2/project" }

  before do
    WebMock.stub_request(:get, test_url).with(basic_auth: [username, password])
      .to_return(body: jira_projects_json, headers: { "Content-Type": "application/json" })
    WebMock.stub_request(:get, start_at_20_url).with(basic_auth: [username, password])
      .to_return(body: empty_jira_projects_json, headers: { "Content-Type": "application/json" })
    WebMock.stub_request(:get, start_at_1_url).with(basic_auth: [username, password])
      .to_return(body: jira_projects_json, headers: { "Content-Type": "application/json" })
    WebMock.stub_request(:get, max_results_1_url).with(basic_auth: [username, password])
      .to_return(body: jira_projects_json, headers: { "Content-Type": "application/json" })
    WebMock.stub_request(:get, all_projects_url).with(basic_auth: [username, password])
      .to_return(body: all_jira_projects_json, headers: { "Content-Type": "application/json" })
    WebMock.stub_request(:get, 'https://jira.example.com/rest/api/2/serverInfo')
      .to_return(status: 200, body: server_info_json, headers: {})
  end
end
