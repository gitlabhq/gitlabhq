# frozen_string_literal: true

require 'spec_helper'

describe Sentry::Client::Issue do
  include SentryClientHelpers

  let(:token) { 'test-token' }
  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0' }
  let(:client) { Sentry::Client.new(sentry_url, token) }
  let(:issue_id) { 503504 }

  describe '#list_issues' do
    shared_examples 'issues have correct return type' do |klass|
      it "returns objects of type #{klass}" do
        expect(subject[:issues]).to all( be_a(klass) )
      end
    end

    shared_examples 'issues have correct length' do |length|
      it { expect(subject[:issues].length).to eq(length) }
    end

    let(:issues_sample_response) do
      Gitlab::Utils.deep_indifferent_access(
        JSON.parse(fixture_file('sentry/issues_sample_response.json'))
      )
    end

    let(:default_httparty_options) do
      {
        follow_redirects: false,
        headers: { "Authorization" => "Bearer test-token" }
      }
    end

    let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
    let(:issue_status) { 'unresolved' }
    let(:limit) { 20 }
    let(:search_term) { '' }
    let(:cursor) { nil }
    let(:sort) { 'last_seen' }
    let(:sentry_api_response) { issues_sample_response }
    let(:sentry_request_url) { sentry_url + '/issues/?limit=20&query=is:unresolved' }
    let!(:sentry_api_request) { stub_sentry_request(sentry_request_url, body: sentry_api_response) }

    subject { client.list_issues(issue_status: issue_status, limit: limit, search_term: search_term, sort: sort, cursor: cursor) }

    it_behaves_like 'calls sentry api'

    it_behaves_like 'issues have correct return type', Gitlab::ErrorTracking::Error
    it_behaves_like 'issues have correct length', 1

    shared_examples 'has correct external_url' do
      context 'external_url' do
        it 'is constructed correctly' do
          expect(subject[:issues][0].external_url).to eq('https://sentrytest.gitlab.com/sentry-org/sentry-project/issues/11')
        end
      end
    end

    context 'when response has a pagination info' do
      let(:headers) do
        {
          link: '<https://sentrytest.gitlab.com>; rel="previous"; results="true"; cursor="1573556671000:0:1", <https://sentrytest.gitlab.com>; rel="next"; results="true"; cursor="1572959139000:0:0"'
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

    context 'error object created from sentry response' do
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

    context 'redirects' do
      let(:sentry_api_url) { sentry_url + '/issues/?limit=20&query=is:unresolved' }

      it_behaves_like 'no Sentry redirects'
    end

    context 'requests with sort parameter in sentry api' do
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
        expect { subject }.to raise_error(Sentry::Client::BadRequestError, 'Invalid value for sort param')
      end
    end

    context 'Older sentry versions where keys are not present' do
      let(:sentry_api_response) do
        issues_sample_response[0...1].map do |issue|
          issue[:project].delete(:id)
          issue
        end
      end

      it_behaves_like 'calls sentry api'

      it_behaves_like 'issues have correct return type', Gitlab::ErrorTracking::Error
      it_behaves_like 'issues have correct length', 1

      it_behaves_like 'has correct external_url'
    end

    context 'essential keys missing in API response' do
      let(:sentry_api_response) do
        issues_sample_response[0...1].map do |issue|
          issue.except(:id)
        end
      end

      it 'raises exception' do
        expect { subject }.to raise_error(Sentry::Client::MissingKeysError, 'Sentry API response is missing keys. key not found: "id"')
      end
    end

    context 'sentry api response too large' do
      it 'raises exception' do
        deep_size = double('Gitlab::Utils::DeepSize', valid?: false)
        allow(Gitlab::Utils::DeepSize).to receive(:new).with(sentry_api_response).and_return(deep_size)

        expect { subject }.to raise_error(Sentry::Client::ResponseInvalidSizeError, 'Sentry API response is too big. Limit is 1 MB.')
      end
    end

    it_behaves_like 'maps Sentry exceptions'

    context 'when search term is present' do
      let(:search_term) { 'NoMethodError' }
      let(:sentry_request_url) { "#{sentry_url}/issues/?limit=20&query=is:unresolved NoMethodError" }

      it_behaves_like 'calls sentry api'

      it_behaves_like 'issues have correct return type', Gitlab::ErrorTracking::Error
      it_behaves_like 'issues have correct length', 1
    end

    context 'when cursor is present' do
      let(:cursor) { '1572959139000:0:0' }
      let(:sentry_request_url) { "#{sentry_url}/issues/?limit=20&cursor=#{cursor}&query=is:unresolved" }

      it_behaves_like 'calls sentry api'

      it_behaves_like 'issues have correct return type', Gitlab::ErrorTracking::Error
      it_behaves_like 'issues have correct length', 1
    end
  end

  describe '#issue_details' do
    let(:issue_sample_response) do
      Gitlab::Utils.deep_indifferent_access(
        JSON.parse(fixture_file('sentry/issue_sample_response.json'))
      )
    end

    let(:sentry_request_url) { "#{sentry_url}/issues/#{issue_id}/" }
    let!(:sentry_api_request) { stub_sentry_request(sentry_request_url, body: issue_sample_response) }

    subject { client.issue_details(issue_id: issue_id) }

    context 'error object created from sentry response' do
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
      end

      with_them do
        it do
          expect(subject.public_send(error_object)).to eq(issue_sample_response.dig(*sentry_response))
        end
      end

      it 'has a correct external URL' do
        expect(subject.external_url).to eq('https://sentrytest.gitlab.com/api/0/issues/503504')
      end

      it 'issue has a correct external base url' do
        expect(subject.external_base_url).to eq('https://sentrytest.gitlab.com/api/0')
      end

      it 'has a correct GitLab issue url' do
        expect(subject.gitlab_issue).to eq('https://gitlab.com/gitlab-org/gitlab/issues/1')
      end

      it 'has the correct tags' do
        expect(subject.tags).to eq({ level: issue_sample_response['level'], logger: issue_sample_response['logger'] })
      end
    end
  end

  describe '#update_issue' do
    let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0' }
    let(:sentry_request_url) { "#{sentry_url}/issues/#{issue_id}/" }

    before do
      stub_sentry_request(sentry_request_url, :put)
    end

    let(:params) do
      {
        status: 'resolved'
      }
    end

    subject { client.update_issue(issue_id: issue_id, params: params) }

    it_behaves_like 'calls sentry api' do
      let(:sentry_api_request) { stub_sentry_request(sentry_request_url, :put) }
    end

    it 'returns a truthy result' do
      expect(subject).to be_truthy
    end

    context 'error encountered' do
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
