# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

require 'spec_helper'

describe JiraService, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }

      it { is_expected.to validate_presence_of(:api_url) }
      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }
      it { is_expected.to validate_presence_of(:new_issue_url) }
      it_behaves_like 'issue tracker service URL attribute', :api_url
      it_behaves_like 'issue tracker service URL attribute', :project_url
      it_behaves_like 'issue tracker service URL attribute', :issues_url
      it_behaves_like 'issue tracker service URL attribute', :new_issue_url
    end

    context 'when service is inactive' do
      before { subject.active = false }

      it { is_expected.not_to validate_presence_of(:api_url) }
      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
      it { is_expected.not_to validate_presence_of(:new_issue_url) }
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
        project_url: 'http://jira.example.com',
        username: 'gitlab_jira_username',
        password: 'gitlab_jira_password'
      )
      @jira_service.save # will build API URL, as api_url was not specified above
      @sample_data = Gitlab::PushDataBuilder.build_sample(project, user)
      # https://github.com/bblimke/webmock#request-with-basic-authentication
      @api_url = 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/issue/JIRA-123/transitions'
      @comment_url = 'http://gitlab_jira_username:gitlab_jira_password@jira.example.com/rest/api/2/issue/JIRA-123/comment'

      WebMock.stub_request(:post, @api_url)
      WebMock.stub_request(:post, @comment_url)
    end

    it "should call JIRA API" do
      @jira_service.execute(merge_request,
                            ExternalIssue.new("JIRA-123", project))
      expect(WebMock).to have_requested(:post, @comment_url).with(
        body: /Issue solved with/
      ).once
    end

    it "calls the api with jira_issue_transition_id" do
      @jira_service.jira_issue_transition_id = 'this-is-a-custom-id'
      @jira_service.execute(merge_request,
                            ExternalIssue.new("JIRA-123", project))
      expect(WebMock).to have_requested(:post, @api_url).with(
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
            api_url: 'http://jira.example.com/rest/api/2',
            username: 'mic',
            password: "password"
          }
        )
      end
  
      it "reset password if url changed" do
        @jira_service.api_url = 'http://jira_edited.example.com/rest/api/2'
        @jira_service.save
        expect(@jira_service.password).to be_nil
      end
  
      it "does not reset password if username changed" do
        @jira_service.username = "some_name"
        @jira_service.save
        expect(@jira_service.password).to eq("password")
      end

      it "does not reset password if new url is set together with password, even if it's the same password" do
        @jira_service.api_url = 'http://jira_edited.example.com/rest/api/2'
        @jira_service.password = 'password'
        @jira_service.save
        expect(@jira_service.password).to eq("password")
        expect(@jira_service.api_url).to eq("http://jira_edited.example.com/rest/api/2")
      end

      it "should reset password if url changed, even if setter called multiple times" do
        @jira_service.api_url = 'http://jira1.example.com/rest/api/2'
        @jira_service.api_url = 'http://jira1.example.com/rest/api/2'
        @jira_service.save
        expect(@jira_service.password).to be_nil
      end
    end
    
    context "when no password was previously set" do
      before do
        @jira_service = JiraService.create(
          project: create(:project),
          properties: {
            api_url: 'http://jira.example.com/rest/api/2',
            username: 'mic'
          }
        )
      end

      it "saves password if new url is set together with password" do
        @jira_service.api_url = 'http://jira_edited.example.com/rest/api/2'
        @jira_service.password = 'password'
        @jira_service.save
        expect(@jira_service.password).to eq("password")
        expect(@jira_service.api_url).to eq("http://jira_edited.example.com/rest/api/2")
      end
    end
  end

  describe "Validations" do
    context "active" do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :project_url }
      it { is_expected.to validate_presence_of :issues_url }
      it { is_expected.to validate_presence_of :new_issue_url }
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

      it 'should be initialized' do
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

      it "should be correct" do
        expect(@service.title).to eq('Jira One')
        expect(@service.description).to eq('Jira One issue tracker')
      end
    end
  end

  describe 'project and issue urls' do
    let(:project) { create(:project) }

    context 'when gitlab.yml was initialized' do
      before do
        settings = { "jira" => {
          "title" => "Jira",
          "project_url" => "http://jira.sample/projects/project_a",
          "issues_url" => "http://jira.sample/issues/:id",
          "new_issue_url" => "http://jira.sample/projects/project_a/issues/new"
          }
        }
        allow(Gitlab.config).to receive(:issues_tracker).and_return(settings)
        @service = project.create_jira_service(active: true)
      end

      after do
        @service.destroy!
      end

      it 'should be prepopulated with the settings' do
        expect(@service.properties["project_url"]).to eq('http://jira.sample/projects/project_a')
        expect(@service.properties["issues_url"]).to eq("http://jira.sample/issues/:id")
        expect(@service.properties["new_issue_url"]).to eq("http://jira.sample/projects/project_a/issues/new")
      end
    end
  end
end
