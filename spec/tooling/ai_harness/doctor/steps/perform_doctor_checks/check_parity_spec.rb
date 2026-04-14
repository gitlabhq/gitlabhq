# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../../tooling/ai_harness/doctor/steps/perform_doctor_checks/check_parity'

RSpec.describe AiHarness::Doctor::Steps::PerformDoctorChecks::CheckParity, feature_category: :tooling do
  let(:repo_root) { Dir.mktmpdir }
  let(:fix) { false }
  let(:context) { { repo_root: repo_root, fix: fix, results: [] } }

  before do
    system('git', 'init', repo_root, out: File::NULL, err: File::NULL)
  end

  after do
    FileUtils.rm_rf(repo_root)
  end

  def write_and_track(relative_path, content)
    full_path = File.join(repo_root, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    system('git', '-C', repo_root, 'add', '--force', relative_path, out: File::NULL, err: File::NULL)
  end

  describe '.check' do
    context 'when both files exist at root with identical content' do
      before do
        write_and_track('AGENTS.md', '# Instructions')
        write_and_track('CLAUDE.md', '# Instructions')
      end

      it 'reports OK' do
        result = described_class.check(context)

        expect(result[:results].last).to include(status: 'OK')
      end
    end

    context 'when CLAUDE.md is missing at root' do
      before do
        write_and_track('AGENTS.md', '# Instructions')
      end

      it 'reports FAIL with detail about missing CLAUDE.md without directory prefix' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].first).to eq('CLAUDE.md not found (AGENTS.md exists)')
      end
    end

    context 'when AGENTS.md is missing at root' do
      before do
        write_and_track('CLAUDE.md', '# Instructions')
      end

      it 'reports FAIL with detail about missing AGENTS.md' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('AGENTS.md not found')
      end
    end

    context 'when content differs at root' do
      before do
        write_and_track('AGENTS.md', '# Source of truth')
        write_and_track('CLAUDE.md', '# Different content')
      end

      it 'reports FAIL with detail about differing content' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('differs from AGENTS.md')
      end
    end

    context 'when subdirectory pair has identical content' do
      before do
        write_and_track('AGENTS.md', '# Root')
        write_and_track('CLAUDE.md', '# Root')
        write_and_track('sub/AGENTS.md', '# Sub')
        write_and_track('sub/CLAUDE.md', '# Sub')
      end

      it 'reports OK' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when subdirectory pair content differs' do
      before do
        write_and_track('AGENTS.md', '# Root')
        write_and_track('CLAUDE.md', '# Root')
        write_and_track('sub/AGENTS.md', '# Sub agents')
        write_and_track('sub/CLAUDE.md', '# Sub claude')
      end

      it 'reports FAIL with subdirectory path in details' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('sub/')
      end
    end

    context 'when subdirectory CLAUDE.md is missing' do
      before do
        write_and_track('AGENTS.md', '# Root')
        write_and_track('CLAUDE.md', '# Root')
        write_and_track('sub/AGENTS.md', '# Sub')
      end

      it 'reports FAIL with subdirectory path in details' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('sub/')
      end
    end

    context 'with --fix when content differs' do
      let(:fix) { true }

      before do
        write_and_track('AGENTS.md', '# Source of truth')
        write_and_track('CLAUDE.md', '# Different')
      end

      it 'copies AGENTS.md content to CLAUDE.md and reports FIXED' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FIXED')
        expect(File.read(File.join(repo_root, 'CLAUDE.md'))).to eq('# Source of truth')
      end
    end

    context 'with --fix when CLAUDE.md is missing' do
      let(:fix) { true }

      before do
        write_and_track('AGENTS.md', '# Source of truth')
      end

      it 'creates CLAUDE.md from AGENTS.md and reports FIXED' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FIXED')
        expect(File.read(File.join(repo_root, 'CLAUDE.md'))).to eq('# Source of truth')
      end
    end

    context 'with --fix when AGENTS.md is missing (only CLAUDE.md exists)' do
      let(:fix) { true }

      before do
        write_and_track('CLAUDE.md', '# Claude only')
      end

      it 'creates AGENTS.md from CLAUDE.md and reports FIXED' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FIXED')
        expect(File.read(File.join(repo_root, 'AGENTS.md'))).to eq('# Claude only')
      end
    end

    context 'with --fix on subdirectory pair' do
      let(:fix) { true }

      before do
        write_and_track('AGENTS.md', '# Root')
        write_and_track('CLAUDE.md', '# Root')
        write_and_track('sub/AGENTS.md', '# Sub')
      end

      it 'creates missing subdirectory CLAUDE.md and reports FIXED' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FIXED')
        expect(File.read(File.join(repo_root, 'sub', 'CLAUDE.md'))).to eq('# Sub')
      end
    end

    context 'when root-level issue exists' do
      before do
        write_and_track('AGENTS.md', '# Root')
        write_and_track('CLAUDE.md', '# Different')
      end

      it 'reports detail with no directory prefix for root level' do
        result = described_class.check(context)

        detail = result[:results].last[:details].first
        expect(detail).to eq('CLAUDE.md differs from AGENTS.md')
      end
    end

    context 'when deeply nested subdirectory file is missing' do
      before do
        write_and_track('AGENTS.md', '# Root')
        write_and_track('CLAUDE.md', '# Root')
        write_and_track('a/b/c/AGENTS.md', '# Deep')
      end

      it 'reports full relative path from repo root, not just leaf directory' do
        result = described_class.check(context)

        detail = result[:results].last[:details].first
        expect(detail).to include('a/b/c/')
        expect(detail).not_to eq("c/: CLAUDE.md not found (AGENTS.md exists)")
      end
    end

    context 'when CLAUDE.md is a symlink to AGENTS.md at root' do
      before do
        write_and_track('AGENTS.md', '# Instructions')
        File.symlink(File.join(repo_root, 'AGENTS.md'), File.join(repo_root, 'CLAUDE.md'))
        system('git', '-C', repo_root, 'add', '--force', 'CLAUDE.md', out: File::NULL, err: File::NULL)
      end

      it 'reports FAIL with detail about symlink' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].first).to include('symlink')
        expect(check[:details].first).to include('CLAUDE.md')
      end
    end

    context 'when AGENTS.md is a symlink at root' do
      before do
        write_and_track('CLAUDE.md', '# Instructions')
        File.symlink(File.join(repo_root, 'CLAUDE.md'), File.join(repo_root, 'AGENTS.md'))
        system('git', '-C', repo_root, 'add', '--force', 'AGENTS.md', out: File::NULL, err: File::NULL)
      end

      it 'reports FAIL with detail about symlink' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].first).to include('symlink')
        expect(check[:details].first).to include('AGENTS.md')
      end
    end

    context 'when subdirectory CLAUDE.md is a symlink' do
      before do
        write_and_track('AGENTS.md', '# Root')
        write_and_track('CLAUDE.md', '# Root')
        write_and_track('sub/AGENTS.md', '# Sub')
        FileUtils.mkdir_p(File.join(repo_root, 'sub'))
        File.symlink(File.join(repo_root, 'sub', 'AGENTS.md'), File.join(repo_root, 'sub', 'CLAUDE.md'))
        system('git', '-C', repo_root, 'add', '--force', 'sub/CLAUDE.md', out: File::NULL, err: File::NULL)
      end

      it 'reports FAIL with subdirectory prefix and symlink detail' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('sub/')
        expect(check[:details].join).to include('symlink')
      end
    end

    context 'with --fix when CLAUDE.md is a symlink' do
      let(:fix) { true }

      before do
        write_and_track('AGENTS.md', '# Instructions')
        File.symlink(File.join(repo_root, 'AGENTS.md'), File.join(repo_root, 'CLAUDE.md'))
        system('git', '-C', repo_root, 'add', '--force', 'CLAUDE.md', out: File::NULL, err: File::NULL)
      end

      it 'replaces symlink with a regular file copy and reports FIXED' do
        result = described_class.check(context)

        claude_path = File.join(repo_root, 'CLAUDE.md')
        expect(result[:results].last[:status]).to eq('FIXED')
        expect(File.symlink?(claude_path)).to be(false)
        expect(File.read(claude_path)).to eq('# Instructions')
      end
    end

    context 'with --fix when AGENTS.md is a symlink' do
      let(:fix) { true }

      before do
        write_and_track('CLAUDE.md', '# Instructions')
        File.symlink(File.join(repo_root, 'CLAUDE.md'), File.join(repo_root, 'AGENTS.md'))
        system('git', '-C', repo_root, 'add', '--force', 'AGENTS.md', out: File::NULL, err: File::NULL)
      end

      it 'replaces symlink with a regular file copy and reports FIXED' do
        result = described_class.check(context)

        agents_path = File.join(repo_root, 'AGENTS.md')
        expect(result[:results].last[:status]).to eq('FIXED')
        expect(File.symlink?(agents_path)).to be(false)
        expect(File.read(agents_path)).to eq('# Instructions')
      end
    end

    it 'destructures context with type assertions' do
      bad_context = { repo_root: 123, fix: false, results: [] }

      expect { described_class.check(bad_context) }.to raise_error(NoMatchingPatternError)
    end

    it 'raises ArgumentError for unknown fix action' do
      allow(described_class).to receive_messages(
        find_pairs: [],
        validate_pairs: [
          { detail: 'test', agents_path: '/a', claude_path: '/c', action: :unknown_action }
        ]
      )

      fix_context = { repo_root: repo_root, fix: true, results: [] }

      expect { described_class.check(fix_context) }.to raise_error(ArgumentError, /Unknown fix action/)
    end

    it 'raises when git ls-files fails and includes git stderr in the message' do
      bad_context = { repo_root: '/nonexistent/path', fix: false, results: [] }

      expect { described_class.check(bad_context) }.to raise_error(
        RuntimeError, /git ls-files failed.*cannot change to/
      )
    end
  end
end
