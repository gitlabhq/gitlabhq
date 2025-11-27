# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'tmpdir'
require 'open3'
require_relative '../../../scripts/lint/validate_fast_spec_helper_usage'

RSpec.describe Lint::ValidateFastSpecHelperUsage, :silence_stdout, feature_category: :tooling do
  describe '#initialize' do
    subject(:validator) { described_class.new(**kwargs) }

    context 'when target_branch is provided' do
      let(:target_branch) { 'master' }
      let(:kwargs) { { target_branch: target_branch } }

      it 'sets the target_branch' do
        expect(validator.target_branch).to eq(target_branch)
      end

      it 'initializes can_use_fast_helper as empty array' do
        expect(validator.can_use_fast_helper).to eq([])
      end
    end

    context 'when target_branch is not provided' do
      let(:kwargs) { {} }

      context 'when CI_MERGE_REQUEST_TARGET_BRANCH_NAME is set' do
        before do
          stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', 'main')
        end

        it 'uses the environment variable' do
          expect(validator.target_branch).to eq('main')
        end
      end

      context 'when CI_MERGE_REQUEST_TARGET_BRANCH_NAME is not set' do
        before do
          stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', nil)
        end

        it 'defaults to master' do
          expect(validator.target_branch).to eq('master')
        end
      end
    end
  end

  describe '#run' do
    subject(:run) { validator.run }

    let(:target_branch) { 'master' }
    let(:validator) { described_class.new(target_branch: target_branch) }
    let(:temp_dir) { Dir.mktmpdir }

    let(:spec_content_with_spec_helper) do
      <<~RUBY
        require 'spec_helper'

        RSpec.describe Example do
          it 'works' do
            expect(true).to be true
          end
        end
      RUBY
    end

    let(:spec_content_with_fast_spec_helper) do
      <<~RUBY
        require 'fast_spec_helper'

        RSpec.describe Example do
          it 'works' do
            expect(true).to be true
          end
        end
      RUBY
    end

    before do
      # Stub git commands to avoid actual git operations
      allow(Open3).to receive(:capture3).and_call_original
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context 'when no newly added spec files are found' do
      before do
        allow(Open3).to receive(:capture3)
          .with(/git diff.*--diff-filter=A/)
          .and_return(['', '', instance_double(Process::Status, success?: true)])
      end

      it { expect(silence_output { run }).to be true }

      it 'prints success message' do
        stdout, _stderr, _result = capture_output { run }
        expect(stdout).to include('No newly added spec files found')
      end
    end

    context 'when git command fails' do
      before do
        allow(Open3).to receive(:capture3)
          .with(/git diff.*--diff-filter=A/)
          .and_return(['', 'fatal: bad revision', instance_double(Process::Status, success?: false)])
      end

      it { expect(silence_output { run }).to be true }

      it 'prints warning message' do
        _stdout, stderr, _result = capture_output { run }
        expect(stderr).to include('Warning: git diff command failed')
      end
    end

    context 'when newly added spec files use fast_spec_helper' do
      let(:spec_file) { File.join(temp_dir, 'new_spec.rb') }

      before do
        File.write(spec_file, spec_content_with_fast_spec_helper)

        allow(Open3).to receive(:capture3)
          .with(/git diff.*--diff-filter=A/)
          .and_return([spec_file, '', instance_double(Process::Status, success?: true)])
      end

      it { expect(silence_output { run }).to be true }

      it 'prints success message' do
        stdout, _stderr, _result = capture_output { run }
        expect(stdout).to include('No newly added spec files using spec_helper found')
      end
    end

    context 'when git reports files that do not exist on filesystem' do
      let(:nonexistent_file) { File.join(temp_dir, 'nonexistent_spec.rb') }

      before do
        allow(Open3).to receive(:capture3)
          .with(/git diff.*--diff-filter=A/)
          .and_return([nonexistent_file, '', instance_double(Process::Status, success?: true)])
      end

      it { expect(silence_output { run }).to be true }

      it 'skips nonexistent files and prints success message' do
        stdout, _stderr, _result = capture_output { run }
        expect(stdout).to include('No newly added spec files using spec_helper found')
      end
    end

    context 'when newly added spec files require spec_helper and cannot use fast_spec_helper' do
      let(:spec_file) { File.join(temp_dir, 'new_spec.rb') }

      before do
        File.write(spec_file, spec_content_with_spec_helper)

        allow(Open3).to receive(:capture3)
          .with(/git diff.*--diff-filter=A/)
          .and_return([spec_file, '', instance_double(Process::Status, success?: true)])

        # Simulate rspec failing with fast_spec_helper
        allow(Open3).to receive(:capture3)
          .with(/bundle exec rspec.*/)
          .and_return(['1 example, 1 failure', '', instance_double(Process::Status, success?: false)])
      end

      it { expect(silence_output { run }).to be true }

      it 'prints success message' do
        stdout, _stderr, _result = capture_output { run }
        expect(stdout).to include('VALIDATION PASSED')
      end
    end

    context 'when newly added spec files use spec_helper but can use fast_spec_helper' do
      let(:spec_file) { File.join(temp_dir, 'new_spec.rb') }

      before do
        File.write(spec_file, spec_content_with_spec_helper)

        allow(Open3).to receive(:capture3)
          .with(/git diff.*--diff-filter=A/)
          .and_return([spec_file, '', instance_double(Process::Status, success?: true)])

        # Simulate rspec passing with fast_spec_helper
        allow(Open3).to receive(:capture3)
          .with(/bundle exec rspec.*/)
          .and_return(['1 example, 0 failures', '', instance_double(Process::Status, success?: true)])
      end

      it { expect(silence_output { run }).to be false }

      it 'prints failure message with file list' do
        stdout, _stderr, _result = capture_output { run }
        expect(stdout).to include('VALIDATION FAILED')
        expect(stdout).to include(spec_file)
        expect(stdout).to include('fast_spec_helper')
        expect(stdout).to include('Action required')
      end

      it 'populates can_use_fast_helper array' do
        silence_output { run }

        expect(validator.can_use_fast_helper).to include(spec_file)
      end
    end

    context 'when multiple spec files are added with mixed requirements' do
      let(:spec_can_use_fast) { File.join(temp_dir, 'can_use_fast_spec.rb') }
      let(:spec_requires_full) { File.join(temp_dir, 'requires_full_spec.rb') }
      let(:spec_already_fast) { File.join(temp_dir, 'already_fast_spec.rb') }

      before do
        File.write(spec_can_use_fast, spec_content_with_spec_helper)
        File.write(spec_requires_full, spec_content_with_spec_helper)
        File.write(spec_already_fast, spec_content_with_fast_spec_helper)

        git_output = [spec_can_use_fast, spec_requires_full, spec_already_fast].join("\n")
        allow(Open3).to receive(:capture3)
          .with(/git diff.*--diff-filter=A/)
          .and_return([git_output, '', instance_double(Process::Status, success?: true)])

        # Simulate different rspec results for different files
        allow(Open3).to receive(:capture3).with(/bundle exec rspec.*/) do |cmd|
          if cmd.include?(spec_can_use_fast)
            ['1 example, 0 failures', '', instance_double(Process::Status, success?: true)]
          else
            ['1 example, 1 failure', '', instance_double(Process::Status, success?: false)]
          end
        end
      end

      it 'returns false when at least one file can use fast_spec_helper' do
        expect(silence_output { run }).to be false
      end

      it 'only lists files that can use fast_spec_helper in the failure list' do
        stdout, _stderr, _result = capture_output { run }

        # Check that the file is listed in the "can use fast_spec_helper" section
        failure_section = stdout.split('VALIDATION FAILED').last
        expect(failure_section).to include(spec_can_use_fast)
        expect(failure_section).not_to include(spec_already_fast)
      end

      it 'populates can_use_fast_helper with only convertible files' do
        silence_output { run }

        expect(validator.can_use_fast_helper).to contain_exactly(spec_can_use_fast)
      end
    end

    context 'when FROM_LEFTHOOK is set' do
      let(:spec_file) { File.join(temp_dir, 'new_spec.rb') }

      before do
        stub_env('FROM_LEFTHOOK', '1')
        File.write(spec_file, spec_content_with_spec_helper)

        allow(Open3).to receive(:capture3)
          .with(/git diff.*--diff-filter=A/)
          .and_return([spec_file, '', instance_double(Process::Status, success?: true)])
      end

      context 'when validation passes' do
        before do
          # Simulate rspec failing with fast_spec_helper (requires spec_helper)
          allow(Open3).to receive(:capture3)
            .with(/bundle exec rspec.*/)
            .and_return(['1 example, 1 failure', '', instance_double(Process::Status, success?: false)])
        end

        it 'is expected to equal true' do
          stdout, _stderr, result = capture_output { run }
          expect(result).to be true
          expect(stdout).to be_empty
        end

        it 'produces no output' do
          stdout, _stderr, _result = capture_output { run }
          expect(stdout).to be_empty
        end
      end

      context 'when validation fails' do
        before do
          # Simulate rspec passing with fast_spec_helper
          allow(Open3).to receive(:capture3)
            .with(/bundle exec rspec.*/)
            .and_return(['1 example, 0 failures', '', instance_double(Process::Status, success?: true)])
        end

        it { expect(silence_output { run }).to be false }

        it 'shows failure message without verbose headers' do
          stdout, _stderr, _result = capture_output { run }

          # Should show the failure information
          expect(stdout).to include('VALIDATION FAILED')
          expect(stdout).to include(spec_file)
          expect(stdout).to include('fast_spec_helper')

          # Should NOT show verbose progress messages
          expect(stdout).not_to include('Validating newly added specs')
          expect(stdout).not_to include('Finding newly added spec files')
          expect(stdout).not_to include('Testing')
        end
      end

      context 'when no spec files are found' do
        before do
          allow(Open3).to receive(:capture3)
            .with(/git diff.*--diff-filter=A/)
            .and_return(['', '', instance_double(Process::Status, success?: true)])
        end

        it 'is expected to equal true' do
          stdout, _stderr, result = capture_output { run }
          expect(result).to be true
          expect(stdout).to be_empty
        end

        it 'produces no output' do
          stdout, _stderr, _result = capture_output { run }
          expect(stdout).to be_empty
        end
      end

      context 'when no spec_helper files are found' do
        let(:spec_file) { File.join(temp_dir, 'new_spec.rb') }

        before do
          File.write(spec_file, spec_content_with_fast_spec_helper)

          allow(Open3).to receive(:capture3)
            .with(/git diff.*--diff-filter=A/)
            .and_return([spec_file, '', instance_double(Process::Status, success?: true)])
        end

        it 'is expected to equal true' do
          stdout, _stderr, result = capture_output { run }
          expect(result).to be true
          expect(stdout).to be_empty
        end

        it 'produces no output' do
          stdout, _stderr, _result = capture_output { run }
          expect(stdout).to be_empty
        end
      end
    end
  end

  private

  def capture_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    result = yield
    [$stdout.string, $stderr.string, result]
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def silence_output
    _stdout, _stderr, result = capture_output { yield }
    result
  end
end
