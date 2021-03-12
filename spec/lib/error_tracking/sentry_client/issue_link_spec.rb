# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::SentryClient::IssueLink do
  include SentryClientHelpers

  let_it_be(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let_it_be(:error_tracking_setting) { create(:project_error_tracking_setting, api_url: sentry_url) }
  let_it_be(:issue) { create(:issue, project: error_tracking_setting.project) }

  let(:client) { error_tracking_setting.sentry_client }
  let(:sentry_issue_id) { 11111111 }

  describe '#create_issue_link' do
    let(:sentry_issue_link_url) { "https://sentrytest.gitlab.com/api/0/groups/#{sentry_issue_id}/integrations/#{integration_id}/" }
    let(:integration_id) { 44444 }

    let(:issue_link_sample_response) { Gitlab::Json.parse(fixture_file('sentry/global_integration_link_sample_response.json')) }
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

    context 'when integration_id is not provided' do
      let(:sentry_issue_link_url) { "https://sentrytest.gitlab.com/api/0/issues/#{sentry_issue_id}/plugins/gitlab/link/" }
      let(:integration_id) { nil }

      let(:issue_link_sample_response) { Gitlab::Json.parse(fixture_file('sentry/plugin_link_sample_response.json')) }
      let!(:sentry_api_request) { stub_sentry_request(sentry_issue_link_url, :post, body: sentry_api_response) }

      it_behaves_like 'calls sentry api'

      it { is_expected.to be_present }

      context 'redirects' do
        let(:sentry_api_url) { sentry_issue_link_url }

        it_behaves_like 'no Sentry redirects', :post
      end

      context 'when exception is raised' do
        let(:sentry_request_url) { sentry_issue_link_url }

        it_behaves_like 'maps Sentry exceptions', :post
      end
    end
  end
end
