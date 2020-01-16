# frozen_string_literal: true

require 'spec_helper'

describe Sentry::Client::IssueLink do
  include SentryClientHelpers

  let(:error_tracking_setting) { create(:project_error_tracking_setting, api_url: sentry_url) }
  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:client) { error_tracking_setting.sentry_client }

  let(:issue_link_sample_response) { JSON.parse(fixture_file('sentry/issue_link_sample_response.json')) }

  describe '#create_issue_link' do
    let(:integration_id) { 44444 }
    let(:sentry_issue_id) { 11111111 }
    let(:issue) { create(:issue, project: error_tracking_setting.project) }

    let(:sentry_issue_link_url) { "https://sentrytest.gitlab.com/api/0/groups/#{sentry_issue_id}/integrations/#{integration_id}/" }
    let(:sentry_api_response) { issue_link_sample_response }
    let!(:sentry_api_request) { stub_sentry_request(sentry_issue_link_url, :put, body: sentry_api_response, status: 201) }

    subject { client.create_issue_link(integration_id, sentry_issue_id, issue) }

    it_behaves_like 'calls sentry api'

    it { is_expected.to be_present }

    context 'redirects' do
      let(:sentry_api_url) { sentry_issue_link_url }

      it_behaves_like 'no Sentry redirects', :put
    end

    context 'when exception is raised' do
      let(:sentry_request_url) { sentry_issue_link_url }

      it_behaves_like 'maps Sentry exceptions', :put
    end
  end
end
