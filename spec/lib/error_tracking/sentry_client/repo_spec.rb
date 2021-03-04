# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::SentryClient::Repo do
  include SentryClientHelpers

  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:token) { 'test-token' }
  let(:client) { ErrorTracking::SentryClient.new(sentry_url, token) }
  let(:repos_sample_response) { Gitlab::Json.parse(fixture_file('sentry/repos_sample_response.json')) }

  describe '#repos' do
    let(:organization_slug) { 'gitlab' }
    let(:sentry_repos_url) { "https://sentrytest.gitlab.com/api/0/organizations/#{organization_slug}/repos/" }
    let(:sentry_api_response) { repos_sample_response }
    let!(:sentry_api_request) { stub_sentry_request(sentry_repos_url, body: sentry_api_response) }

    subject { client.repos(organization_slug) }

    it_behaves_like 'calls sentry api'

    it { is_expected.to all( be_a(Gitlab::ErrorTracking::Repo)) }

    it { expect(subject.length).to eq(1) }

    context 'redirects' do
      let(:sentry_api_url) { sentry_repos_url }

      it_behaves_like 'no Sentry redirects'
    end

    context 'when exception is raised' do
      let(:sentry_request_url) { sentry_repos_url }

      it_behaves_like 'maps Sentry exceptions'
    end
  end
end
