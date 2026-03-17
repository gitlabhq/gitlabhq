# frozen_string_literal: true

require "fast_spec_helper"

require_relative '../../../../../tooling/lib/tooling/predictive_tests/duo_test_selector'

RSpec.describe Tooling::PredictiveTests::DuoTestSelector, feature_category: :tooling do
  subject(:selector) do
    described_class.new(git_diff: git_diff, changed_files: changed_files, logger: logger)
  end

  let(:logger) { Logger.new(StringIO.new) }

  let(:git_diff) do
    <<~DIFF
      diff --git a/app/views/projects/show.html.haml b/app/views/projects/show.html.haml
      index abc123..def456 100644
      --- a/app/views/projects/show.html.haml
      +++ b/app/views/projects/show.html.haml
      @@ -5,0 +6,1 @@
      +.project-title= @project.name
    DIFF
  end

  let(:changed_files) { %w[app/models/user.rb app/views/users/show.html.haml] }

  # Stub Duo CLI and the output file for tests that exercise the full flow
  def stub_duo_cli_success(json)
    allow(Open3).to receive(:capture2e).and_return(
      ['duo cli output', instance_double(Process::Status, success?: true, exitstatus: 0)]
    )
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(described_class::DUO_OUTPUT_FILE).and_return(true)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(described_class::DUO_OUTPUT_FILE).and_return(Gitlab::Json.generate(json))
  end

  def stub_duo_cli_failure
    allow(Open3).to receive(:capture2e).and_return(
      ['duo: command not found', instance_double(Process::Status, success?: false, exitstatus: 127)]
    )
  end

  def stub_duo_output_file_missing
    allow(Open3).to receive(:capture2e).and_return(
      ['duo cli output', instance_double(Process::Status, success?: true, exitstatus: 0)]
    )
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(described_class::DUO_OUTPUT_FILE).and_return(false)
  end

  describe '#select_tests' do
    subject(:select_tests) { selector.select_tests }

    context 'when no git diff is available' do
      let(:git_diff) { nil }

      before do
        allow(selector).to receive(:get_git_diff).and_return(nil)
      end

      it 'returns fallback result with no specs' do
        expect(select_tests).to include(
          confidence: 0.0,
          specs: [],
          reasoning: 'No git diff'
        )
      end
    end

    context 'when git diff is empty' do
      let(:git_diff) { '' }

      it 'returns fallback result' do
        expect(select_tests).to include(
          confidence: 0.0,
          specs: [],
          reasoning: 'No git diff'
        )
      end
    end

    context 'when change exceeds file limit' do
      let(:changed_files) { (1..51).map { |i| "file#{i}.rb" } }
      let(:git_diff) do
        (1..51).map { |i| "diff --git a/file#{i}.rb b/file#{i}.rb\n+++ b/file#{i}.rb\n+change\n" }.join("\n")
      end

      it 'returns low confidence result' do
        expect(select_tests).to include(confidence: 0.0, specs: [])
        expect(select_tests[:reasoning]).to include('exceeds limit')
        expect(select_tests[:changed_files].length).to eq(51)
      end
    end

    context 'when diff exceeds line limit' do
      let(:changed_files) { ['large.rb'] }
      let(:git_diff) do
        header = "diff --git a/large.rb b/large.rb\n+++ b/large.rb\n"
        lines = (1..5500).map { |i| "+line #{i}\n" }.join
        "#{header}#{lines}"
      end

      it 'returns low confidence result' do
        expect(select_tests).to include(confidence: 0.0, specs: [])
        expect(select_tests[:reasoning]).to include('exceeds limit')
      end
    end

    context 'when Duo CLI is not available' do
      before do
        stub_duo_cli_failure
      end

      it 'returns fallback result' do
        expect(select_tests).to include(
          confidence: 0.0,
          specs: [],
          reasoning: 'Duo CLI failed'
        )
      end
    end

    context 'when Duo CLI succeeds' do
      before do
        stub_duo_cli_success(
          confidence: 0.9,
          directories: ['spec/features/projects'],
          individual_files: [],
          reasoning: 'Found project view changes'
        )
        allow(Dir).to receive(:glob).with('spec/features/projects/**/*_spec.rb').and_return(
          ['spec/features/projects/show_spec.rb', 'spec/features/projects/edit_spec.rb']
        )
      end

      it 'returns successful result with specs' do
        expect(select_tests).to include(
          confidence: 0.9,
          reasoning: 'Found project view changes'
        )
        expect(select_tests[:specs]).to contain_exactly(
          'spec/features/projects/show_spec.rb',
          'spec/features/projects/edit_spec.rb'
        )
      end
    end

    context 'when Duo returns high confidence with no specs' do
      before do
        stub_duo_cli_success(
          confidence: 0.95,
          directories: [],
          individual_files: [],
          reasoning: 'Documentation change only'
        )
      end

      it 'returns high confidence with empty specs array' do
        expect(select_tests).to include(
          confidence: 0.95,
          specs: [],
          reasoning: 'Documentation change only'
        )
      end
    end

    context 'when duo_feature_specs.json is not written by Duo' do
      before do
        stub_duo_output_file_missing
      end

      it 'returns fallback result' do
        expect(select_tests).to include(
          confidence: 0.0,
          specs: [],
          reasoning: 'Failed to parse Duo response'
        )
      end
    end

    context 'when duo_feature_specs.json contains invalid JSON' do
      before do
        allow(Open3).to receive(:capture2e).and_return(
          ['duo cli output', instance_double(Process::Status, success?: true, exitstatus: 0)]
        )
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(described_class::DUO_OUTPUT_FILE).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(described_class::DUO_OUTPUT_FILE).and_return('not valid json')
      end

      it 'returns fallback result' do
        expect(select_tests).to include(
          confidence: 0.0,
          specs: [],
          reasoning: 'Failed to parse Duo response'
        )
      end
    end

    context 'when DUO_TEST_SELECTION_TOKEN is not set' do
      before do
        stub_env('DUO_TEST_SELECTION_TOKEN', nil)
        stub_duo_cli_failure
      end

      it 'falls back gracefully without token' do
        expect(selector.select_tests).to include(confidence: 0.0, specs: [])
      end
    end

    context 'when Duo CLI output is empty' do
      before do
        allow(Open3).to receive(:capture2e).and_return(
          ['', instance_double(Process::Status, success?: true, exitstatus: 0)]
        )
      end

      it 'returns fallback result' do
        expect(selector.select_tests).to include(confidence: 0.0, specs: [])
      end
    end

    context 'when duo_feature_specs.json is empty' do
      before do
        allow(Open3).to receive(:capture2e).and_return(
          ['output', instance_double(Process::Status, success?: true, exitstatus: 0)]
        )
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(described_class::DUO_OUTPUT_FILE).and_return(true)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(described_class::DUO_OUTPUT_FILE).and_return('   ')
      end

      it 'returns fallback result' do
        expect(selector.select_tests).to include(confidence: 0.0, specs: [])
      end
    end
  end

  describe '#extract_changed_files' do
    subject(:extract_changed_files) { selector.send(:extract_changed_files, diff) }

    let(:diff) { git_diff }

    it 'extracts file paths from diff' do
      expect(extract_changed_files).to eq(['app/views/projects/show.html.haml'])
    end

    context 'with multiple files' do
      let(:diff) do
        <<~DIFF
          diff --git a/app/models/user.rb b/app/models/user.rb
          +++ b/app/models/user.rb
          diff --git a/app/views/users/show.html.haml b/app/views/users/show.html.haml
          +++ b/app/views/users/show.html.haml
        DIFF
      end

      it 'extracts all file paths' do
        expect(extract_changed_files).to contain_exactly(
          'app/models/user.rb',
          'app/views/users/show.html.haml'
        )
      end
    end
  end

  describe '#expand_to_specs' do
    subject(:expand_to_specs) { selector.send(:expand_to_specs, directories, individual_files) }

    let(:directories) { [] }
    let(:individual_files) { [] }

    before do
      allow(Dir).to receive(:glob).with('spec/features/projects/**/*_spec.rb').and_return(
        ['spec/features/projects/show_spec.rb', 'spec/features/projects/settings_spec.rb']
      )
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('spec/features/users/profile_spec.rb').and_return(true)
      allow(File).to receive(:exist?).with('spec/features/nonexistent_spec.rb').and_return(false)
    end

    context 'when expanding directories' do
      let(:directories) { ['spec/features/projects'] }

      it 'expands directories to spec files recursively' do
        expect(expand_to_specs).to contain_exactly(
          'spec/features/projects/show_spec.rb',
          'spec/features/projects/settings_spec.rb'
        )
      end
    end

    context 'when including individual files' do
      let(:individual_files) { ['spec/features/users/profile_spec.rb'] }

      it 'includes individual files that exist' do
        expect(expand_to_specs).to eq(['spec/features/users/profile_spec.rb'])
      end
    end

    context 'when individual file does not exist' do
      let(:individual_files) { ['spec/features/nonexistent_spec.rb'] }

      it 'filters out non-existent files' do
        expect(expand_to_specs).to be_empty
      end
    end

    context 'when directory contains non-feature specs' do
      let(:directories) { ['spec/models'] }

      before do
        allow(Dir).to receive(:glob).with('spec/models/**/*_spec.rb').and_return(['spec/models/user_spec.rb'])
      end

      it 'filters out non-feature specs' do
        expect(expand_to_specs).to be_empty
      end
    end

    context 'when specs appear in both directories and individual files' do
      let(:directories) { ['spec/features/projects'] }
      let(:individual_files) { ['spec/features/projects/show_spec.rb'] }

      before do
        allow(File).to receive(:exist?).with('spec/features/projects/show_spec.rb').and_return(true)
      end

      it 'deduplicates specs' do
        expect(expand_to_specs.count('spec/features/projects/show_spec.rb')).to eq(1)
      end
    end
  end

  describe '#validate_response' do
    subject(:validate_response) { selector.send(:validate_response, result) }

    context 'when response is valid' do
      let(:result) { { confidence: 0.9, directories: [], individual_files: [], reasoning: 'test' } }

      it 'returns the result unchanged' do
        expect(validate_response).to eq(result)
      end
    end

    context 'when directories is not an array' do
      let(:result) { { confidence: 0.9, directories: 'not_an_array', individual_files: [] } }

      it 'returns nil' do
        expect(validate_response).to be_nil
      end
    end

    context 'when individual_files is not an array' do
      let(:result) { { confidence: 0.9, directories: [], individual_files: 'not_an_array' } }

      it 'returns nil' do
        expect(validate_response).to be_nil
      end
    end

    context 'when .rb files are incorrectly in directories array' do
      let(:result) do
        {
          confidence: 0.9,
          directories: ['spec/features/projects', 'spec/features/users/profile_spec.rb'],
          individual_files: []
        }
      end

      it 'moves .rb files from directories to individual_files' do
        validated = validate_response

        expect(validated[:directories]).to eq(['spec/features/projects'])
        expect(validated[:individual_files]).to eq(['spec/features/users/profile_spec.rb'])
      end
    end
  end

  describe 'with injected git_diff' do
    it 'uses injected diff instead of calling get_git_diff' do
      allow(selector).to receive(:get_git_diff)
      allow(selector).to receive(:call_duo_cli).and_return(nil)

      selector.select_tests

      expect(selector).not_to have_received(:get_git_diff)
    end
  end
end
