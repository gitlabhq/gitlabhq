# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../tooling/ci/changed_files'

RSpec.describe CI::ChangedFiles, feature_category: :tooling do
  let(:instance) { described_class.new }

  describe '#should_run_checks_for_changed_files' do
    # The mock values are based on allowed values from the docs
    # https://docs.gitlab.com/ci/variables/predefined_variables/
    let(:pipeline_source) { 'merge_request_event' }
    let(:merge_request_event_type) { 'merged_result' }
    let(:commit_ref_name) { 'feature-branch' }

    before do
      stub_env('CI_PIPELINE_SOURCE', pipeline_source)
      stub_env('CI_MERGE_REQUEST_EVENT_TYPE', merge_request_event_type)
      stub_env('CI_COMMIT_REF_NAME', commit_ref_name)
    end

    context 'when in a valid merge request environment' do
      it 'returns true when no tier labels exist' do
        stub_env('CI_MERGE_REQUEST_LABELS', nil)
        expect(instance.should_run_checks_for_changed_files).to be true
      end

      it 'returns true when tier-1 label exists' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'pipeline::tier-1,other-label')
        expect(instance.should_run_checks_for_changed_files).to be true
      end

      it 'returns false when other tier label exists' do
        stub_env('CI_MERGE_REQUEST_LABELS', 'pipeline::tier-2,other-label')
        expect(instance.should_run_checks_for_changed_files).to be false
      end
    end

    context 'when not in a valid merge request environment' do
      context 'when the merge request event type is merge_train' do
        let(:merge_request_event_type) { 'merge_train' }

        it 'returns false' do
          expect(instance.should_run_checks_for_changed_files).to be false
        end
      end

      context 'when the pipeline source is not merged_request_event' do
        let(:pipeline_source) { 'push' }

        it 'returns false when pipeline source is push' do
          expect(instance.should_run_checks_for_changed_files).to be false
        end
      end

      context 'when the current branch is CI_DEFAULT_BRANCH' do
        let(:commit_ref_name) { 'master' }

        it 'returns false' do
          stub_env('CI_DEFAULT_BRANCH', 'master')
          expect(instance.should_run_checks_for_changed_files).to be false
        end
      end

      context 'when the environment variables are not set' do
        let(:pipeline_source) { nil }
        let(:merge_request_event_type) { nil }
        let(:commit_ref_name) { nil }

        it 'returns false' do
          expect(instance.should_run_checks_for_changed_files).to be false
        end
      end
    end
  end

  describe '#get_changed_files_in_merged_results_pipeline' do
    let(:git_diff_output) { "file1.js\nfile2.rb\nfile3.vue" }

    before do
      allow(instance).to receive(:`)
      .with('git diff --name-only --diff-filter=d HEAD~..HEAD')
      .and_return(git_diff_output)
    end

    context 'when git diff is run in a merged results pipeline' do
      it 'returns an array when there are changed files' do
        expect(instance.get_changed_files_in_merged_results_pipeline)
        .to match_array(['file1.js', 'file2.rb', 'file3.vue'])
      end

      context "when there are no changed files" do
        let(:git_diff_output) { "" }

        it 'returns an empty array' do
          expect(instance.get_changed_files_in_merged_results_pipeline).to eq([])
        end
      end
    end
  end

  describe '#filter_and_get_changed_files_in_mr' do
    context 'when checks should run for changed files' do \
      let(:changed_files_output) { ['file1.js', 'file2.rb', 'file3.vue'] }

      before do
        allow(instance).to receive_messages(
          should_run_checks_for_changed_files: true,
          get_changed_files_in_merged_results_pipeline: changed_files_output
        )
      end

      context 'when changed files exist' do
        it 'returns filtered files' do
          expect(instance.filter_and_get_changed_files_in_mr(filter_pattern: /\.(js|vue)$/))
          .to match_array(['file1.js', 'file3.vue'])
        end

        it 'returns all files when filter is empty' do
          expect(instance.filter_and_get_changed_files_in_mr)
          .to match_array(changed_files_output)
        end

        it 'returns empty array and prints warning when no files match filter' do
          allow(instance).to receive(:get_changed_files_in_merged_results_pipeline).and_return(['file1.txt',
            'file2.rb'])
          expect(instance).to receive(:puts).with('No files were changed. Skipping...')

          expect(instance.filter_and_get_changed_files_in_mr(filter_pattern: /\.(js|vue)$/)).to eq([])
        end
      end
    end

    context 'when checks should not run for changed files' do
      before do
        allow(instance).to receive(:should_run_checks_for_changed_files).and_return(false)
      end

      it 'returns ["."] and prints warning' do
        expect(instance).to receive(:puts).with("Changed file criteria didn't match... Command will run for all files")

        expect(instance.filter_and_get_changed_files_in_mr(filter_pattern: /\.(js|vue)$/)).to eq(['.'])
      end
    end
  end

  describe '#run_eslint_for_changed_files' do
    let(:files) { ['file1.js', 'file2.vue'] }
    let(:eslint_command) { ['yarn', 'run', 'lint:eslint', '--format', 'gitlab', 'file1.js', 'file2.vue'] }

    before do
      allow(instance).to receive(:puts).with('Running ESLint...')
    end

    context 'when there are changed files to lint' do
      before do
        allow(instance).to receive(:filter_and_get_changed_files_in_mr).and_return(files)
      end

      it 'runs eslint with the correct arguments and returns exit 0 on success' do
        expect(instance).to receive(:system).with(*eslint_command).and_return(true)

        status = instance_double(Process::Status, exitstatus: 0)
        allow(instance).to receive(:last_command_status).and_return(status)

        expect(instance.run_eslint_for_changed_files).to eq(0)
      end

      it 'runs eslint with the correct arguments and returns exit 1 on failure' do
        expect(instance).to receive(:system).with(*eslint_command).and_return(false)

        status = instance_double(Process::Status, exitstatus: 1)
        allow(instance).to receive(:last_command_status).and_return(status)

        expect(instance.run_eslint_for_changed_files).to eq(1)
      end
    end

    context 'when there are no changed files to lint' do
      it 'does not run eslint and returns exit code 0' do
        allow(instance).to receive(:filter_and_get_changed_files_in_mr).and_return([])
        expect(instance).not_to receive(:system)

        expect(instance.run_eslint_for_changed_files).to eq(0)
      end
    end
  end

  describe 'Run CLI commands' do
    it 'returns 0 for empty args' do
      allow(ARGV).to receive(:empty?).and_return(true)

      expect(instance.process_command_and_determine_exit_status).to eq(0)
    end

    it 'returns 0 when eslint succeeds' do
      allow(ARGV).to receive(:first).and_return('eslint')
      allow(instance).to receive(:run_eslint_for_changed_files).and_return(0)

      expect(instance.process_command_and_determine_exit_status).to eq(0)
    end

    it 'returns exit code when eslint fails' do
      allow(ARGV).to receive(:first).and_return('eslint')
      allow(instance).to receive(:run_eslint_for_changed_files).and_return(11)

      expect(instance.process_command_and_determine_exit_status).to eq(11)
    end

    it 'returns 1 for unknown commands' do
      allow(ARGV).to receive(:first).and_return('unknown')

      expect(instance.process_command_and_determine_exit_status).to eq(1)
    end
  end
end
