# frozen_string_literal: true

require 'spec_helper'

describe Sentry::Client do
  let(:issue_status) { 'unresolved' }
  let(:limit) { 20 }
  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:token) { 'test-token' }

  let(:sample_response) do
    Gitlab::Utils.deep_indifferent_access(
      JSON.parse(File.read(Rails.root.join('spec/fixtures/sentry/issues_sample_response.json')))
    )
  end

  subject(:client) { described_class.new(sentry_url, token) }

  describe '#list_issues' do
    subject { client.list_issues(issue_status: issue_status, limit: limit) }

    before do
      stub_sentry_request(sentry_url + '/issues/?limit=20&query=is:unresolved', body: sample_response)
    end

    it 'returns objects of type ErrorTracking::Error' do
      expect(subject.length).to eq(1)
      expect(subject[0]).to be_a(Gitlab::ErrorTracking::Error)
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
        it { expect(subject[0].public_send(error_object)).to eq(sample_response[0].dig(*sentry_response)) }
      end

      context 'external_url' do
        it 'is constructed correctly' do
          expect(subject[0].external_url).to eq('https://sentrytest.gitlab.com/sentry-org/sentry-project/issues/11')
        end
      end
    end

    context 'redirects' do
      let(:redirect_to) { 'https://redirected.example.com' }
      let(:other_url) { 'https://other.example.org' }

      let!(:redirected_req_stub) { stub_sentry_request(other_url) }

      let!(:redirect_req_stub) do
        stub_sentry_request(
          sentry_url + '/issues/?limit=20&query=is:unresolved',
          status: 302,
          headers: { location: redirect_to }
        )
      end

      it 'does not follow redirects' do
        expect { subject }.to raise_exception(Sentry::Client::Error, 'Sentry response error: 302')
        expect(redirect_req_stub).to have_been_requested
        expect(redirected_req_stub).not_to have_been_requested
      end
    end

    # Sentry API returns 404 if there are extra slashes in the URL!
    context 'extra slashes in URL' do
      let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects//sentry-org/sentry-project/' }
      let(:client) { described_class.new(sentry_url, token) }

      let!(:valid_req_stub) do
        stub_sentry_request(
          'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project/' \
          'issues/?limit=20&query=is:unresolved'
        )
      end

      it 'removes extra slashes in api url' do
        expect(Gitlab::HTTP).to receive(:get).with(
          URI('https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project/issues/'),
          anything
        ).and_call_original

        client.list_issues(issue_status: issue_status, limit: limit)

        expect(valid_req_stub).to have_been_requested
      end
    end
  end

  private

  def stub_sentry_request(url, body: {}, status: 200, headers: {})
    WebMock.stub_request(:get, url)
      .to_return(
        status: status,
        headers: { 'Content-Type' => 'application/json' }.merge(headers),
        body: body.to_json
      )
  end
end
