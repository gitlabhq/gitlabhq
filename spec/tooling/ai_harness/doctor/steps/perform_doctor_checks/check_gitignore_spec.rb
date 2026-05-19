# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../../tooling/ai_harness/doctor/steps/perform_doctor_checks/check_gitignore'

RSpec.describe AiHarness::Doctor::Steps::PerformDoctorChecks::CheckGitignore, feature_category: :tooling do
  let(:repo_root) { Dir.mktmpdir }
  let(:fix) { false }
  let(:context) { { repo_root: repo_root, fix: fix, results: [] } }
  let(:gitignore_path) { File.join(repo_root, '.gitignore') }

  after do
    FileUtils.rm_rf(repo_root)
  end

  describe '.check' do
    context 'when .gitignore contains all required entries' do
      before do
        File.write(gitignore_path, "CLAUDE.local.md\n.ai/*\n")
      end

      it 'reports OK' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when CLAUDE.local.md entry is missing' do
      before do
        File.write(gitignore_path, ".ai/*\n")
      end

      it 'reports FAIL with missing entry detail' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('CLAUDE.local.md')
      end
    end

    context 'when .ai/* entry is missing' do
      before do
        File.write(gitignore_path, "CLAUDE.local.md\n")
      end

      it 'reports FAIL with missing entry detail' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('.ai/*')
      end
    end

    context 'when .gitignore does not exist' do
      it 'reports FAIL' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FAIL')
      end
    end

    context 'when entries are rooted (start with /)' do
      before do
        File.write(gitignore_path, "/CLAUDE.local.md\n/.ai/*\n")
      end

      it 'reports FAIL (rooted entries do not satisfy the check)' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('CLAUDE.local.md')
      end
    end

    context 'with --fix when .gitignore is empty' do
      let(:fix) { true }

      before do
        File.write(gitignore_path, '')
      end

      it 'appends both entries and reports FIXED' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FIXED')
        content = File.read(gitignore_path)
        expect(content).to include('CLAUDE.local.md')
        expect(content).to include('.ai/*')
      end
    end

    context 'with --fix when one entry is missing' do
      let(:fix) { true }

      before do
        File.write(gitignore_path, ".ai/*\n")
      end

      it 'appends only the missing entry and reports FIXED' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FIXED')
        content = File.read(gitignore_path)
        expect(content).to include('CLAUDE.local.md')
      end
    end

    context 'with --fix when .gitignore does not exist' do
      let(:fix) { true }

      it 'creates .gitignore with required entries and reports FIXED' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FIXED')
        expect(File.exist?(gitignore_path)).to be true
        content = File.read(gitignore_path)
        expect(content).to include('CLAUDE.local.md')
        expect(content).to include('.ai/*')
      end
    end

    context 'with --fix when .gitignore has content without trailing newline' do
      let(:fix) { true }

      before do
        File.write(gitignore_path, 'node_modules')
      end

      it 'appends a newline before adding entries' do
        described_class.check(context)

        content = File.read(gitignore_path)
        expect(content).to start_with("node_modules\n")
        expect(content).to include('CLAUDE.local.md')
      end
    end

    it 'destructures context with type assertions' do
      bad_context = { repo_root: 123, fix: false, results: [] }

      expect { described_class.check(bad_context) }.to raise_error(NoMatchingPatternError)
    end
  end
end
