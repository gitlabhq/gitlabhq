# frozen_string_literal: true

shared_context 'sentry error tracking context feature' do
  include ReactiveCachingHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:project_error_tracking_settings) { create(:project_error_tracking_setting, project: project) }
  let_it_be(:issue_response_body) { fixture_file('sentry/issue_sample_response.json') }
  let_it_be(:issue_response) { JSON.parse(issue_response_body) }
  let_it_be(:event_response_body) { fixture_file('sentry/issue_latest_event_sample_response.json') }
  let_it_be(:event_response) { JSON.parse(event_response_body) }
  let(:sentry_api_urls) { Sentry::ApiUrls.new(project_error_tracking_settings.api_url) }
  let(:issue_id) { issue_response['id'] }

  before do
    stub_request(:get, sentry_api_urls.issue_url(issue_id)).with(
      headers: { 'Authorization' => 'Bearer access_token_123' }
    ).to_return(status: 200, body: issue_response_body, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, sentry_api_urls.issue_latest_event_url(issue_id)).with(
      headers: { 'Authorization' => 'Bearer access_token_123' }
    ).to_return(status: 200, body: event_response_body, headers: { 'Content-Type' => 'application/json' })
  end
end
