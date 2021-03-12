# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::SentryClient::ApiUrls do
  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project/' }
  let(:token) { 'test-token' }
  let(:issue_id) { '123456' }
  let(:issue_id_with_reserved_chars) { '123$%' }
  let(:escaped_issue_id) { '123%24%25' }
  let(:api_urls) { described_class.new(sentry_url) }

  # Sentry API returns 404 if there are extra slashes in the URL!
  shared_examples 'correct url with extra slashes' do
    let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects//sentry-org/sentry-project/' }

    it_behaves_like 'correct url'
  end

  shared_examples 'correctly escapes issue ID' do
    context 'with param a string with reserved chars' do
      let(:issue_id) { issue_id_with_reserved_chars }

      it { expect(subject.to_s).to include(escaped_issue_id) }
    end

    context 'with param a symbol with reserved chars' do
      let(:issue_id) { issue_id_with_reserved_chars.to_sym }

      it { expect(subject.to_s).to include(escaped_issue_id) }
    end

    context 'with param an integer' do
      let(:issue_id) { 12345678 }

      it { expect(subject.to_s).to include(issue_id.to_s) }
    end
  end

  describe '#issues_url' do
    subject { api_urls.issues_url }

    shared_examples 'correct url' do
      it { is_expected.to eq_uri('https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project/issues/') }
    end

    it_behaves_like 'correct url'
    it_behaves_like 'correct url with extra slashes'
  end

  describe '#issue_url' do
    subject { api_urls.issue_url(issue_id) }

    shared_examples 'correct url' do
      it { is_expected.to eq_uri("https://sentrytest.gitlab.com/api/0/issues/#{issue_id}/") }
    end

    it_behaves_like 'correct url'
    it_behaves_like 'correct url with extra slashes'
    it_behaves_like 'correctly escapes issue ID'
  end

  describe '#projects_url' do
    subject { api_urls.projects_url }

    shared_examples 'correct url' do
      it { is_expected.to eq_uri('https://sentrytest.gitlab.com/api/0/projects/') }
    end

    it_behaves_like 'correct url'
    it_behaves_like 'correct url with extra slashes'
  end

  describe '#issue_latest_event_url' do
    subject { api_urls.issue_latest_event_url(issue_id) }

    shared_examples 'correct url' do
      it { is_expected.to eq_uri("https://sentrytest.gitlab.com/api/0/issues/#{issue_id}/events/latest/") }
    end

    it_behaves_like 'correct url'
    it_behaves_like 'correct url with extra slashes'
    it_behaves_like 'correctly escapes issue ID'
  end
end
