# frozen_string_literal: true

require 'gitlab/dangerfiles/spec_helper'
require 'fast_spec_helper'

require_relative '../../../tooling/danger/master_pipeline_status'

RSpec.describe Tooling::Danger::MasterPipelineStatus, feature_category: :tooling do
  include_context 'with dangerfile'

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:statuses) do
    [
      {
        'name' => 'rubocop',
        'stage' => 'linter',
        'status' => 'failed',
        'last_finished_at' => '2016-08-12 15:23:28 UTC',
        'last_failed' => {
          'web_url' => "rubocop_failed_web_url",
          'finished_at' => "2024-03-25T18:49:52.259Z"
        }
      },
      {
        'name' => 'rspec',
        'stage' => 'test',
        'status' => 'failed',
        'last_finished_at' => '2016-08-12 15:23:28 UTC',
        'last_failed' => {
          'web_url' => "rubocop_failed_web_url",
          'finished_at' => "2024-03-25T18:49:52.259Z"
        }
      },
      {
        'name' => 'eslint',
        'stage' => 'test',
        'status' => 'success',
        'last_finished_at' => '2016-08-12 15:23:28 UTC'
      }
    ]
  end

  let(:jobs) do
    [
      { 'name' => 'rubocop', 'stage' => 'linter', 'allow_failure' => false },
      { 'name' => 'rspec', 'stage' => 'test', 'allow_failure' => false },
      { 'name' => 'eslint', 'stage' => 'linter', 'allow_failure' => false }
    ]
  end

  let(:file_contents_response) { JSON.pretty_generate(statuses) } # rubocop:disable Gitlab/Json -- JSON is sufficient
  let(:pipeline_jobs_response) { double('PipelineJobsResponse', auto_paginate: jobs) } # rubocop:disable RSpec/VerifiedDoubles -- type is not relevant

  subject(:master_pipeline_status) { fake_danger.new(helper: fake_helper) }

  before do
    allow(master_pipeline_status).to receive_message_chain(:gitlab, :api, :pipeline_jobs) do
      pipeline_jobs_response
    end

    allow(master_pipeline_status).to receive_message_chain(:gitlab, :api, :file_contents) do
      file_contents_response
    end

    allow(fake_helper).to receive(:ci?).and_return(ci_env)
  end

  describe 'check!' do
    context 'when not in ci environment' do
      let(:ci_env) { false }

      it 'does not add the warnings' do
        expect(master_pipeline_status).not_to receive(:warn)

        master_pipeline_status.check!
      end
    end

    context 'when in ci environment' do
      let(:ci_env) { true }

      context 'when all tests are reported as passed in status page' do
        let(:statuses) do
          [
            {
              'name' => 'rubocop',
              'stage' => 'linter',
              'status' => 'success',
              'last_finished_at' => '2024-03-25T18:49:52.259Z'
            }
          ]
        end

        it 'does not raise any warning' do
          expect(master_pipeline_status).not_to receive(:warn)

          master_pipeline_status.check!
        end
      end

      context 'when rubocop is reproted to have failed in the pipeline status page' do
        it 'raises warnings for rubocop' do
          expect(master_pipeline_status).to receive(:warn).with(
            <<~MSG
              The [master pipeline status page](#{described_class::STATUS_PAGE_URL}) reported failures in

              * [rubocop](rubocop_failed_web_url)
              * [rspec](rubocop_failed_web_url)

              If these jobs fail in your merge request with the same errors, then they are not caused by your changes.
              Please check for any on-going incidents in the [incident issue tracker](#{described_class::INCIDENT_TRACKER_URL}) or in the `#master-broken` Slack channel.
            MSG
          )

          master_pipeline_status.check!
        end
      end

      context 'when api returns error when fetching pipeline status' do
        let(:file_contents_response) { raise StandardError, 'Failed to fetch file_contents' }

        it 'does not raise any warning' do
          expect(master_pipeline_status).not_to receive(:warn)

          master_pipeline_status.check!
        end
      end

      context 'when status file does not contain a valid JSON' do
        let(:file_contents_response) { '{' }

        it 'does not raise any warning' do
          expect(master_pipeline_status).not_to receive(:warn)

          master_pipeline_status.check!
        end
      end

      context 'when api returns error when fetching pipeline jobs' do
        let(:pipeline_jobs_response) { raise StandardError, 'Failed to fetch pipeline jobs' }

        it 'does not raise any warning' do
          expect(master_pipeline_status).not_to receive(:warn)

          master_pipeline_status.check!
        end
      end
    end
  end
end
