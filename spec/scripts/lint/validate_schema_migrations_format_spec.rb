# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require 'tmpdir'
require 'digest'

# Load the script under test
load File.expand_path('../../../scripts/lint/validate_schema_migrations_format.rb', __dir__)

RSpec.describe 'validate_schema_migrations_format', feature_category: :tooling do
  let(:temp_dir) { Dir.mktmpdir }
  let(:schema_migrations_dir) { File.join(temp_dir, 'db', 'schema_migrations') }
  let(:git_diff_output) { '' }

  before do
    FileUtils.mkdir_p(schema_migrations_dir)
    stub_const('SCHEMA_MIGRATIONS_DIR', schema_migrations_dir)
    # rubocop:disable RSpec/AnyInstanceOf -- needed to stub backtick at top level
    allow_any_instance_of(Object).to receive(:`).with(/git diff/).and_return(git_diff_output)
    # rubocop:enable RSpec/AnyInstanceOf
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_migration_file(version, content)
    File.write(File.join(schema_migrations_dir, version), content)
  end

  def correct_hash_for(version)
    Digest::SHA256.hexdigest(version)
  end

  describe 'VERSION_PATTERN' do
    it 'matches valid migration versions' do
      expect(VERSION_PATTERN).to match('20260506120000')
      expect(VERSION_PATTERN).to match('20210101000000')
    end

    it 'does not match invalid versions' do
      expect(VERSION_PATTERN).not_to match('not_a_version')
      expect(VERSION_PATTERN).not_to match('2026050612000')
      expect(VERSION_PATTERN).not_to match('202605061200001')
      expect(VERSION_PATTERN).not_to match('19990101000000')
    end
  end

  describe '#main' do
    subject(:run_main) { capture_output { main } }

    context 'when no staged files exist' do
      let(:git_diff_output) { '' }

      it 'returns 0' do
        _stdout, exit_code = run_main
        expect(exit_code).to eq(0)
      end
    end

    context 'when staged files are correctly formatted' do
      let(:version) { '20260506120000' }
      let(:git_diff_output) { "#{schema_migrations_dir}/#{version}\n" }

      before do
        create_migration_file(version, correct_hash_for(version))
      end

      it 'returns 0' do
        _stdout, exit_code = run_main
        expect(exit_code).to eq(0)
      end
    end

    context 'when a staged file has a trailing newline' do
      let(:version) { '20260506120000' }
      let(:git_diff_output) { "#{schema_migrations_dir}/#{version}\n" }

      before do
        create_migration_file(version, "#{correct_hash_for(version)}\n")
      end

      it 'returns 1' do
        _stdout, exit_code = run_main
        expect(exit_code).to eq(1)
      end

      it 'reports the trailing newline error' do
        stdout, _exit_code = run_main
        expect(stdout).to include('has trailing newline')
        expect(stdout).to include(version)
      end

      it 'provides a fix command' do
        stdout, _exit_code = run_main
        expect(stdout).to include('printf')
      end
    end

    context 'when a staged file has incorrect hash' do
      let(:version) { '20260506120000' }
      let(:git_diff_output) { "#{schema_migrations_dir}/#{version}\n" }

      before do
        create_migration_file(version, 'incorrect_hash_value')
      end

      it 'returns 1' do
        _stdout, exit_code = run_main
        expect(exit_code).to eq(1)
      end

      it 'reports the incorrect hash error' do
        stdout, _exit_code = run_main
        expect(stdout).to include('has incorrect hash')
      end
    end

    context 'when a staged file has both trailing newline and incorrect hash' do
      let(:version) { '20260506120000' }
      let(:git_diff_output) { "#{schema_migrations_dir}/#{version}\n" }

      before do
        create_migration_file(version, "wrong_hash\n")
      end

      it 'returns 1' do
        _stdout, exit_code = run_main
        expect(exit_code).to eq(1)
      end

      it 'reports both errors' do
        stdout, _exit_code = run_main
        expect(stdout).to include('has trailing newline')
        expect(stdout).to include('has incorrect hash')
      end
    end

    context 'when multiple files are staged with mixed issues' do
      let(:good_version) { '20260506120000' }
      let(:bad_version) { '20260506130000' }
      let(:git_diff_output) { "#{schema_migrations_dir}/#{good_version}\n#{schema_migrations_dir}/#{bad_version}\n" }

      before do
        create_migration_file(good_version, correct_hash_for(good_version))
        create_migration_file(bad_version, "#{correct_hash_for(bad_version)}\n")
      end

      it 'returns 1' do
        _stdout, exit_code = run_main
        expect(exit_code).to eq(1)
      end

      it 'only reports errors for the bad file' do
        stdout, _exit_code = run_main
        expect(stdout).to include(bad_version)
        expect(stdout).not_to include("#{good_version}:")
      end
    end

    context 'when staged file does not exist on disk' do
      let(:git_diff_output) { "#{schema_migrations_dir}/20260506120000\n" }

      it 'returns 0 (skips non-existent files)' do
        _stdout, exit_code = run_main
        expect(exit_code).to eq(0)
      end
    end

    context 'when staged file is not a version file' do
      let(:git_diff_output) { "#{schema_migrations_dir}/.gitkeep\n" }

      before do
        File.write(File.join(schema_migrations_dir, '.gitkeep'), '')
      end

      it 'returns 0 (skips non-version files)' do
        _stdout, exit_code = run_main
        expect(exit_code).to eq(0)
      end
    end
  end

  private

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    exit_code = yield
    [$stdout.string, exit_code]
  ensure
    $stdout = original_stdout
  end
end
