# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Jira, feature_category: :integrations do
  include AssetsHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:current_user) { build_stubbed(:user) }
  let(:url) { 'http://jira.example.com' }
  let(:api_url) { 'http://api-jira.example.com' }
  let(:username) { 'jira-username' }
  let(:jira_auth_type) { 0 }
  let(:jira_issue_prefix) { '' }
  let(:jira_issue_regex) { '' }
  let(:password) { 'jira-password' }
  let(:project_key) { 'TEST' }
  let(:project_keys) { %w[TEST1 TEST2] }
  let(:transition_id) { 'test27' }
  let(:server_info_results) { { 'deploymentType' => 'Cloud' } }
  let(:client_info_results) { { 'accountType' => 'atlassian' } }
  let(:jira_integration) do
    described_class.new(
      project: project,
      url: url,
      username: username,
      password: password,
      project_key: project_key,
      project_keys: project_keys
    )
  end

  before do
    WebMock.stub_request(:get, /serverInfo/).to_return(body: server_info_results.to_json)
    WebMock.stub_request(:get, /myself/).to_return(body: client_info_results.to_json)
  end

  it_behaves_like Integrations::HasAvatar

  it_behaves_like Integrations::ResetSecretFields do
    let(:integration) { jira_integration }
  end

  describe 'validations' do
    subject { jira_integration }

    context 'when integration is active' do
      before do
        jira_integration.active = true

        # Don't auto-fill URLs from gitlab.yml
        stub_config(issues_tracker: {})
      end

      it { is_expected.to be_valid }
      it { is_expected.to validate_presence_of(:url) }
      it { is_expected.to validate_presence_of(:username) }
      it { is_expected.to validate_presence_of(:password) }
      it { is_expected.to validate_presence_of(:jira_auth_type) }
      it { is_expected.to validate_length_of(:jira_issue_regex).is_at_most(255) }
      it { is_expected.to validate_length_of(:jira_issue_prefix).is_at_most(255) }
      it { is_expected.to validate_inclusion_of(:jira_auth_type).in_array([0, 1]) }

      it_behaves_like 'issue tracker integration URL attribute', :url
      it_behaves_like 'issue tracker integration URL attribute', :api_url

      context 'with personal_access_token_authorization' do
        before do
          jira_integration.jira_auth_type = 1
        end

        it { is_expected.not_to validate_presence_of(:username) }
      end

      context 'when URL is for Jira Cloud' do
        before do
          jira_integration.url = 'https://test.atlassian.net'
        end

        it 'is valid when jira_auth_type is basic' do
          jira_integration.jira_auth_type = 0

          expect(jira_integration).to be_valid
        end

        it 'is invalid when jira_auth_type is PAT' do
          jira_integration.jira_auth_type = 1

          expect(jira_integration).not_to be_valid
        end
      end
    end

    context 'when integration is inactive' do
      before do
        jira_integration.active = false
      end

      it { is_expected.to be_valid }
      it { is_expected.not_to validate_presence_of(:url) }
      it { is_expected.not_to validate_presence_of(:username) }
      it { is_expected.not_to validate_presence_of(:password) }
      it { is_expected.not_to validate_presence_of(:jira_auth_type) }
      it { is_expected.not_to validate_length_of(:jira_issue_regex).is_at_most(255) }
      it { is_expected.not_to validate_length_of(:jira_issue_prefix).is_at_most(255) }
      it { is_expected.not_to validate_inclusion_of(:jira_auth_type).in_array([0, 1]) }
    end

    describe 'jira_issue_transition_id' do
      it 'accepts a blank value' do
        jira_integration.jira_issue_transition_id = ' '

        expect(jira_integration).to be_valid
      end

      it 'accepts any string containing numbers' do
        jira_integration.jira_issue_transition_id = 'foo 23 bar'

        expect(jira_integration).to be_valid
      end

      it 'does not accept a string without numbers' do
        jira_integration.jira_issue_transition_id = 'foo bar'

        expect(jira_integration).not_to be_valid
        expect(jira_integration.errors.full_messages).to eq(
          [
            'Jira issue transition IDs must be a list of numbers that can be split with , or ;'
          ])
      end
    end
  end

  describe 'callbacks' do
    context 'before_save' do
      context "when project_keys are changed" do
        let(:project_keys) { [' GTL  ', 'JR ', '  GTL', ''] }

        it "formats and removes duplicates from project_keys" do
          jira_integration.save!
          expect(jira_integration.project_keys).to contain_exactly('GTL', 'JR')
        end
      end
    end
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
    let(:integration) { jira_integration }

    subject(:fields) { integration.fields }

    it 'returns custom fields' do
      expect(fields.pluck(:name)).to eq(%w[url api_url jira_auth_type username password jira_issue_regex jira_issue_prefix jira_issue_transition_id issues_enabled project_keys])
    end
  end

  describe '#sections' do
    let(:integration) { jira_integration }

    subject(:sections) { integration.sections.map { |s| s[:type] } }

    context 'when project_level? is true' do
      before do
        allow(integration).to receive(:project_level?).and_return(true)
      end

      it 'includes SECTION_TYPE_JIRA_ISSUES' do
        expect(sections).to include(described_class::SECTION_TYPE_JIRA_ISSUES)
      end

      it 'section SECTION_TYPE_JIRA_ISSUES has `plan` attribute' do
        jira_issues_section = integration.sections.find { |s| s[:type] == described_class::SECTION_TYPE_JIRA_ISSUES }
        expect(jira_issues_section[:plan]).to eq('premium')
      end
    end

    context 'when instance_level? is false' do
      before do
        allow(integration).to receive(:instance_level?).and_return(false)
      end

      it 'includes SECTION_TYPE_JIRA_ISSUES' do
        expect(sections).to include(described_class::SECTION_TYPE_JIRA_ISSUES)
      end

      it 'includes SECTION_TYPE_JIRA_ISSUE_CREATION' do
        expect(sections).to include(described_class::SECTION_TYPE_JIRA_ISSUE_CREATION)
      end
    end

    context 'when instance_level? is true' do
      before do
        allow(integration).to receive(:instance_level?).and_return(true)
      end

      it 'does not include SECTION_TYPE_JIRA_ISSUES' do
        expect(sections).not_to include(described_class::SECTION_TYPE_JIRA_ISSUES)
      end

      it 'does not include SECTION_TYPE_JIRA_ISSUE_CREATION' do
        expect(sections).not_to include(described_class::SECTION_TYPE_JIRA_ISSUE_CREATION)
      end
    end
  end

  describe '#reference_pattern' do
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
      'CVE-2022-123'       | 'CVE-2022'
      'CVE-123'            | 'CVE-123'
      'abc-JIRA-1234'      | 'JIRA-1234'
    end

    with_them do
      specify do
        expect(jira_integration.reference_pattern.match(key).to_s).to eq(result)
      end
    end

    context 'with match prefix' do
      before do
        jira_integration.jira_issue_prefix = 'jira#'
      end

      where(:key, :result, :issue_key) do
        'jira##123'                  | ''               | ''
        'jira#1#23#12'               | ''               | ''
        'jira#JIRA-1234A'            | 'jira#JIRA-1234' | 'JIRA-1234'
        'jira#JIRA-1234-some_tag'    | 'jira#JIRA-1234' | 'JIRA-1234'
        'JIRA-1234A'                 | ''               | ''
        'JIRA-1234-some_tag'         | ''               | ''
        'myjira#JIRA-1234-some_tag'  | ''               | ''
        'MYjira#JIRA-1234-some_tag'  | ''               | ''
        'my-jira#JIRA-1234-some_tag' | 'jira#JIRA-1234' | 'JIRA-1234'
      end

      with_them do
        specify do
          expect(jira_integration.reference_pattern.match(key).to_s).to eq(result)

          expect(jira_integration.reference_pattern.match(key)[:issue]).to eq(issue_key) unless result.empty?
        end
      end
    end

    context 'with trailing space in jira_issue_prefix' do
      before do
        jira_integration.jira_issue_prefix = 'Jira# '
      end

      it 'leaves the trailing space' do
        expect(jira_integration.jira_issue_prefix).to eq('Jira# ')
      end

      it 'pulls the issue ID without a prefix' do
        expect(jira_integration.reference_pattern.match('Jira# FOO-123')[:issue]).to eq('FOO-123')
      end
    end

    context 'with custom issue pattern' do
      before do
        jira_integration.jira_issue_regex = '[A-Z][0-9]-[0-9]+'
      end

      where(:key, :result) do
        'J1-123'                | 'J1-123'
        'AAbJ J1-123'           | 'J1-123'
        '#A1-123'               | 'A1-123'
        'J1-1234-some_tag'      | 'J1-1234'
        'J1-1234A'              | 'J1-1234'
        'J1-1234-some_tag'      | 'J1-1234'
        'JI1-123'               | ''
        'J1I-123'               | ''
        'JI-123'                | ''
        '#123'                  | ''
      end

      with_them do
        specify do
          expect(jira_integration.reference_pattern.match(key).to_s).to eq(result)
        end
      end
    end

    context 'with long running regex' do
      let(:key) { "JIRAaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1\nanother line\n" }

      before do
        jira_integration.jira_issue_regex = '((a|b)+|c)+$'
      end

      it 'handles long inputs' do
        expect(jira_integration.reference_pattern.match(key).to_s).to eq('')
      end
    end
  end

  describe '.valid_jira_cloud_url?' do
    using RSpec::Parameterized::TableSyntax

    where(:url, :result) do
      'https://abc.atlassian.net' | true
      'http://abc.atlassian.net'  | false
      'abc.atlassian.net'         | false # This is how it behaves currently, but we may need to consider adding scheme if missing
      'https://somethingelse.com' | false
      'javascript://test.atlassian.net/%250dalert(document.domain)' | false
      'https://example.com".atlassian.net' | false
      nil | false
    end

    with_them do
      specify do
        expect(described_class.valid_jira_cloud_url?(url)).to eq(result)
      end
    end
  end

  describe '#create' do
    let(:params) do
      {
        project: project,
        url: url,
        api_url: api_url,
        jira_auth_type: jira_auth_type,
        username: username, password: password,
        jira_issue_regex: jira_issue_regex,
        jira_issue_prefix: jira_issue_prefix,
        jira_issue_transition_id: transition_id,
        project_key: project_key,
        project_keys: project_keys
      }
    end

    subject(:integration) { described_class.create!(params) }

    it 'does not store data into properties' do
      expect(integration.properties).to be_empty
    end

    it 'stores data in data_fields correctly' do
      expect(integration.jira_tracker_data.url).to eq(url)
      expect(integration.jira_tracker_data.api_url).to eq(api_url)
      expect(integration.jira_tracker_data.jira_auth_type).to eq(jira_auth_type)
      expect(integration.jira_tracker_data.username).to eq(username)
      expect(integration.jira_tracker_data.password).to eq(password)
      expect(integration.jira_tracker_data.jira_issue_regex).to eq(jira_issue_regex)
      expect(integration.jira_tracker_data.jira_issue_prefix).to eq(jira_issue_prefix)
      expect(integration.jira_tracker_data.jira_issue_transition_id).to eq(transition_id)
      expect(integration.jira_tracker_data.deployment_cloud?).to be_truthy
      expect(integration.jira_tracker_data.project_key).to eq(project_key)
      expect(integration.jira_tracker_data.project_keys).to eq(project_keys)
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
          let(:api_url) { 'https://example-api.atlassian.net' }

          it 'deployment_type is set to cloud' do
            expect(integration.jira_tracker_data).to be_deployment_cloud
          end
        end

        context 'and URL is something else' do
          let(:api_url) { 'https://my-jira-api.someserver.com' }

          it 'deployment_type is set to server' do
            expect(integration.jira_tracker_data).to be_deployment_server
          end
        end
      end

      context 'and no ServerInfo response is received' do
        let(:server_info_results) { {} }

        context 'and URL ends in .atlassian.net' do
          let(:api_url) { 'https://example-api.atlassian.net' }

          it 'deployment_type is set to cloud' do
            expect(Gitlab::AppLogger).to receive(:warn).with(message: "Jira API returned no ServerInfo, setting deployment_type from URL", server_info: server_info_results, url: api_url)
            expect(integration.jira_tracker_data).to be_deployment_cloud
          end
        end

        context 'and URL is something else' do
          let(:api_url) { 'https://my-jira-api.someserver.com' }

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
    shared_examples 'handles jira fields' do
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
            integration.update!(username: new_username, url: new_url, password: password)
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
              integration.update!(url: 'http://first.url', password: password)
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
      end
    end

    # this  will be removed as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
    context 'with properties' do
      let(:data_params) do
        {
          url: url, api_url: api_url,
          username: username, password: password,
          jira_issue_transition_id: transition_id
        }
      end

      context 'when data are stored in properties' do
        let(:integration) do
          create(:jira_integration, :without_properties_callback, project: project, properties: data_params.merge(additional: 'something'))
        end

        it_behaves_like 'handles jira fields'
      end

      context 'when data are stored in separated fields' do
        let(:integration) do
          create(:jira_integration, data_params.merge(properties: {}, project: project))
        end

        it_behaves_like 'handles jira fields'
      end

      context 'when data are stored in both properties and separated fields' do
        let(:integration) do
          create(:jira_integration, :without_properties_callback, properties: data_params, project: project).tap do |integration|
            create(:jira_tracker_data, data_params.merge(integration: integration))
          end
        end

        it_behaves_like 'handles jira fields'
      end
    end
  end

  describe '#client' do
    before do
      stub_request(:get, 'http://jira.example.com/foo')
    end

    it 'uses the default GitLab::HTTP timeouts' do
      timeouts = Gitlab::HTTP::DEFAULT_TIMEOUT_OPTIONS

      expect(Gitlab::HTTP_V2::Client).to receive(:httparty_perform_request)
        .with(Net::HTTP::Get, '/foo', hash_including(timeouts)).and_call_original

      jira_integration.client.get('/foo')
    end

    context 'when a custom read_timeout option is passed as an argument' do
      it 'uses the default GitLab::HTTP timeouts plus a custom read_timeout' do
        expected_timeouts = Gitlab::HTTP::DEFAULT_TIMEOUT_OPTIONS.merge(read_timeout: 2.minutes, timeout: 2.minutes)

        expect(Gitlab::HTTP_V2::Client).to receive(:httparty_perform_request)
          .with(Net::HTTP::Get, '/foo', hash_including(expected_timeouts)).and_call_original

        jira_integration.client(read_timeout: 2.minutes).get('/foo')
      end
    end

    context 'with basic auth' do
      before do
        jira_integration.jira_auth_type = 0
      end

      it 'uses correct authorization options' do
        expect_next_instance_of(JIRA::Client) do |instance|
          expect(instance.request_client.options).to include(
            additional_cookies: ['OBBasicAuth=fromDialog'],
            auth_type: :basic,
            use_cookies: true,
            password: jira_integration.password,
            username: jira_integration.username
          )
        end

        jira_integration.client.get('/foo')
      end
    end

    context 'with personal access token auth' do
      before do
        jira_integration.jira_auth_type = 1
      end

      it 'uses correct authorization options' do
        expect_next_instance_of(JIRA::Client) do |instance|
          expect(instance.request_client.options).to include(
            default_headers: { "Authorization" => "Bearer #{password}" }
          )
        end

        jira_integration.client.get('/foo')
      end
    end
  end

  describe '#find_issue' do
    let(:issue_key) { 'JIRA-123' }
    let(:issue_url) { "#{url}/rest/api/2/issue/#{issue_key}" }

    before do
      stub_request(:get, issue_url).with(basic_auth: [username, password])
    end

    it 'calls the Jira API to get the issue' do
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

    context 'with restricted restrict_project_key option' do
      subject(:find_issue) { jira_integration.find_issue(issue_key, restrict_project_key: true) }

      it { is_expected.to eq(nil) }

      context 'when project_keys includes issue_key' do
        let(:project_keys) { ['JIRA'] }

        it 'calls the Jira API to get the issue' do
          find_issue

          expect(WebMock).to have_requested(:get, issue_url)
        end
      end

      context 'when project_keys are empty' do
        let(:project_keys) { [] }

        it 'calls the Jira API to get the issue' do
          find_issue

          expect(WebMock).to have_requested(:get, issue_url)
        end
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

        WebMock.stub_request(:get, issue_url).with(basic_auth: %w[jira-username jira-password])
        WebMock.stub_request(:post, transitions_url).with(basic_auth: %w[jira-username jira-password])
        WebMock.stub_request(:post, comment_url).with(basic_auth: %w[jira-username jira-password])
        WebMock.stub_request(:post, remote_link_url).with(basic_auth: %w[jira-username jira-password])
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

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject { close_issue }

        let(:category) { 'Integrations::Jira' }
        let(:action) { 'perform_integrations_action' }
        let(:namespace) { project.namespace }
        let(:user) { current_user }
        let(:label) { 'redis_hll_counters.ecosystem.ecosystem_total_unique_counts_monthly' }
        let(:property) { 'i_ecosystem_jira_service_close_issue' }
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
        allow(jira_integration).to receive(:log_exception)
        WebMock.stub_request(:post, transitions_url).with(basic_auth: %w[jira-username jira-password]).and_raise("Bad Request")

        close_issue

        expect(jira_integration).to have_received(:log_exception).with(
          kind_of(StandardError),
          message: 'Issue transition failed',
          client_path: '/rest/api/2/issue/JIRA-123/transitions',
          client_status: '400',
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
            WebMock.stub_request(:post, transitions_url).with(basic_auth: %w[jira-username jira-password]).to_return do |request|
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
      let_it_be(:resource) { create(:merge_request, source_project: project) }
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
    let(:success_message) { 'SUCCESS: Successfully posted to http://jira.example.com.' }
    let(:favicon_path) { "http://localhost/assets/#{find_asset('favicon.png').digest_path}" }

    subject { jira_integration.create_cross_reference_note(jira_issue, resource, user) }

    shared_examples 'handles cross-references' do
      let(:resource_name) { jira_integration.send(:mentionable_name, resource) }
      let(:resource_url) { jira_integration.send(:build_entity_url, resource_name, resource.to_param) }
      let(:resource_human_name) { resource.model_name.human }
      let(:plural_resource_human_name) { resource_name.pluralize.humanize(capitalize: false) }
      let(:issue_url) { "#{url}/rest/api/2/issue/JIRA-123" }
      let(:comment_url) { "#{issue_url}/comment" }
      let(:remote_link_url) { "#{issue_url}/remotelink" }

      before do
        allow(JIRA::Resource::Remotelink).to receive(:all).and_return([])
        stub_request(:get, issue_url).with(basic_auth: [username, password])
        stub_request(:post, comment_url).with(basic_auth: [username, password])
        stub_request(:post, remote_link_url).with(basic_auth: [username, password])
      end

      context 'when enabled' do
        before do
          allow(jira_integration).to receive(:can_cross_reference?) { true }
        end

        it 'creates a comment and remote link' do
          expect(subject).to eq(success_message)
          expect(WebMock).to have_requested(:post, comment_url).with(body: comment_body).once
          expect(WebMock).to have_requested(:post, remote_link_url).with(
            body: hash_including(
              GlobalID: 'GitLab',
              relationship: 'mentioned on',
              object: {
                url: resource_url,
                title: "#{resource_human_name} - #{resource.title}",
                icon: { title: 'GitLab', url16x16: favicon_path },
                status: { resolved: false }
              }
            )
          ).once
        end

        context 'when comment already exists' do
          before do
            allow(jira_integration).to receive(:comment_exists?) { true }
          end

          it 'does not create a comment or remote link' do
            expect(subject).to be_nil
            expect(WebMock).not_to have_requested(:post, comment_url)
            expect(WebMock).not_to have_requested(:post, remote_link_url)
          end
        end

        context 'when remote link already exists' do
          let(:link) { double(object: { 'url' => resource_url }) }

          before do
            allow(jira_integration).to receive(:find_remote_link).and_return(link)
          end

          it 'updates the remote link but does not create a comment' do
            expect(link).to receive(:save!)
            expect(subject).to eq(success_message)
            expect(WebMock).not_to have_requested(:post, comment_url)
          end
        end
      end

      context 'when disabled' do
        before do
          allow(jira_integration).to receive(:can_cross_reference?) { false }
        end

        it 'does not create a comment or remote link' do
          expect(subject).to eq("Events for #{plural_resource_human_name} are disabled.")
          expect(WebMock).not_to have_requested(:post, comment_url)
          expect(WebMock).not_to have_requested(:post, remote_link_url)
        end
      end

      it 'tracks usage' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with('i_ecosystem_jira_service_cross_reference', values: user.id)

        subject
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:category) { 'Integrations::Jira' }
        let(:action) { 'perform_integrations_action' }
        let(:namespace) { project.namespace }
        let(:user) { current_user }
        let(:label) { 'redis_hll_counters.ecosystem.ecosystem_total_unique_counts_monthly' }
        let(:property) { 'i_ecosystem_jira_service_cross_reference' }
      end
    end

    context 'for commits' do
      it_behaves_like 'handles cross-references' do
        let(:resource) { project.commit('master') }
        let(:comment_body) { /mentioned this issue in \[a commit\|.* on branch \[master\|/ }
      end
    end

    context 'for issues' do
      it_behaves_like 'handles cross-references' do
        let(:resource) { build_stubbed(:issue, project: project) }
        let(:comment_body) { /mentioned this issue in \[a issue\|/ }
      end
    end

    context 'for merge requests' do
      it_behaves_like 'handles cross-references' do
        let(:resource) { build_stubbed(:merge_request, source_project: project) }
        let(:comment_body) { /mentioned this issue in \[a merge request\|.* on branch \[master\|/ }
      end
    end

    context 'for notes' do
      it_behaves_like 'handles cross-references' do
        let(:resource) { build_stubbed(:note, project: project) }
        let(:comment_body) { /mentioned this issue in \[a note\|/ }
      end
    end

    context 'for snippets' do
      it_behaves_like 'handles cross-references' do
        let(:resource) { build_stubbed(:project_snippet, project: project) }
        let(:resource_human_name) { 'Snippet' }
        let(:plural_resource_human_name) { 'project snippets' }
        let(:comment_body) { /mentioned this issue in \[a snippet\|/ }
      end
    end
  end

  describe '#test' do
    let(:test_results) { { 'accountType' => 'atlassian', "deploymentType" => "Cloud" } }

    def test_info
      jira_integration.test(nil)
    end

    context 'when the test succeeds' do
      it 'gets Jira project with URL when API URL not set' do
        expect(test_info).to eq(success: true, result: test_results)
        expect(WebMock).to have_requested(:get, /jira.example.com/).times(2)
      end

      it 'gets Jira project with API URL if set' do
        jira_integration.update!(api_url: 'http://jira.api.com')

        expect(test_info).to eq(success: true, result: test_results)
        expect(WebMock).to have_requested(:get, /jira.api.com/).times(2)
      end
    end

    context 'when the test fails' do
      it 'returns result with the error' do
        test_url = 'http://jira.example.com/rest/api/2/serverInfo'
        error_message = 'Some specific failure.'

        WebMock.stub_request(:get, test_url).with(basic_auth: [username, password])
          .to_raise(JIRA::HTTPError.new(double(message: error_message, code: '403')))

        expect(jira_integration).to receive(:log_exception).with(
          kind_of(JIRA::HTTPError),
          message: 'Error sending message',
          client_url: 'http://jira.example.com',
          client_path: '/rest/api/2/serverInfo',
          client_status: '403'
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
      integration = described_class.new(url: 'http://jira.test.com/path/', project: project)

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
    let(:integration) { described_class.new(url: 'http://jira.test.com/path/', project: project) }

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

      it 'includes Atlassian referrer for SaaS', :saas do
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

  describe '#project_keys_as_string' do
    it 'returns comma separated project_keys' do
      expect(jira_integration.project_keys_as_string).to eq 'TEST1,TEST2'
    end
  end
end
