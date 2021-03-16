# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::SentryClient do
  include SentryClientHelpers

  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:token) { 'test-token' }
  let(:default_httparty_options) do
    {
      follow_redirects: false,
      headers: { "Authorization" => "Bearer test-token" }
    }
  end

  let(:client) { described_class.new(sentry_url, token) }

  describe '#issue_latest_event' do
    let(:sample_response) do
      Gitlab::Utils.deep_indifferent_access(
        Gitlab::Json.parse(fixture_file('sentry/issue_latest_event_sample_response.json'))
      )
    end

    let(:issue_id) { '1234' }
    let(:sentry_api_response) { sample_response }
    let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0' }
    let(:sentry_request_url) { "#{sentry_url}/issues/#{issue_id}/events/latest/" }
    let!(:sentry_api_request) { stub_sentry_request(sentry_request_url, body: sentry_api_response) }

    subject { client.issue_latest_event(issue_id: issue_id) }

    it_behaves_like 'calls sentry api'

    it 'has correct return type' do
      expect(subject).to be_a(Gitlab::ErrorTracking::ErrorEvent)
    end

    shared_examples 'assigns error tracking event correctly' do
      using RSpec::Parameterized::TableSyntax

      where(:event_object, :sentry_response) do
        :issue_id      | :groupID
        :date_received | :dateReceived
      end

      with_them do
        it { expect(subject.public_send(event_object)).to eq(sentry_api_response.dig(*sentry_response)) }
      end
    end

    context 'error object created from sentry response' do
      it_behaves_like 'assigns error tracking event correctly'

      it 'parses the stack trace' do
        expect(subject.stack_trace_entries).to be_a Array
        expect(subject.stack_trace_entries).not_to be_empty
      end

      context 'error without stack trace' do
        before do
          sample_response['entries'] = []
          stub_sentry_request(sentry_request_url, body: sample_response)
        end

        it_behaves_like 'assigns error tracking event correctly'

        it 'returns an empty array for stack_trace_entries' do
          expect(subject.stack_trace_entries).to eq []
        end
      end
    end
  end
end
