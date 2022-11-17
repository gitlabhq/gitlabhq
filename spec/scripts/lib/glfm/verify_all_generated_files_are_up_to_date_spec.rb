# frozen_string_literal: true
require 'fast_spec_helper'
require_relative '../../../../scripts/lib/glfm/verify_all_generated_files_are_up_to_date'

# IMPORTANT NOTE: See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#verify-all-generated-files-are-up-to-daterb-script
# for details on the implementation and usage of the `verify_all_generated_files_are_up_to_date.rb` script being tested.
# This developers guide contains diagrams and documentation of the script,
# including explanations and examples of all files it reads and writes.
RSpec.describe Glfm::VerifyAllGeneratedFilesAreUpToDate, '#process' do
  subject { described_class.new }

  let(:output_path) { described_class::GLFM_OUTPUT_SPEC_PATH }
  let(:snapshots_path) { described_class::ES_OUTPUT_EXAMPLE_SNAPSHOTS_PATH }
  let(:verify_cmd) { "git status --porcelain #{output_path} #{snapshots_path}" }

  before do
    # Prevent console output when running tests
    allow(subject).to receive(:output)
  end

  context 'when repo is dirty' do
    before do
      # Simulate a dirty repo
      allow(subject).to receive(:run_external_cmd).with(verify_cmd).and_return(" M #{output_path}")
    end

    it 'raises an error', :unlimited_max_formatted_output_length do
      expect { subject.process }.to raise_error(/Cannot run.*uncommitted changes.*#{output_path}/m)
    end
  end

  context 'when repo is clean' do
    before do
      # Mock out all yarn install and script execution
      allow(subject).to receive(:run_external_cmd).with('yarn install --frozen-lockfile')
      allow(subject).to receive(:run_external_cmd).with(/update-specification.rb/)
      allow(subject).to receive(:run_external_cmd).with(/update-example-snapshots.rb/)
    end

    context 'when all generated files are up to date' do
      before do
        # Simulate a clean repo, then simulate no changes to generated files
        allow(subject).to receive(:run_external_cmd).twice.with(verify_cmd).and_return('', '')
      end

      it 'does not raise an error', :unlimited_max_formatted_output_length do
        expect { subject.process }.not_to raise_error
      end
    end

    context 'when generated file(s) are not up to date' do
      before do
        # Simulate a clean repo, then simulate changes to generated files
        allow(subject).to receive(:run_external_cmd).twice.with(verify_cmd).and_return('', "M #{snapshots_path}")
        allow(subject).to receive(:run_external_cmd).with('git diff')
        allow(subject).to receive(:warn).and_call_original
      end

      it 'raises an error', :unlimited_max_formatted_output_length do
        expect(subject).to receive(:warn).with(/following files were modified.*#{snapshots_path}/m)
        expect { subject.process }.to raise_error(/The generated files are not up to date/)
      end
    end
  end
end
