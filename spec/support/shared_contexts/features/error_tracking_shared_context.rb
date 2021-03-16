# frozen_string_literal: true

RSpec.shared_context 'sentry error tracking context feature' do
  include ReactiveCachingHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:project_error_tracking_settings) { create(:project_error_tracking_setting, project: project) }
  let_it_be(:issue_response_body) { fixture_file('sentry/issue_sample_response.json') }
  let_it_be(:issue_response) { Gitlab::Json.parse(issue_response_body) }
  let_it_be(:event_response_body) { fixture_file('sentry/issue_latest_event_sample_response.json') }
  let_it_be(:event_response) { Gitlab::Json.parse(event_response_body) }
  let(:sentry_api_urls) { ErrorTracking::SentryClient::ApiUrls.new(project_error_tracking_settings.api_url) }
  let(:issue_id) { issue_response['id'] }
  let(:issue_seen) { 1.year.ago.utc }
  let(:formatted_issue_seen) { issue_seen.strftime("%Y-%m-%d %-l:%M:%S%p %Z") }
  let(:date_received) { 32.days.ago.utc }

  before do
    request_headers = { 'Authorization' => 'Bearer access_token_123', 'Content-Type' => 'application/json' }
    response_headers = { 'Content-Type' => 'application/json' }

    issue_response['firstSeen'] = issue_seen.iso8601(6)
    issue_response['lastSeen'] = issue_seen.iso8601(6)
    event_response['dateReceived'] = date_received.iso8601(6)

    issue_url = sentry_api_urls.issue_url(issue_id).to_s
    stub_request(:get, issue_url)
      .with(headers: request_headers)
      .to_return(status: 200, body: issue_response.to_json, headers: response_headers)
    event_url = sentry_api_urls.issue_latest_event_url(issue_id).to_s
    stub_request(:get, event_url)
      .with(headers: request_headers)
      .to_return(status: 200, body: event_response.to_json, headers: response_headers)
  end
end
