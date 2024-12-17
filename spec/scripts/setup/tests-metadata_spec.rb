# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require_relative '../../../scripts/setup/tests-metadata'

# rubocop:disable Gitlab/Json, Lint/MissingCopEnableDirective -- It's not intended to have extra dependency

RSpec.describe TestsMetadata, feature_category: :tooling do # rubocop:disable RSpec/SpecFilePathFormat -- We use dashes in scripts
  subject(:metadata) do
    described_class.new(
      mode: mode,
      knapsack_report_path: knapsack_report_path,
      flaky_report_path: flaky_report_path,
      fast_quarantine_path: fast_quarantine_path,
      average_knapsack: average_knapsack)
  end

  let(:average_knapsack) { true }
  let(:knapsack_report_path) { 'knapsack_report/path' }
  let(:flaky_report_path) { 'flaky_report/path' }
  let(:fast_quarantine_path) { 'fast_quarantine/path' }
  let(:aborted) { StandardError.new }

  describe '#main' do
    context 'when mode is retrieve' do
      let(:mode) { 'retrieve' }

      it 'calls prepare_directories and retrieve' do
        expect(metadata).to receive(:prepare_directories)
        expect(metadata).to receive(:retrieve)
        expect(metadata).not_to receive(:update)
        expect(metadata).not_to receive(:verify)

        metadata.main
      end
    end

    context 'when mode is update' do
      let(:mode) { 'update' }

      it 'calls prepare_directories and retrieve and update' do
        expect(metadata).to receive(:prepare_directories)
        expect(metadata).to receive(:retrieve)
        expect(metadata).to receive(:update)
        expect(metadata).not_to receive(:verify)

        metadata.main
      end
    end

    context 'when mode is verify' do
      let(:mode) { 'verify' }

      it 'calls prepare_directories and retrieve and update' do
        expect(metadata).not_to receive(:prepare_directories)
        expect(metadata).not_to receive(:retrieve)
        expect(metadata).not_to receive(:update)
        expect(metadata).to receive(:verify)

        metadata.main
      end
    end
  end

  describe '#prepare_directories' do
    let(:mode) { 'retrieve' }

    it 'prepares the directories' do
      expect(FileUtils).to receive(:mkdir_p).with([
        File.dirname(knapsack_report_path),
        File.dirname(flaky_report_path),
        File.dirname(fast_quarantine_path)
      ])

      metadata.__send__(:prepare_directories)
    end
  end

  shared_context 'with fake reports' do
    let(:knapsack_report_path) { knapsack_report_file.path }
    let(:flaky_report_path) { flaky_report_file.path }
    let(:fast_quarantine_path) { fast_quarantine_file.path }

    let(:knapsack_report_file) { tempfile_write('knapsack', knapsack_report) }
    let(:flaky_report_file) { tempfile_write('flaky', flaky_report) }
    let(:fast_quarantine_file) { tempfile_write('fast_quarantine', fast_quarantine_report) }

    let(:knapsack_report) { json_report }
    let(:flaky_report) { json_report }
    let(:fast_quarantine_report) { text_report }

    let(:json_report) { '{"valid":"json"}' }
    let(:text_report) { 'This is an apple' }

    after do
      [knapsack_report_file, flaky_report_file, fast_quarantine_file]
        .each(&:unlink)
    end

    def tempfile_write(path, content)
      file = Tempfile.new(path)
      file.write(content)
      file.close
      file
    end
  end

  describe '#retrieve' do
    include_context 'with fake reports'

    let(:mode) { 'retrieve' }
    let(:expect_curl) { true }
    let(:curl_knapsack_return) { true }
    let(:curl_flaky_report_return) { true }
    let(:curl_fast_quarantine_return) { true }

    before do
      expect_system_curl
    end

    def expect_system_curl
      expect_system_curl_with(%W[
        curl --fail --location -o #{knapsack_report_path} https://gitlab-org.gitlab.io/gitlab/#{knapsack_report_path}
      ], curl_knapsack_return)

      expect_system_curl_with(%W[
        curl --fail --location -o #{flaky_report_path} https://gitlab-org.gitlab.io/gitlab/#{flaky_report_path}
      ], curl_flaky_report_return)

      expect_system_curl_with(%W[
        curl --fail --location -o #{fast_quarantine_path} https://gitlab-org.gitlab.io/quality/engineering-productivity/fast-quarantine/#{fast_quarantine_path}
      ], curl_fast_quarantine_return)
    end

    def expect_system_curl_with(arguments, curl_return)
      to =
        if expect_curl
          :to
        else
          :not_to
        end

      expectation =
        expect(metadata).public_send(to, receive(:system)).with(*arguments) # rubocop:disable RSpec/MissingExpectationTargetMethod -- it's dynamic

      expectation.and_return(curl_return) if expect_curl
    end

    it 'downloads the metadata and parse it respectively' do
      metadata.__send__(:retrieve)

      expect(File.read(knapsack_report_path)).to eq(json_report)
      expect(File.read(flaky_report_path)).to eq(json_report)
      expect(File.read(fast_quarantine_path)).to eq(text_report)
    end

    context 'when JSON report we download is invalid' do
      let(:json_report) { 'This is a bad JSON' }

      it 'writes a fallback JSON file instead of using invalid JSON' do
        metadata.__send__(:retrieve)

        expect(File.read(knapsack_report_path)).to eq(described_class::FALLBACK_JSON)
        expect(File.read(flaky_report_path)).to eq(described_class::FALLBACK_JSON)
        expect(File.read(fast_quarantine_path)).to eq(text_report)
      end
    end

    context 'when fast quarantine report failed to download' do
      let(:curl_fast_quarantine_return) { false }

      it 'writes a fallback file with fallback content' do
        metadata.__send__(:retrieve)

        expect(File.read(fast_quarantine_path)).to eq('')
      end
    end

    context 'when it is update mode' do
      let(:mode) { 'update' }
      let(:expect_curl) { false }

      it 'does not download tests metadata via curl' do # rubocop:disable RSpec/NoExpectationExample -- set in before already, see expect_system_curl_with
        metadata.__send__(:retrieve)
      end
    end
  end

  describe '#update' do
    let(:mode) { 'update' }

    it 'updates all reports' do
      expect(metadata).to receive(:update_knapsack_report)
      expect(metadata).to receive(:update_flaky_report)
      expect(metadata).to receive(:prune_flaky_report)

      metadata.__send__(:update)
    end
  end

  describe '#update_knapsack_report' do
    include_context 'with fake reports'

    let(:mode) { 'update' }
    let(:knapsack_report_dir) { File.dirname(knapsack_report_path) }

    let(:individual_knapsack_reports) do
      %W[
        #{knapsack_report_dir}/rspec-0.json
        #{knapsack_report_dir}/rspec-1.json
      ]
    end

    before do
      allow(Dir).to receive(:[]).with("#{knapsack_report_dir}/rspec*.json")
        .and_return(individual_knapsack_reports)
    end

    it 'updates knapsack report' do
      expect(metadata).to receive(:system).with(
        'scripts/pipeline/average_reports.rb',
        '-i', knapsack_report_path,
        '-n', individual_knapsack_reports.join(',')
      ).and_return(true)

      metadata.__send__(:update_knapsack_report)
    end

    context 'when scripts/pipeline/average_reports.rb failed' do
      it 'aborts the process' do
        expect(metadata).to receive(:system).with(
          'scripts/pipeline/average_reports.rb',
          '-i', knapsack_report_path,
          '-n', individual_knapsack_reports.join(',')
        ).and_return(false)

        expect(metadata).to receive(:abort)

        metadata.__send__(:update_knapsack_report)
      end
    end

    context 'when average_knapsack is false' do
      let(:average_knapsack) { false }

      it 'uses scripts/merge-reports to merge reports instead' do
        expect(metadata).to receive(:system).with(
          'scripts/merge-reports',
          knapsack_report_path,
          individual_knapsack_reports.join(' ')
        ).and_return(true)

        metadata.__send__(:update_knapsack_report)
      end

      context 'when scripts/merge-reports failed' do
        it 'aborts the process' do
          expect(metadata).to receive(:system).with(
            'scripts/merge-reports',
            knapsack_report_path,
            individual_knapsack_reports.join(' ')
          ).and_return(false)

          expect(metadata).to receive(:abort)

          metadata.__send__(:update_knapsack_report)
        end
      end
    end
  end

  describe '#update_flaky_report' do
    include_context 'with fake reports'

    let(:mode) { 'update' }
    let(:flaky_report_dir) { File.dirname(flaky_report_path) }

    let(:individual_flaky_reports) do
      %W[
        #{flaky_report_dir}/all_0.json
        #{flaky_report_dir}/all_1.json
      ]
    end

    before do
      allow(Dir).to receive(:[]).with("#{flaky_report_dir}/all_*.json")
        .and_return(individual_flaky_reports)
    end

    it 'updates flaky report' do
      expect(metadata).to receive(:system).with(
        'scripts/merge-reports',
        flaky_report_path,
        individual_flaky_reports.join(' ')
      ).and_return(true)

      metadata.__send__(:update_flaky_report)
    end

    context 'when scripts/merge-reports failed' do
      it 'aborts the process' do
        expect(metadata).to receive(:system).with(
          'scripts/merge-reports',
          flaky_report_path,
          individual_flaky_reports.join(' ')
        ).and_return(false)

        expect(metadata).to receive(:abort).and_raise(aborted)

        expect do
          metadata.__send__(:update_flaky_report)
        end.to raise_error(aborted)
      end
    end
  end

  describe '#prune_flaky_report' do
    include_context 'with fake reports'

    let(:mode) { 'update' }
    let(:flaky_report_dir) { File.dirname(flaky_report_path) }

    it 'prunes flaky report' do
      expect(metadata).to receive(:system).with(
        'scripts/flaky_examples/prune-old-flaky-examples',
        flaky_report_path
      ).and_return(true)

      metadata.__send__(:prune_flaky_report)
    end

    context 'when scripts/flaky_examples/prune-old-flaky-examples failed' do
      it 'aborts the process' do
        expect(metadata).to receive(:system).with(
          'scripts/flaky_examples/prune-old-flaky-examples',
          flaky_report_path
        ).and_return(false)

        expect(metadata).to receive(:abort)

        metadata.__send__(:prune_flaky_report)
      end
    end
  end

  describe '#verify' do
    include_context 'with fake reports'

    shared_examples 'fail verification and abort' do
      it 'calls abort to fail the verification' do
        expect(metadata).to receive(:abort).and_raise(aborted)

        expect do
          metadata.__send__(:verify)
        end.to raise_error(aborted)
      end
    end

    let(:mode) { 'verify' }

    let(:knapsack_report) { JSON.dump({ __FILE__ => 123.456 }) }

    let(:flaky_report) do
      <<~JSON
        {
          "fa1659e83e918bab8cb80518ea5f80f4": {
            "first_flaky_at": "2023-12-07 14:21:34 +0000",
            "last_flaky_at": "2024-09-02 22:18:36 +0000",
            "last_flaky_job": "https://gitlab.com/gitlab-org/gitlab/-/jobs/7724274859",
            "last_attempts_count": 2,
            "flaky_reports": 954,
            "feature_category": "integrations",
            "example_id": "./spec/features/projects/integrations/user_activates_issue_tracker_spec.rb[1:4:1:2:1]",
            "file": "./spec/features/projects/integrations/user_activates_issue_tracker_spec.rb",
            "line": 49,
            "description": "User activates issue tracker behaves like external issue tracker activation user sets and activates the integration when the connection test fails activates the integration"
          }
        }
      JSON
    end

    let(:fast_quarantine_report) do
      <<~TEXT
        qa/specs/features/ee/browser_ui/3_create/remote_development/workspace_actions_spec.rb
        spec/features/work_items/work_item_detail_spec.rb:67
      TEXT
    end

    it 'validates reports are valid' do
      expect { metadata.__send__(:verify) }.to output("OK\n").to_stdout
    end

    context 'when knapsack report has type error' do
      let(:knapsack_report) { JSON.dump({ __FILE__ => '123.456' }) }

      it_behaves_like 'fail verification and abort'
    end

    context 'when knapsack report is not valid JSON' do
      let(:knapsack_report) { { __FILE__ => 123.456 }.to_s }

      it_behaves_like 'fail verification and abort'
    end

    context 'when flaky report is not valid JSON' do
      let(:flaky_report) { 'This is an apple' }

      it_behaves_like 'fail verification and abort'
    end

    context 'when fast quarantine report is not valid',
      skip: 'This is not possible because it is always considered valid'
  end
end
