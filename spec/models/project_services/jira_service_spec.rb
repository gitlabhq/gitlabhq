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

  describe "Execute" do
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
        password: 'gitlab_jira_password'
      )

      @jira_service.save

      project_url = 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/issue/JIRA-123'
      @transitions_url = 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/issue/JIRA-123/transitions'
      @comment_url = 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/issue/JIRA-123/comment'

      WebMock.stub_request(:get, project_url)
      WebMock.stub_request(:post, @transitions_url)
      WebMock.stub_request(:post, @comment_url)
    end

    it "calls JIRA API" do
      @jira_service.execute(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).to have_requested(:post, @comment_url).with(
        body: /Issue solved with/
      ).once
    end

    it "references the GitLab commit/merge request" do
      @jira_service.execute(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).to have_requested(:post, @comment_url).with(
        body: /#{Gitlab.config.gitlab.url}\/#{project.path_with_namespace}\/commit\/#{merge_request.diff_head_sha}/
      ).once
    end

    it "references the GitLab commit/merge request (relative URL)" do
      stub_config_setting(relative_url_root: '/gitlab')
      stub_config_setting(url: Settings.send(:build_gitlab_url))

      Project.default_url_options[:script_name] = "/gitlab"

      @jira_service.execute(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).to have_requested(:post, @comment_url).with(
        body: /#{Gitlab.config.gitlab.url}\/#{project.path_with_namespace}\/commit\/#{merge_request.diff_head_sha}/
      ).once
    end

    it "calls the api with jira_issue_transition_id" do
      @jira_service.jira_issue_transition_id = 'this-is-a-custom-id'
      @jira_service.execute(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).to have_requested(:post, @transitions_url).with(
        body: /this-is-a-custom-id/
      ).once
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
