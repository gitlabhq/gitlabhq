require 'spec_helper'

describe JiraService, models: true do
  include Gitlab::Routing.url_helpers

  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }

      it { is_expected.to validate_presence_of(:url) }
      it { is_expected.to validate_presence_of(:project_key) }
      it_behaves_like 'issue tracker service URL attribute', :url
    end

    context 'when service is inactive' do
      before { subject.active = false }

      it { is_expected.not_to validate_presence_of(:url) }
    end
  end

  describe '#reference_pattern' do
    it_behaves_like 'allows project key on reference pattern'

    it 'does not allow # on the code' do
      expect(subject.reference_pattern.match('#123')).to be_nil
      expect(subject.reference_pattern.match('1#23#12')).to be_nil
    end
  end

  describe '#can_test?' do
    let(:jira_service) { described_class.new }

    it 'returns false if username is blank' do
      allow(jira_service).to receive_messages(
        url: 'http://jira.example.com',
        username: '',
        password: '12345678'
      )

      expect(jira_service.can_test?).to be_falsy
    end

    it 'returns false if password is blank' do
      allow(jira_service).to receive_messages(
        url: 'http://jira.example.com',
        username: 'tester',
        password: ''
      )

      expect(jira_service.can_test?).to be_falsy
    end

    it 'returns true if password and username are present' do
      jira_service = described_class.new
      allow(jira_service).to receive_messages(
        url: 'http://jira.example.com',
        username: 'tester',
        password: '12345678'
      )

      expect(jira_service.can_test?).to be_truthy
    end
  end

  describe '#close_issue' do
    let(:custom_base_url) { 'http://custom_url' }
    let(:user)    { create(:user) }
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request) }

    before do
      @jira_service = JiraService.new
      allow(@jira_service).to receive_messages(
        project_id: project.id,
        project: project,
        service_hook: true,
        url: 'http://jira.example.com',
        username: 'gitlab_jira_username',
        password: 'gitlab_jira_password',
        project_key: 'GitLabProject',
        jira_issue_transition_id: "custom-id"
      )

      # These stubs are needed to test JiraService#close_issue.
      # We close the issue then do another request to API to check if it got closed.
      # Here is stubbed the API return with a closed and an opened issues.
      open_issue   = JIRA::Resource::Issue.new(@jira_service.client, attrs: { "id" => "JIRA-123" })
      closed_issue = open_issue.dup
      allow(open_issue).to receive(:resolution).and_return(false)
      allow(closed_issue).to receive(:resolution).and_return(true)
      allow(JIRA::Resource::Issue).to receive(:find).and_return(open_issue, closed_issue)

      allow_any_instance_of(JIRA::Resource::Issue).to receive(:key).and_return("JIRA-123")

      @jira_service.save

      project_issues_url = 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/issue/JIRA-123'
      @transitions_url   = 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/issue/JIRA-123/transitions'
      @comment_url       = 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/issue/JIRA-123/comment'
      @remote_link_url   = 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/issue/JIRA-123/remotelink'

      WebMock.stub_request(:get, project_issues_url)
      WebMock.stub_request(:post, @transitions_url)
      WebMock.stub_request(:post, @comment_url)
      WebMock.stub_request(:post, @remote_link_url)
    end

    it "calls JIRA API" do
      @jira_service.close_issue(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).to have_requested(:post, @comment_url).with(
        body: /Issue solved with/
      ).once
    end

    # Check https://developer.atlassian.com/jiradev/jira-platform/guides/other/guide-jira-remote-issue-links/fields-in-remote-issue-links
    # for more information
    it "creates Remote Link reference in JIRA for comment" do
      @jira_service.close_issue(merge_request, ExternalIssue.new("JIRA-123", project))

      # Creates comment
      expect(WebMock).to have_requested(:post, @comment_url)

      # Creates Remote Link in JIRA issue fields
      expect(WebMock).to have_requested(:post, @remote_link_url).with(
        body: hash_including(
          GlobalID: "GitLab",
          object: {
            url: "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/commit/#{merge_request.diff_head_sha}",
            title: "GitLab: Solved by commit #{merge_request.diff_head_sha}.",
            icon: { title: "GitLab", url16x16: "https://gitlab.com/favicon.ico" },
            status: { resolved: true, icon: { url16x16: "http://www.openwebgraphics.com/resources/data/1768/16x16_apply.png", title: "Closed" } }
          }
        )
      ).once
    end

    it "does not send comment or remote links to issues already closed" do
      allow_any_instance_of(JIRA::Resource::Issue).to receive(:resolution).and_return(true)

      @jira_service.close_issue(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).not_to have_requested(:post, @comment_url)
      expect(WebMock).not_to have_requested(:post, @remote_link_url)
    end

    it "references the GitLab commit/merge request" do
      stub_config_setting(base_url: custom_base_url)

      @jira_service.close_issue(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).to have_requested(:post, @comment_url).with(
        body: /#{custom_base_url}\/#{project.path_with_namespace}\/commit\/#{merge_request.diff_head_sha}/
      ).once
    end

    it "references the GitLab commit/merge request (relative URL)" do
      stub_config_setting(relative_url_root: '/gitlab')
      stub_config_setting(url: Settings.send(:build_gitlab_url))

      allow(JiraService).to receive(:default_url_options) do
        { script_name: '/gitlab' }
      end

      @jira_service.close_issue(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).to have_requested(:post, @comment_url).with(
        body: /#{Gitlab.config.gitlab.url}\/#{project.path_with_namespace}\/commit\/#{merge_request.diff_head_sha}/
      ).once
    end

    it "calls the api with jira_issue_transition_id" do
      @jira_service.close_issue(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).to have_requested(:post, @transitions_url).with(
        body: /custom-id/
      ).once
    end
  end

  describe '#test_settings' do
    let(:jira_service) do
      described_class.new(
        url: 'http://jira.example.com',
        username: 'gitlab_jira_username',
        password: 'gitlab_jira_password',
        project_key: 'GitLabProject'
      )
    end
    let(:project_url) { 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/project/GitLabProject' }

    before do
      WebMock.stub_request(:get, project_url)
    end

    it 'tries to get JIRA project' do
      jira_service.test_settings

      expect(WebMock).to have_requested(:get, project_url)
    end
  end

  describe "Stored password invalidation" do
    let(:project) { create(:project) }

    context "when a password was previously set" do
      before do
        @jira_service = JiraService.create!(
          project: create(:project),
          properties: {
            url: 'http://jira.example.com/rest/api/2',
            username: 'mic',
            password: "password"
          }
        )
      end

      it "reset password if url changed" do
        @jira_service.url = 'http://jira_edited.example.com/rest/api/2'
        @jira_service.save
        expect(@jira_service.password).to be_nil
      end

      it "does not reset password if username changed" do
        @jira_service.username = "some_name"
        @jira_service.save
        expect(@jira_service.password).to eq("password")
      end

      it "does not reset password if new url is set together with password, even if it's the same password" do
        @jira_service.url = 'http://jira_edited.example.com/rest/api/2'
        @jira_service.password = 'password'
        @jira_service.save
        expect(@jira_service.password).to eq("password")
        expect(@jira_service.url).to eq("http://jira_edited.example.com/rest/api/2")
      end

      it "resets password if url changed, even if setter called multiple times" do
        @jira_service.url = 'http://jira1.example.com/rest/api/2'
        @jira_service.url = 'http://jira1.example.com/rest/api/2'
        @jira_service.save
        expect(@jira_service.password).to be_nil
      end
    end

    context "when no password was previously set" do
      before do
        @jira_service = JiraService.create(
          project: create(:project),
          properties: {
            url: 'http://jira.example.com/rest/api/2',
            username: 'mic'
          }
        )
      end

      it "saves password if new url is set together with password" do
        @jira_service.url = 'http://jira_edited.example.com/rest/api/2'
        @jira_service.password = 'password'
        @jira_service.save
        expect(@jira_service.password).to eq("password")
        expect(@jira_service.url).to eq("http://jira_edited.example.com/rest/api/2")
      end
    end
  end

  describe "Validations" do
    context "active" do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :url }
    end
  end

  describe 'description and title' do
    let(:project) { create(:project) }

    context 'when it is not set' do
      before do
        @service = project.create_jira_service(active: true)
      end

      after do
        @service.destroy!
      end

      it 'is initialized' do
        expect(@service.title).to eq('JIRA')
        expect(@service.description).to eq("Jira issue tracker")
      end
    end

    context 'when it is set' do
      before do
        properties = { 'title' => 'Jira One', 'description' => 'Jira One issue tracker' }
        @service = project.create_jira_service(active: true, properties: properties)
      end

      after do
        @service.destroy!
      end

      it "is correct" do
        expect(@service.title).to eq('Jira One')
        expect(@service.description).to eq('Jira One issue tracker')
      end
    end
  end

  describe 'project and issue urls' do
    let(:project) { create(:project) }

    context 'when gitlab.yml was initialized' do
      before do
        settings = {
          "jira" => {
            "title" => "Jira",
            "url" => "http://jira.sample/projects/project_a"
          }
        }
        allow(Gitlab.config).to receive(:issues_tracker).and_return(settings)
        @service = project.create_jira_service(active: true)
      end

      after do
        @service.destroy!
      end

      it 'is prepopulated with the settings' do
        expect(@service.properties["title"]).to eq('Jira')
        expect(@service.properties["url"]).to eq('http://jira.sample/projects/project_a')
      end
    end
  end
end
