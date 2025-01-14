# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::SentryClient::Issue, feature_category: :observability do
  include SentryClientHelpers

  let(:token) { 'test-token' }
  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0' }
  let(:client) { ErrorTracking::SentryClient.new(sentry_url, token) }
  let(:issue_id) { 11 }

  describe '#list_issues' do
    shared_examples 'issues have correct return type' do |klass|
      it "returns objects of type #{klass}" do
        expect(subject[:issues]).to all(be_a(klass))
      end
    end

    shared_examples 'issues have correct length' do |length|
      it { expect(subject[:issues].length).to eq(length) }
    end

    let(:issues_sample_response) do
      Gitlab::Utils.deep_indifferent_access(
        Gitlab::Json.parse(fixture_file('sentry/issues_sample_response.json'))
      )
    end

    let(:default_httparty_options) do
      {
        follow_redirects: false,
        headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer test-token" }
      }
    end

    let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
    let(:issue_status) { 'unresolved' }
    let(:limit) { 20 }
    let(:search_term) { '' }
    let(:cursor) { nil }
    let(:sort) { 'last_seen' }
    let(:sentry_api_response) { issues_sample_response }
    let(:sentry_request_url) { "#{sentry_url}/issues/?limit=20&query=is:unresolved" }
    let!(:sentry_api_request) { stub_sentry_request(sentry_request_url, body: sentry_api_response) }

    subject do
      client.list_issues(
        issue_status: issue_status,
        limit: limit,
        search_term: search_term,
        sort: sort,
        cursor: cursor
      )
    end

    it_behaves_like 'calls sentry api'

    it_behaves_like 'issues have correct return type', Gitlab::ErrorTracking::Error
    it_behaves_like 'issues have correct length', 3
    it_behaves_like 'maps Sentry exceptions'
    it_behaves_like 'Sentry API response size limit'

    shared_examples 'has correct external_url' do
      describe '#external_url' do
        it 'is constructed correctly' do
          expect(subject[:issues][0].external_url).to eq('https://sentrytest.gitlab.com/sentry-org/sentry-project/issues/11')
        end
      end
    end

    context 'when response has a pagination info' do
      let(:headers) do
        {
          link: '<https://sentrytest.gitlab.com>; rel="previous"; results="true"; cursor="1573556671000:0:1",' \
                '<https://sentrytest.gitlab.com>; rel="next"; results="true"; cursor="1572959139000:0:0"'
        }
      end

      let!(:sentry_api_request) { stub_sentry_request(sentry_request_url, body: sentry_api_response, headers: headers) }

      it 'parses the pagination' do
        expect(subject[:pagination]).to eq(
          'previous' => { 'cursor' => '1573556671000:0:1' },
          'next' => { 'cursor' => '1572959139000:0:0' }
        )
      end
    end

    context 'when error object created from sentry response' do
      using RSpec::Parameterized::TableSyntax

      where(:error_object, :sentry_response) do
        :id           | :id
        :first_seen   | :firstSeen
        :last_seen    | :lastSeen
        :title        | :title
        :type         | :type
        :user_count   | :userCount
        :count        | :count
        :message      | [:metadata, :value]
        :culprit      | :culprit
        :short_id     | :shortId
        :status       | :status
        :frequency    | [:stats, '24h']
        :project_id   | [:project, :id]
        :project_name | [:project, :name]
        :project_slug | [:project, :slug]
      end

      with_them do
        it { expect(subject[:issues][0].public_send(error_object)).to eq(sentry_api_response[0].dig(*sentry_response)) }
      end

      it_behaves_like 'has correct external_url'
    end

    context 'with redirects' do
      let(:sentry_api_url) { "#{sentry_url}/issues/?limit=20&query=is:unresolved" }

      it_behaves_like 'no Sentry redirects'
    end

    context 'with sort parameter in sentry api' do
      let(:sentry_request_url) do
        'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project/' \
          'issues/?limit=20&query=is:unresolved&sort=freq'
      end

      let!(:sentry_api_request) { stub_sentry_request(sentry_request_url, body: sentry_api_response) }

      subject { client.list_issues(issue_status: issue_status, limit: limit, sort: 'frequency') }

      it 'calls the sentry api with sort params' do
        expect(Gitlab::HTTP).to receive(:get).with(
          URI("#{sentry_url}/issues/"),
          default_httparty_options.merge(query: { limit: 20, query: "is:unresolved", sort: "freq" })
        ).and_call_original

        subject

        expect(sentry_api_request).to have_been_requested
      end
    end

    context 'with invalid sort params' do
      subject { client.list_issues(issue_status: issue_status, limit: limit, sort: 'fish') }

      it 'throws an error' do
        expect { subject }.to raise_error(ErrorTracking::SentryClient::BadRequestError, 'Invalid value for sort param')
      end
    end

    context 'with older sentry versions where keys are not present' do
      let(:sentry_api_response) do
        issues_sample_response.first(1).map do |issue|
          issue[:project].delete(:id)
          issue
        end
      end

      it_behaves_like 'calls sentry api'

      it_behaves_like 'issues have correct return type', Gitlab::ErrorTracking::Error
      it_behaves_like 'issues have correct length', 1

      it_behaves_like 'has correct external_url'
    end

    context 'when essential keys are missing in API response' do
      let(:sentry_api_response) do
        issues_sample_response.first(1).map do |issue|
          issue.except(:id)
        end
      end

      it 'raises exception' do
        expect { subject }.to raise_error(
          ErrorTracking::SentryClient::MissingKeysError,
          'Sentry API response is missing keys. key not found: "id"'
        )
      end
    end

    context 'when search term is present' do
      let(:search_term) { 'NoMethodError' }
      let(:sentry_request_url) { "#{sentry_url}/issues/?limit=20&query=is:unresolved NoMethodError" }

      it_behaves_like 'calls sentry api'

      it_behaves_like 'issues have correct return type', Gitlab::ErrorTracking::Error
      it_behaves_like 'issues have correct length', 3
    end

    context 'when cursor is present' do
      let(:cursor) { '1572959139000:0:0' }
      let(:sentry_request_url) { "#{sentry_url}/issues/?limit=20&cursor=#{cursor}&query=is:unresolved" }

      it_behaves_like 'calls sentry api'

      it_behaves_like 'issues have correct return type', Gitlab::ErrorTracking::Error
      it_behaves_like 'issues have correct length', 3
    end

    it_behaves_like 'non-numeric input handling in Sentry response', 'id' do
      let(:sentry_api_response) do
        issues_sample_response.first(1).map do |issue|
          issue[:id] = id_input
          issue
        end
      end
    end
  end

  describe '#issue_details' do
    let(:issue_sample_response) do
      Gitlab::Utils.deep_indifferent_access(
        Gitlab::Json.parse(fixture_file('sentry/issue_sample_response.json'))
      )
    end

    let(:sentry_api_response) { issue_sample_response }
    let(:sentry_request_url) { "#{sentry_url}/issues/#{issue_id}/" }
    let!(:sentry_api_request) { stub_sentry_request(sentry_request_url, body: sentry_api_response) }

    subject { client.issue_details(issue_id: issue_id) }

    it_behaves_like 'maps Sentry exceptions'
    it_behaves_like 'Sentry API response size limit'

    context 'with error object created from sentry response' do
      using RSpec::Parameterized::TableSyntax

      where(:error_object, :sentry_response) do
        :id                          | :id
        :first_seen                  | :firstSeen
        :last_seen                   | :lastSeen
        :title                       | :title
        :type                        | :type
        :user_count                  | :userCount
        :count                       | :count
        :message                     | [:metadata, :value]
        :culprit                     | :culprit
        :short_id                    | :shortId
        :status                      | :status
        :frequency                   | [:stats, '24h']
        :project_id                  | [:project, :id]
        :project_name                | [:project, :name]
        :project_slug                | [:project, :slug]
        :first_release_last_commit   | [:firstRelease, :lastCommit]
        :last_release_last_commit    | [:lastRelease, :lastCommit]
        :first_release_short_version | [:firstRelease, :shortVersion]
        :last_release_short_version  | [:lastRelease, :shortVersion]
        :first_release_version       | [:firstRelease, :version]
        :last_release_version        | [:lastRelease, :version]
      end

      with_them do
        it do
          expect(subject.public_send(error_object)).to eq(issue_sample_response.dig(*sentry_response))
        end
      end

      it 'has a correct external URL' do
        expect(subject.external_url).to eq('https://sentrytest.gitlab.com/api/0/issues/11')
      end

      it 'issue has a correct external base url' do
        expect(subject.external_base_url).to eq('https://sentrytest.gitlab.com/api/0')
      end

      it 'has a correct GitLab issue url' do
        expect(subject.gitlab_issue).to eq('https://gitlab.com/gitlab-org/gitlab/issues/1')
      end

      it 'has an integrated attribute set to false' do
        expect(subject.integrated).to be_falsey
      end

      context 'when issue annotations exist' do
        before do
          issue_sample_response['annotations'] = [
            nil,
            '',
            "<a href=\"http://github.com/issues/6\">github-issue-6</a>",
            "<div>annotation</a>",
            "<a href=\"http://localhost/gitlab-org/gitlab/issues/2\">gitlab-org/gitlab#2</a>"
          ]
          stub_sentry_request(sentry_request_url, body: issue_sample_response)
        end

        it 'has a correct GitLab issue url' do
          expect(subject.gitlab_issue).to eq('http://localhost/gitlab-org/gitlab/issues/2')
        end
      end

      context 'when no GitLab issue is linked' do
        before do
          issue_sample_response['pluginIssues'] = []
          stub_sentry_request(sentry_request_url, body: issue_sample_response)
        end

        it 'does not find a GitLab issue' do
          expect(subject.gitlab_issue).to be_nil
        end
      end

      it 'has the correct tags' do
        expect(subject.tags).to eq({ level: issue_sample_response['level'], logger: issue_sample_response['logger'] })
      end
    end

    it_behaves_like 'non-numeric input handling in Sentry response', 'id' do
      let(:sentry_api_response) do
        issue_sample_response.tap do |issue|
          issue[:id] = id_input
        end
      end
    end
  end

  describe '#update_issue' do
    let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0' }
    let(:sentry_request_url) { "#{sentry_url}/issues/#{issue_id}/" }
    let(:params) do
      {
        status: 'resolved'
      }
    end

    before do
      stub_sentry_request(sentry_request_url, :put)
    end

    subject { client.update_issue(issue_id: issue_id, params: params) }

    it_behaves_like 'Sentry API response size limit' do
      let(:sentry_api_response) { {} }
    end

    it_behaves_like 'calls sentry api' do
      let(:sentry_api_request) { stub_sentry_request(sentry_request_url, :put) }
    end

    it 'returns a truthy result' do
      expect(subject).to be_truthy
    end

    context 'when error is encountered' do
      let(:error) { StandardError.new('error') }

      before do
        allow(client).to receive(:update_issue).and_raise(error)
      end

      it 'raises the error' do
        expect { subject }.to raise_error(error)
      end
    end
  end
end
