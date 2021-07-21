# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Jira do
  include AssetsHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:current_user) { build_stubbed(:user) }
  let(:url) { 'http://jira.example.com' }
  let(:api_url) { 'http://api-jira.example.com' }
  let(:username) { 'jira-username' }
  let(:password) { 'jira-password' }
  let(:transition_id) { 'test27' }
  let(:server_info_results) { { 'deploymentType' => 'Cloud' } }
  let(:jira_integration) do
    described_class.new(
      project: project,
      url: url,
      username: username,
      password: password
    )
  end

  before do
    WebMock.stub_request(:get, /serverInfo/).to_return(body: server_info_results.to_json )
  end

  describe '#options' do
    let(:options) do
      {
        project: project,
        active: true,
        username: 'username',
        password: 'test',
        jira_issue_transition_id: 24,
        url: 'http://jira.test.com:1234/path/'
      }
    end

    let(:integration) { described_class.create!(options) }

    it 'sets the URL properly' do
      # jira-ruby gem parses the URI and handles trailing slashes fine:
      # https://github.com/sumoheavy/jira-ruby/blob/v1.7.0/lib/jira/http_client.rb#L62
      expect(integration.options[:site]).to eq('http://jira.test.com:1234')
    end

    it 'leaves out trailing slashes in context' do
      expect(integration.options[:context_path]).to eq('/path')
    end

    context 'URL without a path' do
      before do
        integration.url = 'http://jira.test.com/'
      end

      it 'leaves out trailing slashes in context' do
        expect(integration.options[:site]).to eq('http://jira.test.com')
        expect(integration.options[:context_path]).to eq('')
      end
    end

    context 'URL with query string parameters' do
      before do
        integration.url << '?nosso&foo=bar'
      end

      it 'removes query string parameters' do
        expect(integration.options[:site]).to eq('http://jira.test.com:1234')
        expect(integration.options[:context_path]).to eq('/path')
      end
    end

    context 'username with trailing whitespaces' do
      before do
        options.merge!(username: 'username ')
      end

      it 'leaves out trailing whitespaces in username' do
        expect(integration.options[:username]).to eq('username')
      end
    end

    it 'provides additional cookies to allow basic auth with oracle webgate' do
      expect(integration.options[:use_cookies]).to eq(true)
      expect(integration.options[:additional_cookies]).to eq(['OBBasicAuth=fromDialog'])
    end

    context 'using api URL' do
      before do
        options.merge!(api_url: 'http://jira.test.com/api_path/')
      end

      it 'leaves out trailing slashes in context' do
        expect(integration.options[:context_path]).to eq('/api_path')
      end
    end
  end

  describe '#fields' do
    let(:integration) { create(:jira_integration) }

    subject(:fields) { integration.fields }

    it 'returns custom fields' do
      expect(fields.pluck(:name)).to eq(%w[url api_url username password])
    end
  end

  describe '.reference_pattern' do
    using RSpec::Parameterized::TableSyntax

    where(:key, :result) do
      '#123'               | ''
      '1#23#12'            | ''
      'JIRA-1234A'         | 'JIRA-1234'
      'JIRA-1234-some_tag' | 'JIRA-1234'
      'JIRA-1234_some_tag' | 'JIRA-1234'
      'EXT_EXT-1234'       | 'EXT_EXT-1234'
      'EXT3_EXT-1234'      | 'EXT3_EXT-1234'
      '3EXT_EXT-1234'      | ''
    end

    with_them do
      specify do
        expect(described_class.reference_pattern.match(key).to_s).to eq(result)
      end
    end
  end

  describe '#create' do
    let(:params) do
      {
        project: project,
        url: url,
        api_url: api_url,
        username: username, password: password,
        jira_issue_transition_id: transition_id
      }
    end

    subject(:integration) { described_class.create!(params) }

    it 'does not store data into properties' do
      expect(integration.properties).to be_nil
    end

    it 'stores data in data_fields correctly' do
      expect(integration.jira_tracker_data.url).to eq(url)
      expect(integration.jira_tracker_data.api_url).to eq(api_url)
      expect(integration.jira_tracker_data.username).to eq(username)
      expect(integration.jira_tracker_data.password).to eq(password)
      expect(integration.jira_tracker_data.jira_issue_transition_id).to eq(transition_id)
      expect(integration.jira_tracker_data.deployment_cloud?).to be_truthy
    end

    context 'when loading serverInfo' do
      context 'with a Cloud instance' do
        let(:server_info_results) { { 'deploymentType' => 'Cloud' } }

        it 'is detected' do
          expect(integration.jira_tracker_data).to be_deployment_cloud
        end
      end

      context 'with a Server instance' do
        let(:server_info_results) { { 'deploymentType' => 'Server' } }

        it 'is detected' do
          expect(integration.jira_tracker_data).to be_deployment_server
        end
      end

      context 'from an Unknown instance' do
        let(:server_info_results) { { 'deploymentType' => 'FutureCloud' } }

        context 'and URL ends in .atlassian.net' do
          let(:api_url) { 'http://example-api.atlassian.net' }

          it 'deployment_type is set to cloud' do
            expect(integration.jira_tracker_data).to be_deployment_cloud
          end
        end

        context 'and URL is something else' do
          let(:api_url) { 'http://my-jira-api.someserver.com' }

          it 'deployment_type is set to server' do
            expect(integration.jira_tracker_data).to be_deployment_server
          end
        end
      end

      context 'and no ServerInfo response is received' do
        let(:server_info_results) { {} }

        context 'and URL ends in .atlassian.net' do
          let(:api_url) { 'http://example-api.atlassian.net' }

          it 'deployment_type is set to cloud' do
            expect(Gitlab::AppLogger).to receive(:warn).with(message: "Jira API returned no ServerInfo, setting deployment_type from URL", server_info: server_info_results, url: api_url)
            expect(integration.jira_tracker_data).to be_deployment_cloud
          end
        end

        context 'and URL is something else' do
          let(:api_url) { 'http://my-jira-api.someserver.com' }

          it 'deployment_type is set to server' do
            expect(Gitlab::AppLogger).to receive(:warn).with(message: "Jira API returned no ServerInfo, setting deployment_type from URL", server_info: server_info_results, url: api_url)
            expect(integration.jira_tracker_data).to be_deployment_server
          end
        end
      end
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
          expect(integration.url).to eq(url)
          expect(integration.api_url).to eq(api_url)
          expect(integration.username).to eq(username)
          expect(integration.password).to eq(password)
          expect(integration.jira_issue_transition_id).to eq(transition_id)
        end
      end

      describe '#update' do
        context 'basic update' do
          let_it_be(:new_username) { 'new_username' }
          let_it_be(:new_url) { 'http://jira-new.example.com' }

          before do
            integration.update!(username: new_username, url: new_url)
          end

          it 'stores updated data in jira_tracker_data table' do
            data = integration.jira_tracker_data.reload

            expect(data.url).to eq(new_url)
            expect(data.api_url).to eq(api_url)
            expect(data.username).to eq(new_username)
            expect(data.password).to eq(password)
            expect(data.jira_issue_transition_id).to eq(transition_id)
          end
        end

        context 'when updating the url, api_url, username, or password' do
          context 'when updating the integration' do
            it 'updates deployment type' do
              integration.update!(url: 'http://first.url')
              integration.jira_tracker_data.update!(deployment_type: 'server')

              expect(integration.jira_tracker_data.deployment_server?).to be_truthy

              integration.update!(api_url: 'http://another.url', password: password)
              integration.jira_tracker_data.reload

              expect(integration.jira_tracker_data.deployment_cloud?).to be_truthy
              expect(WebMock).to have_requested(:get, /serverInfo/).twice
            end
          end

          context 'when removing the integration' do
            let(:server_info_results) { {} }

            it 'updates deployment type' do
              integration.update!(url: nil, api_url: nil, active: false)

              integration.jira_tracker_data.reload

              expect(integration.jira_tracker_data.deployment_unknown?).to be_truthy
            end
          end

          it 'calls serverInfo for url' do
            integration.update!(url: 'http://first.url', password: password)

            expect(WebMock).to have_requested(:get, /serverInfo/)
          end

          it 'calls serverInfo for api_url' do
            integration.update!(api_url: 'http://another.url', password: password)

            expect(WebMock).to have_requested(:get, /serverInfo/)
          end

          it 'calls serverInfo for username' do
            integration.update!(username: 'test-user')

            expect(WebMock).to have_requested(:get, /serverInfo/)
          end

          it 'calls serverInfo for password' do
            integration.update!(password: 'test-password')

            expect(WebMock).to have_requested(:get, /serverInfo/)
          end
        end

        context 'when not updating the url, api_url, username, or password' do
          it 'does not update deployment type' do
            expect { integration.update!(jira_issue_transition_id: 'jira_issue_transition_id') }
              .to raise_error(ActiveRecord::RecordInvalid)

            expect(WebMock).not_to have_requested(:get, /serverInfo/)
          end
        end

        context 'when not allowed to test an instance or group' do
          it 'does not update deployment type' do
            allow(integration).to receive(:testable?).and_return(false)

            integration.update!(url: 'http://first.url')

            expect(WebMock).not_to have_requested(:get, /serverInfo/)
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
                integration
                integration.url = 'http://jira_edited.example.com'

                expect(integration).not_to be_valid
                expect(integration.url).to eq('http://jira_edited.example.com')
                expect(integration.password).to be_nil
              end

              it 'does not reset password if url "changed" to the same url as before' do
                integration.url = 'http://jira.example.com'

                expect(integration).to be_valid
                expect(integration.url).to eq('http://jira.example.com')
                expect(integration.password).not_to be_nil
              end

              it 'resets password if url not changed but api url added' do
                integration.api_url = 'http://jira_edited.example.com/rest/api/2'

                expect(integration).not_to be_valid
                expect(integration.api_url).to eq('http://jira_edited.example.com/rest/api/2')
                expect(integration.password).to be_nil
              end

              it 'does not reset password if new url is set together with password, even if it\'s the same password' do
                integration.url = 'http://jira_edited.example.com'
                integration.password = password

                expect(integration).to be_valid
                expect(integration.password).to eq(password)
                expect(integration.url).to eq('http://jira_edited.example.com')
              end

              it 'resets password if url changed, even if setter called multiple times' do
                integration.url = 'http://jira1.example.com/rest/api/2'
                integration.url = 'http://jira1.example.com/rest/api/2'

                expect(integration).not_to be_valid
                expect(integration.password).to be_nil
              end

              it 'does not reset password if username changed' do
                integration.username = 'some_name'

                expect(integration).to be_valid
                expect(integration.password).to eq(password)
              end

              it 'does not reset password if password changed' do
                integration.url = 'http://jira_edited.example.com'
                integration.password = 'new_password'

                expect(integration).to be_valid
                expect(integration.password).to eq('new_password')
              end

              it 'does not reset password if the password is touched and same as before' do
                integration.url = 'http://jira_edited.example.com'
                integration.password = password

                expect(integration).to be_valid
                expect(integration.password).to eq(password)
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
                integration.api_url = 'http://jira_edited.example.com/rest/api/2'

                expect(integration).not_to be_valid
                expect(integration.password).to be_nil
              end

              it 'does not reset password if url changed' do
                integration.url = 'http://jira_edited.example.com'

                expect(integration).to be_valid
                expect(integration.password).to eq(password)
              end

              it 'resets password if api url set to empty' do
                integration.api_url = ''

                expect(integration).not_to be_valid
                expect(integration.password).to be_nil
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
              integration.url = 'http://jira_edited.example.com/rest/api/2'
              integration.password = 'password'
              integration.save!

              expect(integration.reload).to have_attributes(
                url: 'http://jira_edited.example.com/rest/api/2',
                password: 'password'
              )
            end
          end
        end
      end
    end

    # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
    context 'when data are stored in properties' do
      let(:properties) { data_params }
      let!(:integration) do
        create(:jira_integration, :without_properties_callback, properties: properties.merge(additional: 'something'))
      end

      it_behaves_like 'handles jira fields'
    end

    context 'when data are stored in separated fields' do
      let(:integration) do
        create(:jira_integration, data_params.merge(properties: {}))
      end

      it_behaves_like 'handles jira fields'
    end

    context 'when data are stored in both properties and separated fields' do
      let(:properties) { data_params }
      let(:integration) do
        create(:jira_integration, :without_properties_callback, properties: properties).tap do |integration|
          create(:jira_tracker_data, data_params.merge(integration: integration))
        end
      end

      it_behaves_like 'handles jira fields'
    end
  end

  describe '#find_issue' do
    let(:issue_key) { 'JIRA-123' }
    let(:issue_url) { "#{url}/rest/api/2/issue/#{issue_key}" }

    before do
      stub_request(:get, issue_url).with(basic_auth: [username, password])
    end

    it 'call the Jira API to get the issue' do
      jira_integration.find_issue(issue_key)

      expect(WebMock).to have_requested(:get, issue_url)
    end

    context 'with options' do
      let(:issue_url) { "#{url}/rest/api/2/issue/#{issue_key}?expand=renderedFields,transitions" }

      it 'calls the Jira API with the options to get the issue' do
        jira_integration.find_issue(issue_key, rendered_fields: true, transitions: true)

        expect(WebMock).to have_requested(:get, issue_url)
      end
    end
  end

  describe '#close_issue' do
    let(:custom_base_url) { 'http://custom_url' }

    shared_examples 'close_issue' do
      let(:issue_key)       { 'JIRA-123' }
      let(:issue_url)       { "#{url}/rest/api/2/issue/#{issue_key}" }
      let(:transitions_url) { "#{issue_url}/transitions" }
      let(:comment_url)     { "#{issue_url}/comment" }
      let(:remote_link_url) { "#{issue_url}/remotelink" }
      let(:transitions)     { nil }

      let(:issue_fields) do
        {
          id: issue_key,
          self: issue_url,
          transitions: transitions
        }
      end

      subject(:close_issue) do
        jira_integration.close_issue(resource, ExternalIssue.new(issue_key, project))
      end

      before do
        jira_integration.jira_issue_transition_id = '999'

        # These stubs are needed to test Integrations::Jira#close_issue.
        # We close the issue then do another request to API to check if it got closed.
        # Here is stubbed the API return with a closed and an opened issues.
        open_issue   = JIRA::Resource::Issue.new(jira_integration.client, attrs: issue_fields.deep_stringify_keys)
        closed_issue = open_issue.dup
        allow(open_issue).to receive(:resolution).and_return(false)
        allow(closed_issue).to receive(:resolution).and_return(true)
        allow(JIRA::Resource::Issue).to receive(:find).and_return(open_issue, closed_issue)

        allow_any_instance_of(JIRA::Resource::Issue).to receive(:key).and_return(issue_key)
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return([])

        WebMock.stub_request(:get, issue_url).with(basic_auth: %w(jira-username jira-password))
        WebMock.stub_request(:post, transitions_url).with(basic_auth: %w(jira-username jira-password))
        WebMock.stub_request(:post, comment_url).with(basic_auth: %w(jira-username jira-password))
        WebMock.stub_request(:post, remote_link_url).with(basic_auth: %w(jira-username jira-password))
      end

      let(:external_issue) { ExternalIssue.new('JIRA-123', project) }

      def close_issue
        jira_integration.close_issue(resource, external_issue, current_user)
      end

      it 'calls Jira API' do
        close_issue

        expect(WebMock).to have_requested(:post, comment_url).with(
          body: /Issue solved with/
        ).once
      end

      it 'tracks usage' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with('i_ecosystem_jira_service_close_issue', values: current_user.id)

        close_issue
      end

      it 'does not fail if remote_link.all on issue returns nil' do
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return(nil)

        expect { close_issue }.not_to raise_error
      end

      # Check https://developer.atlassian.com/jiradev/jira-platform/guides/other/guide-jira-remote-issue-links/fields-in-remote-issue-links
      # for more information
      it 'creates Remote Link reference in Jira for comment' do
        close_issue

        favicon_path = "http://localhost/assets/#{find_asset('favicon.png').digest_path}"

        # Creates comment
        expect(WebMock).to have_requested(:post, comment_url)
        # Creates Remote Link in Jira issue fields
        expect(WebMock).to have_requested(:post, remote_link_url).with(
          body: hash_including(
            GlobalID: 'GitLab',
            relationship: 'mentioned on',
            object: {
              url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/commit/#{commit_id}",
              title: "Solved by commit #{commit_id}.",
              icon: { title: 'GitLab', url16x16: favicon_path },
              status: { resolved: true }
            }
          )
        ).once
      end

      context 'when "comment_on_event_enabled" is set to false' do
        it 'creates Remote Link reference but does not create comment' do
          allow(jira_integration).to receive_messages(comment_on_event_enabled: false)
          close_issue

          expect(WebMock).not_to have_requested(:post, comment_url)
          expect(WebMock).to have_requested(:post, remote_link_url)
        end
      end

      context 'when Remote Link already exists' do
        let(:remote_link) do
          double(
            'remote link',
            object: {
              url: "#{Gitlab.config.gitlab.url}/#{project.full_path}/-/commit/#{commit_id}"
            }.with_indifferent_access
          )
        end

        it 'does not create comment' do
          allow(JIRA::Resource::Remotelink).to receive(:all).and_return([remote_link])

          expect(remote_link).to receive(:save!)

          close_issue

          expect(WebMock).not_to have_requested(:post, comment_url)
        end
      end

      it 'does not send comment or remote links to issues already closed' do
        allow_any_instance_of(JIRA::Resource::Issue).to receive(:resolution).and_return(true)

        close_issue

        expect(WebMock).not_to have_requested(:post, comment_url)
        expect(WebMock).not_to have_requested(:post, remote_link_url)
      end

      it 'does not send comment or remote links to issues with unknown resolution' do
        allow_any_instance_of(JIRA::Resource::Issue).to receive(:respond_to?).with(:resolution).and_return(false)

        close_issue

        expect(WebMock).not_to have_requested(:post, comment_url)
        expect(WebMock).not_to have_requested(:post, remote_link_url)
      end

      it 'references the GitLab commit' do
        stub_config_setting(base_url: custom_base_url)

        close_issue

        expect(WebMock).to have_requested(:post, comment_url).with(
          body: %r{#{custom_base_url}/#{project.full_path}/-/commit/#{commit_id}}
        ).once
      end

      it 'references the GitLab commit' do
        stub_config_setting(relative_url_root: '/gitlab')
        stub_config_setting(url: Settings.send(:build_gitlab_url))

        allow(described_class).to receive(:default_url_options) do
          { script_name: '/gitlab' }
        end

        close_issue

        expect(WebMock).to have_requested(:post, comment_url).with(
          body: %r{#{Gitlab.config.gitlab.url}/#{project.full_path}/-/commit/#{commit_id}}
        ).once
      end

      it 'logs exception when transition id is not valid' do
        allow(jira_integration).to receive(:log_error)
        WebMock.stub_request(:post, transitions_url).with(basic_auth: %w(jira-username jira-password)).and_raise("Bad Request")

        close_issue

        expect(jira_integration).to have_received(:log_error).with(
          "Issue transition failed",
          error: hash_including(
            exception_class: 'StandardError',
            exception_message: "Bad Request"
          ),
          client_url: "http://jira.example.com"
        )
      end

      it 'calls the api with jira_issue_transition_id' do
        close_issue

        expect(WebMock).to have_requested(:post, transitions_url).with(
          body: /"id":"999"/
        ).once
      end

      context 'when custom transition IDs are blank' do
        before do
          jira_integration.jira_issue_transition_id = ''
        end

        it 'does not transition the issue' do
          close_issue

          expect(WebMock).not_to have_requested(:post, transitions_url)
        end
      end

      context 'when using automatic issue transitions' do
        let(:transitions) do
          [
            { id: '1' },
            { id: '2', to: { statusCategory: { key: 'new' } } },
            { id: '3', to: { statusCategory: { key: 'done' } } },
            { id: '4', to: { statusCategory: { key: 'done' } } }
          ]
        end

        before do
          jira_integration.jira_issue_transition_automatic = true

          close_issue
        end

        it 'uses the next transition with a status category of done' do
          expect(WebMock).to have_requested(:post, transitions_url).with(
            body: /"id":"3"/
          ).once
        end

        context 'when no done transition is available' do
          let(:transitions) do
            [
              { id: '1', to: { statusCategory: { key: 'new' } } }
            ]
          end

          it 'does not attempt to transition' do
            expect(WebMock).not_to have_requested(:post, transitions_url)
          end
        end

        context 'when no valid transitions are returned' do
          let(:transitions) { 'foo' }

          it 'does not attempt to transition' do
            expect(WebMock).not_to have_requested(:post, transitions_url)
          end
        end
      end

      context 'when using multiple transition ids' do
        before do
          allow(jira_integration).to receive_messages(jira_issue_transition_id: '1,2,3')
        end

        it 'calls the api with transition ids separated by comma' do
          close_issue

          1.upto(3) do |transition_id|
            expect(WebMock).to have_requested(:post, transitions_url).with(
              body: /"id":"#{transition_id}"/
            ).once
          end

          expect(WebMock).to have_requested(:post, comment_url)
        end

        it 'calls the api with transition ids separated by semicolon' do
          allow(jira_integration).to receive_messages(jira_issue_transition_id: '1;2;3')

          close_issue

          1.upto(3) do |transition_id|
            expect(WebMock).to have_requested(:post, transitions_url).with(
              body: /"id":"#{transition_id}"/
            ).once
          end

          expect(WebMock).to have_requested(:post, comment_url)
        end

        context 'when a transition fails' do
          before do
            WebMock.stub_request(:post, transitions_url).with(basic_auth: %w(jira-username jira-password)).to_return do |request|
              { status: request.body.include?('"id":"2"') ? 500 : 200 }
            end
          end

          it 'stops the sequence' do
            close_issue

            1.upto(2) do |transition_id|
              expect(WebMock).to have_requested(:post, transitions_url).with(
                body: /"id":"#{transition_id}"/
              )
            end

            expect(WebMock).not_to have_requested(:post, transitions_url).with(
              body: /"id":"3"/
            )

            expect(WebMock).not_to have_requested(:post, comment_url)
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

  describe '#create_cross_reference_note' do
    let_it_be(:user) { build_stubbed(:user) }

    let(:jira_issue) { ExternalIssue.new('JIRA-123', project) }

    subject { jira_integration.create_cross_reference_note(jira_issue, resource, user) }

    shared_examples 'creates a comment on Jira' do
      let(:issue_url) { "#{url}/rest/api/2/issue/JIRA-123" }
      let(:comment_url) { "#{issue_url}/comment" }
      let(:remote_link_url) { "#{issue_url}/remotelink" }

      before do
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return([])
        stub_request(:get, issue_url).with(basic_auth: [username, password])
        stub_request(:post, comment_url).with(basic_auth: [username, password])
        stub_request(:post, remote_link_url).with(basic_auth: [username, password])
      end

      it 'creates a comment on Jira' do
        subject

        expect(WebMock).to have_requested(:post, comment_url).with(
          body: /mentioned this issue in/
        ).once
      end

      it 'tracks usage' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with('i_ecosystem_jira_service_cross_reference', values: user.id)

        subject
      end
    end

    context 'when resource is a commit' do
      let(:resource) { project.commit('master') }

      context 'when disabled' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:commit_events) { false }
          end
        end

        it { is_expected.to eq('Events for commits are disabled.') }
      end

      context 'when enabled' do
        it_behaves_like 'creates a comment on Jira'
      end
    end

    context 'when resource is a merge request' do
      let(:resource) { build_stubbed(:merge_request, source_project: project) }

      context 'when disabled' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:merge_requests_events) { false }
          end
        end

        it { is_expected.to eq('Events for merge requests are disabled.') }
      end

      context 'when enabled' do
        it_behaves_like 'creates a comment on Jira'
      end
    end
  end

  describe '#test' do
    let(:server_info_results) { { 'url' => 'http://url', 'deploymentType' => 'Cloud' } }

    def server_info
      jira_integration.test(nil)
    end

    context 'when the test succeeds' do
      it 'gets Jira project with URL when API URL not set' do
        expect(server_info).to eq(success: true, result: server_info_results)
        expect(WebMock).to have_requested(:get, /jira.example.com/)
      end

      it 'gets Jira project with API URL if set' do
        jira_integration.update!(api_url: 'http://jira.api.com')

        expect(server_info).to eq(success: true, result: server_info_results)
        expect(WebMock).to have_requested(:get, /jira.api.com/)
      end
    end

    context 'when the test fails' do
      it 'returns result with the error' do
        test_url = 'http://jira.example.com/rest/api/2/serverInfo'
        error_message = 'Some specific failure.'

        WebMock.stub_request(:get, test_url).with(basic_auth: [username, password])
          .to_raise(JIRA::HTTPError.new(double(message: error_message)))

        expect(jira_integration).to receive(:log_error).with(
          'Error sending message',
          client_url: 'http://jira.example.com',
          error: error_message
        )

        expect(jira_integration.test(nil)).to eq(success: false, result: error_message)
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

        integration = project.create_jira_integration(active: true)

        expect(integration.url).to eq('http://jira.sample/projects/project_a')
        expect(integration.api_url).to eq('http://jira.sample/api')
      end
    end

    it 'removes trailing slashes from url' do
      integration = described_class.new(url: 'http://jira.test.com/path/')

      expect(integration.url).to eq('http://jira.test.com/path')
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
    let(:integration) { described_class.new(url: 'http://jira.test.com/path/') }

    describe '#web_url' do
      it 'handles paths, slashes, and query string' do
        expect(integration.web_url).to eq(integration.url)
        expect(integration.web_url('subpath/')).to eq('http://jira.test.com/path/subpath')
        expect(integration.web_url('/subpath/')).to eq('http://jira.test.com/path/subpath')
        expect(integration.web_url('subpath', foo: :bar)).to eq('http://jira.test.com/path/subpath?foo=bar')
      end

      it 'preserves existing query string' do
        integration.url = 'http://jira.test.com/path/?nosso&foo=bar%20bar'

        expect(integration.web_url).to eq("http://jira.test.com/path?foo=bar%20bar&nosso")
        expect(integration.web_url('subpath/')).to eq('http://jira.test.com/path/subpath?foo=bar%20bar&nosso')
        expect(integration.web_url('/subpath/')).to eq('http://jira.test.com/path/subpath?foo=bar%20bar&nosso')
        expect(integration.web_url('subpath', bar: 'baz baz')).to eq('http://jira.test.com/path/subpath?bar=baz%20baz&foo=bar%20bar&nosso')
      end

      it 'returns an empty string if URL is not set' do
        integration.url = nil

        expect(integration.web_url).to eq('')
      end

      it 'includes Atlassian referrer for gitlab.com' do
        allow(Gitlab).to receive(:com?).and_return(true)

        expect(integration.web_url).to eq("http://jira.test.com/path?#{described_class::ATLASSIAN_REFERRER_GITLAB_COM.to_query}")

        allow(Gitlab).to receive(:staging?).and_return(true)

        expect(integration.web_url).to eq(integration.url)
      end

      it 'includes Atlassian referrer for self-managed' do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

        expect(integration.web_url).to eq("http://jira.test.com/path?#{described_class::ATLASSIAN_REFERRER_SELF_MANAGED.to_query}")
      end
    end

    describe '#project_url' do
      it 'returns the correct URL' do
        expect(integration.project_url).to eq('http://jira.test.com/path')
      end

      it 'returns an empty string if URL is not set' do
        integration.url = nil

        expect(integration.project_url).to eq('')
      end
    end

    describe '#issues_url' do
      it 'returns the correct URL' do
        expect(integration.issues_url).to eq('http://jira.test.com/path/browse/:id')
      end

      it 'returns an empty string if URL is not set' do
        integration.url = nil

        expect(integration.issues_url).to eq('')
      end
    end

    describe '#new_issue_url' do
      it 'returns the correct URL' do
        expect(integration.new_issue_url).to eq('http://jira.test.com/path/secure/CreateIssue!default.jspa')
      end

      it 'returns an empty string if URL is not set' do
        integration.url = nil

        expect(integration.new_issue_url).to eq('')
      end
    end
  end

  describe '#issue_transition_enabled?' do
    it 'returns true if automatic transitions are enabled' do
      jira_integration.jira_issue_transition_automatic = true

      expect(jira_integration.issue_transition_enabled?).to be(true)
    end

    it 'returns true if custom transitions are set' do
      jira_integration.jira_issue_transition_id = '1, 2, 3'

      expect(jira_integration.issue_transition_enabled?).to be(true)
    end

    it 'returns false if automatic and custom transitions are disabled' do
      expect(jira_integration.issue_transition_enabled?).to be(false)
    end
  end

  describe 'valid_connection? and configured?' do
    before do
      allow(jira_integration).to receive(:test).with(nil).and_return(test_result)
    end

    context 'when the test fails' do
      let(:test_result) { { success: false } }

      it 'is falsey' do
        expect(jira_integration).not_to be_valid_connection
      end

      it 'implies that configured? is also falsey' do
        expect(jira_integration).not_to be_configured
      end
    end

    context 'when the test succeeds' do
      let(:test_result) { { success: true } }

      it 'is truthy' do
        expect(jira_integration).to be_valid_connection
      end

      context 'when the integration is active' do
        before do
          jira_integration.active = true
        end

        it 'implies that configured? is also truthy' do
          expect(jira_integration).to be_configured
        end
      end

      context 'when the integration is inactive' do
        before do
          jira_integration.active = false
        end

        it 'implies that configured? is falsey' do
          expect(jira_integration).not_to be_configured
        end
      end
    end
  end
end
