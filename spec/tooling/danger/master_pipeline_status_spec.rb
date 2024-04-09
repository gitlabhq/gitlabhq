# frozen_string_literal: true

require 'gitlab/dangerfiles/spec_helper'
require 'fast_spec_helper'
require 'webmock/rspec'

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
          'web_url' => "rspec_failed_web_url",
          'finished_at' => "2024-03-25T18:49:52.259Z"
        }
      },
      {
        'name' => 'eslint',
        'stage' => 'test',
        'status' => 'success'
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

  let(:status_file_content)    { JSON.pretty_generate(statuses) } # rubocop:disable Gitlab/Json -- JSON is sufficient
  let(:pipeline_jobs_response) { double('PipelineJobsResponse', auto_paginate: jobs) } # rubocop:disable RSpec/VerifiedDoubles -- type is not relevant
  let(:ci_mr_event_type)       { 'merged_result' }
  let(:target_branch)          { 'master' }

  let(:expected_status_url) do
    'https://gitlab.com/gitlab-org/quality/engineering-productivity/master-broken-incidents/-/raw/master-pipeline-status/canonical-gitlab-master-pipeline-status.json'
  end

  subject(:master_pipeline_status) { fake_danger.new(helper: fake_helper) }

  before do
    allow(master_pipeline_status).to receive_message_chain(:gitlab, :api, :pipeline_jobs) do
      pipeline_jobs_response
    end

    stub_const('ENV',
      {
        'CI_MERGE_REQUEST_EVENT_TYPE' => ci_mr_event_type,
        'CI_PROJECT_ID' => 1,
        'CI_PIPELINE_ID' => 1
      }
    )

    stub_request(:get, expected_status_url).to_return({ status: 200, body: status_file_content })
    allow(fake_helper).to receive(:ci?).and_return(ci_env)
    allow(master_pipeline_status.helper).to receive(:mr_target_branch).and_return(target_branch)
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

      context 'when MR target branch is not master' do
        let(:target_branch) { 'feature' }

        it 'does not add the warnings' do
          expect(master_pipeline_status).not_to receive(:warn)
          master_pipeline_status.check!
        end
      end

      context 'when CI_MERGE_REQUEST_EVENT_TYPE is not merge_request' do
        let(:ci_mr_event_type) { 'detached' }

        it 'does not add the warnings' do
          expect(master_pipeline_status).not_to receive(:warn)
        end
      end

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

      context 'when rubocop is reported to have failed in the pipeline status page' do
        it 'raises warnings for rubocop' do
          expect(master_pipeline_status).to receive(:warn).with(
            <<~MSG
              The [master pipeline status page](#{expected_status_url}) reported failures in

              * [rubocop](rubocop_failed_web_url)
              * [rspec](rspec_failed_web_url)

              If these jobs fail in your merge request with the same errors, then they are not caused by your changes.
              Please check for any on-going incidents in the [incident issue tracker](#{described_class::STATUS_FILE_PROJECT}/-/issues) or in the `#master-broken` Slack channel.
            MSG
          )

          master_pipeline_status.check!
        end
      end

      context 'when status file request returned 404' do
        let(:expected_output) { "Request to #{expected_status_url} returned 404 Not Found. Ignoring.\n" }

        before do
          allow(Net::HTTP).to receive(:get_response).and_return(instance_double(Net::HTTPResponse,
            code: '404',
            message: 'Not Found'
          ))
        end

        it 'does not raise any warning' do
          expect(master_pipeline_status).not_to receive(:warn)
          expect { master_pipeline_status.check! }.to output(expected_output).to_stdout
        end
      end

      context 'when status file does not contain a valid JSON' do
        let(:status_file_content) { '{' }
        let(:expected_output) do
          <<~MSG
            Failed to parse JSON for #{expected_status_url}. Ignoring. Full error:
            unexpected token at '{'
          MSG
        end

        it 'does not raise any warning' do
          expect(master_pipeline_status).not_to receive(:warn)
          expect { master_pipeline_status.check! }.to output(expected_output).to_stdout
        end
      end

      context 'when api returns error when fetching pipeline jobs' do
        let(:expected_output) { "Failed to retrieve CI jobs via API for project 1 and 1: StandardError. Ignoring.\n" }
        let(:pipeline_jobs_response) { raise StandardError, expected_output.chomp }

        it 'does not raise any warning' do
          expect(master_pipeline_status).not_to receive(:warn)
          expect { master_pipeline_status.check! }.to output(expected_output).to_stdout
        end
      end
    end
  end
end
