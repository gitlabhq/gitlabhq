# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../../tooling/ai_harness/doctor/steps/perform_doctor_checks/check_ai_references'

RSpec.describe AiHarness::Doctor::Steps::PerformDoctorChecks::CheckAiReferences, feature_category: :tooling do
  let(:repo_root) { Dir.mktmpdir }
  let(:context) { { repo_root: repo_root, fix: false, results: [] } }

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
    context 'when all .ai/ references resolve to existing files' do
      before do
        write_and_track('.ai/git.md', '# Git')
        write_and_track('AGENTS.md', 'Read .ai/git.md')
      end

      it 'reports OK' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when a .ai/ reference does not resolve' do
      before do
        write_and_track('AGENTS.md', 'Read .ai/missing.md for details')
      end

      it 'reports FAIL with the missing file path' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('.ai/missing.md')
        expect(check[:details].join).to include('does not exist')
      end
    end

    context 'when AGENTS.md contains no .ai/ references' do
      before do
        write_and_track('AGENTS.md', '# No references here')
      end

      it 'reports OK' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when --fix is passed with missing references' do
      let(:context) { { repo_root: repo_root, fix: true, results: [] } }

      before do
        write_and_track('AGENTS.md', 'Read .ai/missing.md')
      end

      it 'still reports FAIL (not auto-fixable)' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FAIL')
      end
    end

    context 'when no AGENTS.md files exist' do
      it 'reports OK' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when subdirectory AGENTS.md references .ai/ file in its own directory' do
      before do
        write_and_track('sub/.ai/testing.md', '# Testing')
        write_and_track('AGENTS.md', '# Root')
        write_and_track('sub/AGENTS.md', 'Read .ai/testing.md')
      end

      it 'resolves the reference relative to the subdirectory and reports OK' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when subdirectory AGENTS.md references .ai/ file that only exists at repo root' do
      before do
        write_and_track('.ai/testing.md', '# Testing')
        write_and_track('AGENTS.md', '# Root')
        write_and_track('sub/AGENTS.md', 'Read .ai/testing.md')
        # sub/.ai/testing.md does NOT exist
      end

      it 'reports FAIL with a path that identifies the containing subdirectory' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('sub/.ai/testing.md')
        expect(check[:details].join).to include('does not exist')
      end
    end

    context 'when .ai/ reference has trailing sentence punctuation' do
      before do
        write_and_track('.ai/README.md', '# README')
        write_and_track('AGENTS.md', 'See .ai/README.md.')
      end

      it 'strips trailing punctuation and reports OK' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when git ls-files returns a path but file was deleted from disk' do
      before do
        write_and_track('AGENTS.md', 'Read .ai/git.md')
        # File is tracked but then removed from disk
        File.delete(File.join(repo_root, 'AGENTS.md'))
      end

      it 'skips the missing file and reports OK' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when root AGENTS.md is untracked but subdirectory AGENTS.md is tracked' do
      before do
        write_and_track('.ai/git.md', '# Git')
        write_and_track('sub/AGENTS.md', 'Read .ai/git.md')
        # Root AGENTS.md exists on disk but is NOT git-tracked
        File.write(File.join(repo_root, 'AGENTS.md'), 'Read .ai/missing.md')
      end

      it 'still scans the untracked root AGENTS.md for broken references' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('.ai/missing.md')
      end
    end

    it 'destructures context with type assertions' do
      bad_context = { repo_root: 123, results: [] }

      expect { described_class.check(bad_context) }.to raise_error(NoMatchingPatternError)
    end

    it 'raises when git ls-files fails and includes git stderr in the message' do
      bad_context = { repo_root: '/nonexistent/path', fix: false, results: [] }

      expect { described_class.check(bad_context) }.to raise_error(
        RuntimeError, /git ls-files failed.*cannot change to/
      )
    end
  end
end
