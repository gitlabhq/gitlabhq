# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/generate-failed-pipeline-slack-message'
require_relative '../support/helpers/stub_env'

RSpec.describe GenerateFailedPipelineSlackMessage, feature_category: :tooling do
  include StubENV

  describe '#execute' do
    let(:create_issue) { instance_double(CreateIssue) }
    let(:issue) { double('Issue', iid: 1) } # rubocop:disable RSpec/VerifiedDoubles
    let(:create_issue_discussion) { instance_double(CreateIssueDiscussion, execute: true) }
    let(:failed_jobs) { instance_double(PipelineFailedJobs, execute: []) }

    let(:project_path) { 'gitlab-org/gitlab-test-project' }
    let(:options) do
      {
        project: project_path,
        incident_json_file: 'incident_json_file_tests.json'
      }
    end

    subject { described_class.new(options).execute }

    before do
      stub_env(
        'CI_COMMIT_REF_NAME' => 'my-branch',
        'CI_COMMIT_SHA' => 'bfcd2b9b5cad0b889494ce830697392c8ca11257',
        'CI_COMMIT_TITLE' => 'Commit title',
        'CI_PIPELINE_CREATED_AT' => '2023-01-24 00:00:00',
        'CI_PIPELINE_ID' => '1234567',
        'CI_PIPELINE_SOURCE' => 'push',
        'CI_PIPELINE_URL' => 'https://gitlab.com/gitlab-org/gitlab/-/pipelines/1234567',
        'CI_PROJECT_PATH' => 'gitlab.com/gitlab-org/gitlab',
        'CI_PROJECT_URL' => 'https://gitlab.com/gitlab-org/gitlab',
        'CI_SERVER_URL' => 'https://gitlab.com',
        'GITLAB_USER_ID' => '1111',
        'GITLAB_USER_LOGIN' => 'foo',
        'GITLAB_USER_NAME' => 'Foo User',
        'PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE' => 'asdf1234',
        'SLACK_CHANNEL' => '#a-slack-channel'
      )

      allow(PipelineFailedJobs).to receive(:new)
      .with(API::DEFAULT_OPTIONS.merge(exclude_allowed_to_fail_jobs: true))
      .and_return(failed_jobs)
    end

    it 'returns the correct keys' do
      expect(subject.keys).to match_array([:channel, :username, :icon_emoji, :text, :blocks])
    end

    it 'returns the correct channel' do
      expect(subject[:channel]).to eq('#a-slack-channel')
    end

    it 'returns the correct username' do
      expect(subject[:username]).to eq('Failed pipeline reporter')
    end

    it 'returns the correct icon_emoji' do
      expect(subject[:icon_emoji]).to eq(':boom:')
    end

    it 'returns the correct text' do
      expect(subject[:text]).to eq(
        '*<https://gitlab.com/gitlab-org/gitlab|gitlab.com/gitlab-org/gitlab> pipeline ' \
        '<https://gitlab.com/gitlab-org/gitlab/-/pipelines/1234567|#1234567> failed*'
      )
    end

    it 'returns the correct incident button link' do
      block_with_incident_link = subject[:blocks].detect { |block| block.key?(:accessory) }

      expect(block_with_incident_link[:accessory][:url]).to eq(
        "https://gitlab.com/#{project_path}/-/issues/new?issuable_template=incident&issue%5Bissue_type%5D=incident"
      )
    end
  end
end
