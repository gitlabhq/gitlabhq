# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../tooling/ci/changed_files'

RSpec.describe CI::ChangedFiles, feature_category: :tooling do
  let(:instance) { described_class.new }

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
    let(:changed_files_output) { ['file1.js', 'file2.rb', 'file3.vue'] }

    before do
      allow(instance).to receive(
        :get_changed_files_in_merged_results_pipeline).and_return(changed_files_output)
    end

    context 'when there are changed files' do
      context 'when filter value matches' do
        it 'returns filtered files' do
          expect(instance.filter_and_get_changed_files_in_mr(filter_pattern: /\.(js|vue)$/))
          .to match_array(['file1.js', 'file3.vue'])
        end

        it 'returns all files when filter is empty' do
          expect(instance.filter_and_get_changed_files_in_mr)
          .to match_array(changed_files_output)
        end
      end

      context 'when filter does not match' do
        let(:changed_files_output) { ['file1.txt', 'file2.rb'] }

        it 'returns empty array when no files match filter' do
          expect(instance.filter_and_get_changed_files_in_mr(filter_pattern: /\.(js|vue)$/)).to eq([])
        end
      end
    end

    context 'when there are no changed files' do
      let(:changed_files_output) { [] }

      it 'returns an empty array' do
        expect(instance.filter_and_get_changed_files_in_mr).to eq([])
      end
    end
  end

  describe '#run_eslint_for_changed_files' do
    let(:eslint_command) do
      ['yarn', 'run', 'lint:eslint', '--no-warn-ignored', '--format', 'gitlab', 'file1.js', 'file2.vue']
    end

    let(:console_message) { /Running ESLint for changed files.../i }

    context 'when there are changed files to lint' do
      let(:files) { ['file1.js', 'file2.vue'] }

      before do
        allow(instance).to receive(:filter_and_get_changed_files_in_mr).and_return(files)
      end

      it 'runs eslint with the correct arguments and returns exit 0 on success' do
        expect(instance).to receive(:system).with(*eslint_command).and_return(true)
        expect(instance).to receive(:puts).with(console_message)

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
      let(:no_files_msg) { /No files were changed. Skipping/i }

      it 'does not run eslint and returns exit code 0' do
        allow(instance).to receive(:filter_and_get_changed_files_in_mr).and_return([])

        expect(instance).to receive(:puts).with(console_message).ordered
        expect(instance).to receive(:puts).with(no_files_msg).ordered

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
