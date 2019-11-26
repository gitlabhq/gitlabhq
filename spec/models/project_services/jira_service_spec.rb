# frozen_string_literal: true

require 'spec_helper'

describe JiraService do
  include Gitlab::Routing
  include AssetsHelpers

  let(:title) { 'custom title' }
  let(:description) { 'custom description' }
  let(:url) { 'http://jira.example.com' }
  let(:api_url) { 'http://api-jira.example.com' }
  let(:username) { 'jira-username' }
  let(:password) { 'jira-password' }
  let(:transition_id) { 'test27' }

  describe '#options' do
    let(:options) do
      {
        project: create(:project),
        active: true,
        username: 'username',
        password: 'test',
        jira_issue_transition_id: 24,
        url: 'http://jira.test.com/path/'
      }
    end

    let(:service) { described_class.create(options) }

    it 'sets the URL properly' do
      # jira-ruby gem parses the URI and handles trailing slashes fine:
      # https://github.com/sumoheavy/jira-ruby/blob/v1.7.0/lib/jira/http_client.rb#L62
      expect(service.options[:site]).to eq('http://jira.test.com/')
    end

    it 'leaves out trailing slashes in context' do
      expect(service.options[:context_path]).to eq('/path')
    end

    context 'username with trailing whitespaces' do
      before do
        options.merge!(username: 'username ')
      end

      it 'leaves out trailing whitespaces in username' do
        expect(service.options[:username]).to eq('username')
      end
    end

    it 'provides additional cookies to allow basic auth with oracle webgate' do
      expect(service.options[:use_cookies]).to eq(true)
      expect(service.options[:additional_cookies]).to eq(['OBBasicAuth=fromDialog'])
    end

    context 'using api URL' do
      before do
        options.merge!(api_url: 'http://jira.test.com/api_path/')
      end

      it 'leaves out trailing slashes in context' do
        expect(service.options[:context_path]).to eq('/api_path')
      end
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe '.reference_pattern' do
    it_behaves_like 'allows project key on reference pattern'

    it 'does not allow # on the code' do
      expect(described_class.reference_pattern.match('#123')).to be_nil
      expect(described_class.reference_pattern.match('1#23#12')).to be_nil
    end
  end

  describe '#create' do
    let(:params) do
      {
        project: create(:project),
        title: 'custom title', description: 'custom description',
        url: url, api_url: api_url,
        username: username, password: password,
        jira_issue_transition_id: transition_id
      }
    end

    subject { described_class.create(params) }

    it 'does not store data into properties' do
      expect(subject.properties).to be_nil
    end

    it 'sets title correctly' do
      service = subject

      expect(service.title).to eq('custom title')
    end

    it 'sets service data correctly' do
      service = subject

      expect(service.title).to eq('custom title')
      expect(service.description).to eq('custom description')
    end

    it 'stores data in data_fields correcty' do
      service = subject

      expect(service.jira_tracker_data.url).to eq(url)
      expect(service.jira_tracker_data.api_url).to eq(api_url)
      expect(service.jira_tracker_data.username).to eq(username)
      expect(service.jira_tracker_data.password).to eq(password)
      expect(service.jira_tracker_data.jira_issue_transition_id).to eq(transition_id)
    end
  end

  # we need to make sure we are able to read both from properties and jira_tracker_data table
  # TODO: change this as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
  context 'overriding properties' do
    let(:access_params) do
      { url: url, api_url: api_url, username: username, password: password,
        jira_issue_transition_id: transition_id }
    end
    let(:data_params) do
      {
        url: url, api_url: api_url,
        username: username, password: password,
        jira_issue_transition_id: transition_id
      }
    end

    shared_examples 'handles jira fields' do
      let(:data_params) do
        {
          url: url, api_url: api_url,
          username: username, password: password,
          jira_issue_transition_id: transition_id
        }
      end

      context 'reading data' do
        it 'reads data correctly' do
          expect(service.url).to eq(url)
          expect(service.api_url).to eq(api_url)
          expect(service.username).to eq(username)
          expect(service.password).to eq(password)
          expect(service.jira_issue_transition_id).to eq(transition_id)
        end
      end

      context '#update' do
        context 'basic update' do
          let(:new_username) { 'new_username' }
          let(:new_url) { 'http://jira-new.example.com' }

          before do
            service.update(username: new_username, url: new_url)
          end

          it 'leaves properties field emtpy' do
            # expect(service.reload.properties).to be_empty
          end

          it 'stores updated data in jira_tracker_data table' do
            data = service.jira_tracker_data.reload

            expect(data.url).to eq(new_url)
            expect(data.api_url).to eq(api_url)
            expect(data.username).to eq(new_username)
            expect(data.password).to eq(password)
            expect(data.jira_issue_transition_id).to eq(transition_id)
          end
        end

        context 'stored password invalidation' do
          context 'when a password was previously set' do
            context 'when only web url present' do
              let(:data_params) do
                {
                  url: url, api_url: nil,
                  username: username, password: password,
                  jira_issue_transition_id: transition_id
                }
              end

              it 'resets password if url changed' do
                service
                service.url = 'http://jira_edited.example.com'
                service.save

                expect(service.reload.url).to eq('http://jira_edited.example.com')
                expect(service.password).to be_nil
              end

              it 'does not reset password if url "changed" to the same url as before' do
                service.title = 'aaaaaa'
                service.url = 'http://jira.example.com'
                service.save

                expect(service.reload.url).to eq('http://jira.example.com')
                expect(service.password).not_to be_nil
              end

              it 'resets password if url not changed but api url added' do
                service.api_url = 'http://jira_edited.example.com/rest/api/2'
                service.save

                expect(service.reload.api_url).to eq('http://jira_edited.example.com/rest/api/2')
                expect(service.password).to be_nil
              end

              it 'does not reset password if new url is set together with password, even if it\'s the same password' do
                service.url = 'http://jira_edited.example.com'
                service.password = password
                service.save

                expect(service.password).to eq(password)
                expect(service.url).to eq('http://jira_edited.example.com')
              end

              it 'resets password if url changed, even if setter called multiple times' do
                service.url = 'http://jira1.example.com/rest/api/2'
                service.url = 'http://jira1.example.com/rest/api/2'
                service.save

                expect(service.password).to be_nil
              end

              it 'does not reset password if username changed' do
                service.username = 'some_name'
                service.save

                expect(service.reload.password).to eq(password)
              end

              it 'does not reset password if password changed' do
                service.url = 'http://jira_edited.example.com'
                service.password = 'new_password'
                service.save

                expect(service.reload.password).to eq('new_password')
              end

              it 'does not reset password if the password is touched and same as before' do
                service.url = 'http://jira_edited.example.com'
                service.password = password
                service.save

                expect(service.reload.password).to eq(password)
              end
            end

            context 'when both web and api url present' do
              let(:data_params) do
                {
                  url: url, api_url: 'http://jira.example.com/rest/api/2',
                  username: username, password: password,
                  jira_issue_transition_id: transition_id
                }
              end

              it 'resets password if api url changed' do
                service.api_url = 'http://jira_edited.example.com/rest/api/2'
                service.save

                expect(service.password).to be_nil
              end

              it 'does not reset password if url changed' do
                service.url = 'http://jira_edited.example.com'
                service.save

                expect(service.password).to eq(password)
              end

              it 'resets password if api url set to empty' do
                service.update(api_url: '')

                expect(service.reload.password).to be_nil
              end
            end
          end

          context 'when no password was previously set' do
            let(:data_params) do
              {
                url: url, username: username
              }
            end

            it 'saves password if new url is set together with password' do
              service.url = 'http://jira_edited.example.com/rest/api/2'
              service.password = 'password'
              service.save
              expect(service.reload.password).to eq('password')
              expect(service.reload.url).to eq('http://jira_edited.example.com/rest/api/2')
            end
          end
        end
      end
    end

    # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
    context 'when data are stored in properties' do
      let(:properties) { data_params.merge(title: title, description: description) }
      let!(:service) do
        create(:jira_service, :without_properties_callback, properties: properties.merge(additional: 'something'))
      end

      it_behaves_like 'issue tracker fields'
      it_behaves_like 'handles jira fields'
    end

    context 'when data are stored in separated fields' do
      let(:service) do
        create(:jira_service, data_params.merge(properties: {}, title: title, description: description))
      end

      it_behaves_like 'issue tracker fields'
      it_behaves_like 'handles jira fields'
    end

    context 'when data are stored in both properties and separated fields' do
      let(:properties) { data_params.merge(title: title, description: description) }
      let(:service) do
        create(:jira_service, :without_properties_callback, active: false, properties: properties).tap do |service|
          create(:jira_tracker_data, data_params.merge(service: service))
        end
      end

      it_behaves_like 'issue tracker fields'
      it_behaves_like 'handles jira fields'
    end

    context 'when no title & description are set' do
      let(:service) do
        create(:jira_service, properties: access_params)
      end

      it 'returns default values' do
        expect(service.title).to eq('Jira')
        expect(service.description).to eq('Jira issue tracker')
      end
    end
  end

  describe '#close_issue' do
    let(:custom_base_url) { 'http://custom_url' }
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }

    shared_examples 'close_issue' do
      before do
        @jira_service = described_class.new
        allow(@jira_service).to receive_messages(
          project_id: project.id,
          project: project,
          service_hook: true,
          url: 'http://jira.example.com',
          username: 'gitlab_jira_username',
          password: 'gitlab_jira_password',
          jira_issue_transition_id: '999'
        )

        # These stubs are needed to test JiraService#close_issue.
        # We close the issue then do another request to API to check if it got closed.
        # Here is stubbed the API return with a closed and an opened issues.
        open_issue   = JIRA::Resource::Issue.new(@jira_service.client, attrs: { 'id' => 'JIRA-123' })
        closed_issue = open_issue.dup
        allow(open_issue).to receive(:resolution).and_return(false)
        allow(closed_issue).to receive(:resolution).and_return(true)
        allow(JIRA::Resource::Issue).to receive(:find).and_return(open_issue, closed_issue)

        allow_any_instance_of(JIRA::Resource::Issue).to receive(:key).and_return('JIRA-123')
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

      it 'calls Jira API' do
        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).to have_requested(:post, @comment_url).with(
          body: /Issue solved with/
        ).once
      end

      it 'does not fail if remote_link.all on issue returns nil' do
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return(nil)

        expect { @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project)) }
            .not_to raise_error
      end

      # Check https://developer.atlassian.com/jiradev/jira-platform/guides/other/guide-jira-remote-issue-links/fields-in-remote-issue-links
      # for more information
      it 'creates Remote Link reference in Jira for comment' do
        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        favicon_path = "http://localhost/assets/#{find_asset('favicon.png').digest_path}"

        # Creates comment
        expect(WebMock).to have_requested(:post, @comment_url)
        # Creates Remote Link in Jira issue fields
        expect(WebMock).to have_requested(:post, @remote_link_url).with(
          body: hash_including(
            GlobalID: 'GitLab',
            relationship: 'mentioned on',
            object: {
              url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/commit/#{commit_id}",
              title: "Solved by commit #{commit_id}.",
              icon: { title: 'GitLab', url16x16: favicon_path },
              status: { resolved: true }
            }
          )
        ).once
      end

      context 'when "comment_on_event_enabled" is set to false' do
        it 'creates Remote Link reference but does not create comment' do
          allow(@jira_service).to receive_messages(comment_on_event_enabled: false)
          @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

          expect(WebMock).not_to have_requested(:post, @comment_url)
          expect(WebMock).to have_requested(:post, @remote_link_url)
        end
      end

      it 'does not send comment or remote links to issues already closed' do
        allow_any_instance_of(JIRA::Resource::Issue).to receive(:resolution).and_return(true)

        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).not_to have_requested(:post, @comment_url)
        expect(WebMock).not_to have_requested(:post, @remote_link_url)
      end

      it 'does not send comment or remote links to issues with unknown resolution' do
        allow_any_instance_of(JIRA::Resource::Issue).to receive(:respond_to?).with(:resolution).and_return(false)

        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).not_to have_requested(:post, @comment_url)
        expect(WebMock).not_to have_requested(:post, @remote_link_url)
      end

      it 'references the GitLab commit' do
        stub_config_setting(base_url: custom_base_url)

        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).to have_requested(:post, @comment_url).with(
          body: %r{#{custom_base_url}/#{project.full_path}/commit/#{commit_id}}
        ).once
      end

      it 'references the GitLab commit' do
        stub_config_setting(relative_url_root: '/gitlab')
        stub_config_setting(url: Settings.send(:build_gitlab_url))

        allow(described_class).to receive(:default_url_options) do
          { script_name: '/gitlab' }
        end

        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).to have_requested(:post, @comment_url).with(
          body: %r{#{Gitlab.config.gitlab.url}/#{project.full_path}/commit/#{commit_id}}
        ).once
      end

      it 'logs exception when transition id is not valid' do
        allow(@jira_service).to receive(:log_error)
        WebMock.stub_request(:post, @transitions_url).with(basic_auth: %w(gitlab_jira_username gitlab_jira_password)).and_raise("Bad Request")

        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(@jira_service).to have_received(:log_error).with("Issue transition failed", error: "Bad Request", client_url: "http://jira.example.com")
      end

      it 'calls the api with jira_issue_transition_id' do
        @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

        expect(WebMock).to have_requested(:post, @transitions_url).with(
          body: /999/
        ).once
      end

      context 'when have multiple transition ids' do
        it 'calls the api with transition ids separated by comma' do
          allow(@jira_service).to receive_messages(jira_issue_transition_id: '1,2,3')

          @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

          1.upto(3) do |transition_id|
            expect(WebMock).to have_requested(:post, @transitions_url).with(
              body: /#{transition_id}/
            ).once
          end
        end

        it 'calls the api with transition ids separated by semicolon' do
          allow(@jira_service).to receive_messages(jira_issue_transition_id: '1;2;3')

          @jira_service.close_issue(resource, ExternalIssue.new('JIRA-123', project))

          1.upto(3) do |transition_id|
            expect(WebMock).to have_requested(:post, @transitions_url).with(
              body: /#{transition_id}/
            ).once
          end
        end
      end
    end

    context 'when resource is a merge request' do
      let(:resource) { create(:merge_request) }
      let(:commit_id) { resource.diff_head_sha }

      it_behaves_like 'close_issue'
    end

    context 'when resource is a commit' do
      let(:resource) { project.commit('master') }
      let(:commit_id) { resource.id }

      it_behaves_like 'close_issue'
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
      it 'tries to get Jira project with URL when API URL not set' do
        test_settings('jira.example.com')
      end

      it 'returns correct result' do
        expect(test_settings).to eq( { success: true, result: { 'url' => 'http://url' } })
      end

      it 'tries to get Jira project with API URL if set' do
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

  describe 'description and title' do
    let(:title) { 'Jira One' }
    let(:description) { 'Jira One issue tracker' }
    let(:properties) do
      {
        url: 'http://jira.example.com/web',
        username: 'mic',
        password: 'password',
        title: title,
        description: description
      }
    end

    context 'when it is not set' do
      it 'default values are returned' do
        service = create(:jira_service)

        expect(service.title).to eq('Jira')
        expect(service.description).to eq('Jira issue tracker')
      end
    end

    context 'when it is set in properties' do
      it 'values from properties are returned' do
        service = create(:jira_service, :without_properties_callback, properties: properties)

        expect(service.title).to eq(title)
        expect(service.description).to eq(description)
      end
    end

    context 'when it is in title & description fields' do
      it 'values from title and description fields are returned' do
        service = create(:jira_service, title: title, description: description)

        expect(service.title).to eq(title)
        expect(service.description).to eq(description)
      end
    end

    context 'when it is in both properites & title & description fields' do
      it 'values from title and description fields are returned' do
        title2 = 'Jira 2'
        description2 = 'Jira description 2'

        service = create(:jira_service, title: title2, description: description2, properties: properties)

        expect(service.title).to eq(title2)
        expect(service.description).to eq(description2)
      end
    end
  end

  describe 'project and issue urls' do
    context 'when gitlab.yml was initialized' do
      it 'is prepopulated with the settings' do
        settings = {
          'jira' => {
            'url' => 'http://jira.sample/projects/project_a',
            'api_url' => 'http://jira.sample/api'
          }
        }
        allow(Gitlab.config).to receive(:issues_tracker).and_return(settings)

        project = create(:project)
        service = project.create_jira_service(active: true)

        expect(service.url).to eq('http://jira.sample/projects/project_a')
        expect(service.api_url).to eq('http://jira.sample/api')
      end
    end

    it 'removes trailing slashes from url' do
      service = described_class.new(url: 'http://jira.test.com/path/')

      expect(service.url).to eq('http://jira.test.com/path')
    end
  end

  describe 'favicon urls' do
    it 'includes the standard favicon' do
      props = described_class.new.send(:build_remote_link_props, url: 'http://example.com', title: 'title')
      expect(props[:object][:icon][:url16x16]).to match %r{^http://localhost/assets/favicon(?:-\h+).png$}
    end

    it 'includes returns the custom favicon' do
      create :appearance, favicon: fixture_file_upload('spec/fixtures/dk.png')

      props = described_class.new.send(:build_remote_link_props, url: 'http://example.com', title: 'title')
      expect(props[:object][:icon][:url16x16]).to match %r{^http://localhost/uploads/-/system/appearance/favicon/\d+/dk.png$}
    end
  end

  context 'generating external URLs' do
    let(:service) { described_class.new(url: 'http://jira.test.com/path/') }

    describe '#issues_url' do
      it 'handles trailing slashes' do
        expect(service.issues_url).to eq('http://jira.test.com/path/browse/:id')
      end
    end

    describe '#new_issue_url' do
      it 'handles trailing slashes' do
        expect(service.new_issue_url).to eq('http://jira.test.com/path/secure/CreateIssue.jspa')
      end
    end
  end
end
