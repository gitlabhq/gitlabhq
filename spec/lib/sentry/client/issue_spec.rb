# frozen_string_literal: true

require 'spec_helper'

describe Sentry::Client::Issue do
  include SentryClientHelpers

  let(:token) { 'test-token' }
  let(:client) { Sentry::Client.new(sentry_url, token) }

  describe '#issue_details' do
    let(:issue_sample_response) do
      Gitlab::Utils.deep_indifferent_access(
        JSON.parse(fixture_file('sentry/issue_sample_response.json'))
      )
    end

    let(:issue_id) { 503504 }
    let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0' }
    let(:sentry_request_url) { "#{sentry_url}/issues/#{issue_id}/" }
    let!(:sentry_api_request) { stub_sentry_request(sentry_request_url, body: issue_sample_response) }

    subject { client.issue_details(issue_id: issue_id) }

    it_behaves_like 'calls sentry api'

    it 'escapes issue ID' do
      allow(CGI).to receive(:escape).and_call_original

      subject

      expect(CGI).to have_received(:escape).with(issue_id.to_s)
    end

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
    end
  end
end
