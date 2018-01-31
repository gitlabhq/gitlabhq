require 'spec_helper'

describe JiraService do
  include Gitlab::Routing

  describe '#options' do
    let(:service) do
      described_class.new(
        project: build_stubbed(:project),
        active: true,
        username: 'username',
        password: 'test',
        jira_issue_transition_id: 24,
        url: 'http://jira.test.com/path/'
      )
    end

    it 'sets the URL properly' do
      # jira-ruby gem parses the URI and handles trailing slashes
      # fine: https://github.com/sumoheavy/jira-ruby/blob/v1.4.1/lib/jira/http_client.rb#L59
      expect(service.options[:site]).to eq('http://jira.test.com/')
    end

    it 'leaves out trailing slashes in context' do
      expect(service.options[:context_path]).to eq('/path')
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:url) }
      it_behaves_like 'issue tracker service URL attribute', :url
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:url) }
      it { is_expected.not_to validate_presence_of(:username) }
      it { is_expected.not_to validate_presence_of(:password) }
    end

    context 'validating urls' do
      let(:service) do
        described_class.new(
          project: create(:project),
          active: true,
          username: 'username',
          password: 'test',
          jira_issue_transition_id: 24,
          url: 'http://jira.test.com'
        )
      end

      it 'is valid when all fields have required values' do
        expect(service).to be_valid
      end

      it 'is not valid when url is not a valid url' do
        service.url = 'not valid'

        expect(service).not_to be_valid
      end

      it 'is not valid when api url is not a valid url' do
        service.api_url = 'not valid'

        expect(service).not_to be_valid
      end

      it 'is not valid when username is missing' do
        service.username = nil

        expect(service).not_to be_valid
      end

      it 'is not valid when password is missing' do
        service.password = nil

        expect(service).not_to be_valid
      end

      it 'is valid when api url is a valid url' do
        service.api_url = 'http://jira.test.com/api'

        expect(service).to be_valid
      end
    end
  end

  describe '.reference_pattern' do
    it_behaves_like 'allows project key on reference pattern'

    it 'does not allow # on the code' do
      expect(described_class.reference_pattern.match('#123')).to be_nil
      expect(described_class.reference_pattern.match('1#23#12')).to be_nil
    end
  end

  describe '#close_issue' do
    let(:custom_base_url) { 'http://custom_url' }
    let(:user)    { create(:user) }
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request) }

    before do
      @jira_service = described_class.new
      allow(@jira_service).to receive_messages(
        project_id: project.id,
        project: project,
        service_hook: true,
        url: 'http://jira.example.com',
        username: 'gitlab_jira_username',
        password: 'gitlab_jira_password',
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
      allow(JIRA::Resource::Remotelink).to receive(:all).and_return([])

      @jira_service.save

      project_issues_url = 'http://jira.example.com/rest/api/2/issue/JIRA-123'
      @transitions_url   = 'http://jira.example.com/rest/api/2/issue/JIRA-123/transitions'
      @comment_url       = 'http://jira.example.com/rest/api/2/issue/JIRA-123/comment'
      @remote_link_url   = 'http://jira.example.com/rest/api/2/issue/JIRA-123/remotelink'

      WebMock.stub_request(:get, project_issues_url).with(basic_auth: %w(gitlab_jira_username gitlab_jira_password))
      WebMock.stub_request(:post, @transitions_url).with(basic_auth: %w(gitlab_jira_username gitlab_jira_password))
      WebMock.stub_request(:post, @comment_url).with(basic_auth: %w(gitlab_jira_username gitlab_jira_password))
      WebMock.stub_request(:post, @remote_link_url).with(basic_auth: %w(gitlab_jira_username gitlab_jira_password))
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
            url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/commit/#{merge_request.diff_head_sha}",
            title: "GitLab: Solved by commit #{merge_request.diff_head_sha}.",
            icon: { title: "GitLab", url16x16: "https://gitlab.com/favicon.ico" },
            status: { resolved: true }
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

    it "does not send comment or remote links to issues with unknown resolution" do
      allow_any_instance_of(JIRA::Resource::Issue).to receive(:respond_to?).with(:resolution).and_return(false)

      @jira_service.close_issue(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).not_to have_requested(:post, @comment_url)
      expect(WebMock).not_to have_requested(:post, @remote_link_url)
    end

    it "references the GitLab commit/merge request" do
      stub_config_setting(base_url: custom_base_url)

      @jira_service.close_issue(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).to have_requested(:post, @comment_url).with(
        body: /#{custom_base_url}\/#{project.full_path}\/commit\/#{merge_request.diff_head_sha}/
      ).once
    end

    it "references the GitLab commit/merge request (relative URL)" do
      stub_config_setting(relative_url_root: '/gitlab')
      stub_config_setting(url: Settings.send(:build_gitlab_url))

      allow(described_class).to receive(:default_url_options) do
        { script_name: '/gitlab' }
      end

      @jira_service.close_issue(merge_request, ExternalIssue.new("JIRA-123", project))

      expect(WebMock).to have_requested(:post, @comment_url).with(
        body: /#{Gitlab.config.gitlab.url}\/#{project.full_path}\/commit\/#{merge_request.diff_head_sha}/
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
        project: create(:project),
        url: 'http://jira.example.com',
        username: 'jira_username',
        password: 'jira_password'
      )
    end

    def test_settings(api_url = nil)
      api_url ||= 'jira.example.com'
      test_url = "http://#{api_url}/rest/api/2/serverInfo"

      WebMock.stub_request(:get, test_url).with(basic_auth: %w(jira_username jira_password)).to_return(body: { url: 'http://url' }.to_json )

      jira_service.test(nil)
    end

    context 'when the test succeeds' do
      it 'tries to get JIRA project with URL when API URL not set' do
        test_settings('jira.example.com')
      end

      it 'returns correct result' do
        expect(test_settings).to eq( { success: true, result: { 'url' => 'http://url' } })
      end

      it 'tries to get JIRA project with API URL if set' do
        jira_service.update(api_url: 'http://jira.api.com')
        test_settings('jira.api.com')
      end
    end

    context 'when the test fails' do
      it 'returns result with the error' do
        test_url = 'http://jira.example.com/rest/api/2/serverInfo'
        WebMock.stub_request(:get, test_url).with(basic_auth: %w(jira_username jira_password))
          .to_raise(JIRA::HTTPError.new(double(message: 'Some specific failure.')))

        expect(jira_service.test(nil)).to eq( { success: false, result: 'Some specific failure.' })
      end
    end
  end

  describe "Stored password invalidation" do
    let(:project) { create(:project) }

    context "when a password was previously set" do
      before do
        @jira_service = described_class.create!(
          project: project,
          properties: {
            url: 'http://jira.example.com/web',
            username: 'mic',
            password: "password"
          }
        )
      end

      context 'when only web url present' do
        it 'reset password if url changed' do
          @jira_service.url = 'http://jira_edited.example.com/rest/api/2'
          @jira_service.save

          expect(@jira_service.password).to be_nil
        end

        it 'reset password if url not changed but api url added' do
          @jira_service.api_url = 'http://jira_edited.example.com/rest/api/2'
          @jira_service.save

          expect(@jira_service.password).to be_nil
        end
      end

      context 'when both web and api url present' do
        before do
          @jira_service.api_url = 'http://jira.example.com/rest/api/2'
          @jira_service.password = 'password'

          @jira_service.save
        end
        it 'reset password if api url changed' do
          @jira_service.api_url = 'http://jira_edited.example.com/rest/api/2'
          @jira_service.save

          expect(@jira_service.password).to be_nil
        end

        it 'does not reset password if url changed' do
          @jira_service.url = 'http://jira_edited.example.com/rweb'
          @jira_service.save

          expect(@jira_service.password).to eq("password")
        end

        it 'reset password if api url set to ""' do
          @jira_service.api_url = ''
          @jira_service.save

          expect(@jira_service.password).to be_nil
        end
      end

      it 'does not reset password if username changed' do
        @jira_service.username = 'some_name'
        @jira_service.save

        expect(@jira_service.password).to eq('password')
      end

      it 'does not reset password if new url is set together with password, even if it\'s the same password' do
        @jira_service.url = 'http://jira_edited.example.com/rest/api/2'
        @jira_service.password = 'password'
        @jira_service.save

        expect(@jira_service.password).to eq('password')
        expect(@jira_service.url).to eq('http://jira_edited.example.com/rest/api/2')
      end

      it 'resets password if url changed, even if setter called multiple times' do
        @jira_service.url = 'http://jira1.example.com/rest/api/2'
        @jira_service.url = 'http://jira1.example.com/rest/api/2'
        @jira_service.save
        expect(@jira_service.password).to be_nil
      end
    end

    context 'when no password was previously set' do
      before do
        @jira_service = described_class.create(
          project: project,
          properties: {
            url: 'http://jira.example.com/rest/api/2',
            username: 'mic'
          }
        )
      end

      it 'saves password if new url is set together with password' do
        @jira_service.url = 'http://jira_edited.example.com/rest/api/2'
        @jira_service.password = 'password'
        @jira_service.save
        expect(@jira_service.password).to eq('password')
        expect(@jira_service.url).to eq('http://jira_edited.example.com/rest/api/2')
      end
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

  describe 'additional cookies' do
    let(:project) { create(:project) }

    context 'provides additional cookies to allow basic auth with oracle webgate' do
      before do
        @service = project.create_jira_service(
          active: true, properties: { url: 'http://jira.com' })
      end

      after do
        @service.destroy!
      end

      it 'is initialized' do
        expect(@service.options[:use_cookies]).to eq(true)
        expect(@service.options[:additional_cookies]).to eq(["OBBasicAuth=fromDialog"])
      end
    end
  end

  describe 'project and issue urls' do
    let(:project) { create(:project) }

    context 'when gitlab.yml was initialized' do
      before do
        settings = {
          'jira' => {
            'title' => 'Jira',
            'url' => 'http://jira.sample/projects/project_a',
            'api_url' => 'http://jira.sample/api'
          }
        }
        allow(Gitlab.config).to receive(:issues_tracker).and_return(settings)
        @service = project.create_jira_service(active: true)
      end

      after do
        @service.destroy!
      end

      it 'is prepopulated with the settings' do
        expect(@service.properties['title']).to eq('Jira')
        expect(@service.properties['url']).to eq('http://jira.sample/projects/project_a')
        expect(@service.properties['api_url']).to eq('http://jira.sample/api')
      end
    end
  end
end
