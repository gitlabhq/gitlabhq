# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/create-pipeline-failure-incident'
require_relative '../support/helpers/stub_env'

RSpec.describe CreatePipelineFailureIncident, feature_category: :tooling do
  include StubENV

  describe '#execute' do
    let(:create_issue) { instance_double(CreateIssue) }
    let(:issue) { double('Issue', iid: 1) } # rubocop:disable RSpec/VerifiedDoubles
    let(:create_issue_discussion) { instance_double(CreateIssueDiscussion, execute: true) }
    let(:failed_jobs) { instance_double(PipelineFailedJobs, execute: []) }

    let(:options) do
      {
        project: 'gitlab-org/gitlab-test-project',
        api_token: 'asdf1234'
      }
    end

    let(:issue_params) do
      {
        issue_type: 'incident',
        title: title,
        description: description,
        labels: incident_labels
      }
    end

    subject { described_class.new(options).execute }

    before do
      stub_env(
        'CI_COMMIT_SHA' => 'bfcd2b9b5cad0b889494ce830697392c8ca11257',
        'CI_PROJECT_PATH' => 'gitlab.com/gitlab-org/gitlab',
        'CI_PROJECT_NAME' => 'gitlab',
        'GITLAB_USER_ID' => '1111',
        'CI_PROJECT_ID' => '13083',
        'CI_PIPELINE_ID' => '1234567',
        'CI_PIPELINE_URL' => 'https://gitlab.com/gitlab-org/gitlab/-/pipelines/1234567',
        'CI_PROJECT_URL' => 'https://gitlab.com/gitlab-org/gitlab',
        'CI_PIPELINE_CREATED_AT' => '2023-01-24 00:00:00',
        'CI_COMMIT_TITLE' => 'Commit title',
        'CI_PIPELINE_SOURCE' => 'push',
        'GITLAB_USER_NAME' => 'Foo User',
        'PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE' => 'asdf1234',
        'CI_SERVER_URL' => 'https://gitlab.com',
        'GITLAB_USER_LOGIN' => 'foo'
      )
    end

    shared_examples 'creating an issue' do
      it 'successfully creates an issue' do
        allow(PipelineFailedJobs).to receive(:new)
          .with(API::DEFAULT_OPTIONS.merge(exclude_allowed_to_fail_jobs: true))
          .and_return(failed_jobs)

        expect(CreateIssue).to receive(:new)
          .with(project: options[:project], api_token: options[:api_token])
          .and_return(create_issue)

        expect(CreateIssueDiscussion).to receive(:new)
          .with(project: options[:project], api_token: options[:api_token])
          .and_return(create_issue_discussion).twice

        expect(create_issue).to receive(:execute)
          .with(issue_params).and_return(issue)

        expect(subject).to eq(issue)
      end
    end

    context 'when stable branch' do
      let(:incident_labels) { ['release-blocker'] }
      let(:title) { /broken `15-6-stable-ee`/ }
      let(:description) { /A broken stable branch prevents patch releases/ }

      let(:commit_merge_request) do
        {
          'author' => {
            'id' => '2'
          },
          'title' => 'foo',
          'web_url' => 'https://gitlab.com/test'
        }
      end

      let(:merge_request) { instance_double(CommitMergeRequests, execute: [commit_merge_request]) }
      let(:issue_params) { super().merge(assignee_ids: [1111, 2]) }

      before do
        stub_env(
          'CI_COMMIT_REF_NAME' => '15-6-stable-ee'
        )

        allow(CommitMergeRequests).to receive(:new)
          .with(API::DEFAULT_OPTIONS.merge(sha: ENV['CI_COMMIT_SHA']))
          .and_return(merge_request)
      end

      it_behaves_like 'creating an issue'
    end

    context 'when other branch' do
      let(:title) { /broken `master`/ }
      let(:description) { /Follow the \[Broken `master` handbook guide\]/ }

      before do
        stub_env(
          'CI_COMMIT_REF_NAME' => 'master'
        )
      end

      context 'when GitLab FOSS' do
        let(:incident_labels) { ['master:foss-broken', 'Engineering Productivity', 'master-broken::undetermined'] }

        before do
          stub_env(
            'CI_PROJECT_NAME' => 'gitlab-foss'
          )
        end

        it_behaves_like 'creating an issue'
      end

      context 'when GitLab EE' do
        let(:incident_labels) { ['master:broken', 'Engineering Productivity', 'master-broken::undetermined'] }

        before do
          stub_env(
            'CI_PROJECT_NAME' => 'gitlab'
          )
        end

        it_behaves_like 'creating an issue'
      end
    end

    context 'when review-apps' do
      let(:options) do
        {
          project: 'gitlab-org/quality/engineering-productivity/review-apps-broken-incidents',
          api_token: 'asdf1234'
        }
      end

      let(:incident_labels) { ["review-apps-broken", "Engineering Productivity", "ep::review-apps"] }
      let(:title)           { /broken `my-branch`/ }
      let(:description)     { /Please refer to \[the review-apps triaging process\]/ }

      before do
        stub_env(
          'CI_COMMIT_REF_NAME' => 'my-branch'
        )
      end

      it_behaves_like 'creating an issue'
    end
  end
end
