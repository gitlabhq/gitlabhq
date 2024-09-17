# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/all'
require_relative '../../scripts/generate-failed-test-on-omnibus-mr-message'

RSpec.describe GenerateFailedTestOnOmnibusMrMessage, feature_category: :tooling do
  include StubENV

  describe '#execute' do
    let(:options) do
      {
        project: 1234,
        api_token: 'asdf1234'
      }
    end

    let(:commit_merge_request) do
      {
        'author' => {
          'id' => '2',
          'username' => 'test_user'
        }
      }
    end

    let(:package_and_test_job) do
      { 'web_url' => 'http://example.com' }
    end

    let(:merge_request) { instance_double(CommitMergeRequests, execute: [commit_merge_request]) }
    let(:content) { /The `e2e:test-on-omnibus-ee` child pipeline has failed./ }
    let(:merge_request_discussion_client) { instance_double(CreateMergeRequestDiscussion, execute: true) }
    let(:package_and_test_job_client) { instance_double(GetTestOnOmnibusJob, execute: package_and_test_job) }

    subject(:discussion_added) { described_class.new(options).execute }

    before do
      stub_env(
        'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA' => 'bfcd2b9b5cad0b889494ce830697392c8ca11257',
        'CI_PROJECT_ID' => '13083',
        'CI_PIPELINE_ID' => '1234567',
        'CI_PIPELINE_URL' => 'https://gitlab.com/gitlab-org/gitlab/-/pipelines/1234567',
        'PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE' => 'asdf1234'
      )

      allow(GetTestOnOmnibusJob).to receive(:new)
        .with(API::DEFAULT_OPTIONS)
        .and_return(package_and_test_job_client)
    end

    context 'when test-on-omnibus fails' do
      before do
        allow(CommitMergeRequests).to receive(:new)
          .with(API::DEFAULT_OPTIONS.merge(sha: ENV['CI_MERGE_REQUEST_SOURCE_BRANCH_SHA']))
          .and_return(merge_request)
      end

      it 'successfully creates a discussion' do
        expect(CreateMergeRequestDiscussion).to receive(:new)
          .with(API::DEFAULT_OPTIONS.merge(merge_request: commit_merge_request))
          .and_return(merge_request_discussion_client)

        expect(merge_request_discussion_client).to receive(:execute).with(content)

        expect(discussion_added).to eq(true)
      end
    end

    context 'when test-on-omnibus is did not fail' do
      let(:package_and_test_job_client) { instance_double(GetTestOnOmnibusJob, execute: nil) }

      it 'does not add a discussion' do
        expect(CreateMergeRequestDiscussion).not_to receive(:new)
        expect(discussion_added).to eq(nil)
      end
    end
  end
end
