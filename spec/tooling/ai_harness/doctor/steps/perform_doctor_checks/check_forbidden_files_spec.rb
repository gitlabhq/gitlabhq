# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../../tooling/ai_harness/doctor/steps/perform_doctor_checks/check_forbidden_files'

RSpec.describe AiHarness::Doctor::Steps::PerformDoctorChecks::CheckForbiddenFiles, feature_category: :tooling do
  let(:repo_root) { Dir.mktmpdir }
  let(:allowed_prefix) { '.claude/skills/example-allowed-skill/SKILL.md' }
  let(:config) { { 'allowed_committed_files' => [allowed_prefix] } }
  let(:context) { { repo_root: repo_root, config: config, fix: false, results: [] } }

  after do
    FileUtils.rm_rf(repo_root)
  end

  describe '.check' do
    before do
      # Initialize a git repo so git ls-files works
      system('git', 'init', repo_root, out: File::NULL, err: File::NULL)
    end

    context 'when no forbidden files are tracked' do
      it 'reports OK' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when .claude/rules/ file is committed' do
      before do
        add_tracked_file('.claude/rules/my-rule.md')
      end

      it 'reports FAIL with the file path' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('.claude/rules/my-rule.md')
      end
    end

    context 'when an allowed file from the allowlist is committed' do
      before do
        add_tracked_file(allowed_prefix)
      end

      it 'reports OK (intentionally committed project content)' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when allowed and forbidden files are both committed' do
      before do
        add_tracked_file(allowed_prefix)
        add_tracked_file('.claude/skills/my-personal-skill.md')
      end

      it 'reports FAIL only for the non-allowlisted file' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('my-personal-skill.md')
        expect(check[:details].join).not_to include(allowed_prefix)
      end
    end

    context 'when a file outside the allowlist is committed' do
      before do
        add_tracked_file('.claude/skills/my-skill.md')
      end

      it 'reports FAIL' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FAIL')
      end
    end

    context 'when .claude/settings.json is committed' do
      before do
        add_tracked_file('.claude/settings.json', '{}')
      end

      it 'reports FAIL' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('.claude/settings.json')
      end
    end

    context 'when .opencode/ file is committed' do
      before do
        add_tracked_file('.opencode/config.json', '{}')
      end

      it 'reports FAIL' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FAIL')
      end
    end

    context 'when .gitlab/duo/chat-rules.md is committed' do
      before do
        add_tracked_file('.gitlab/duo/chat-rules.md')
      end

      it 'reports FAIL' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('.gitlab/duo/chat-rules.md')
      end
    end

    context 'when .gitlab/duo/mcp.json is committed' do
      before do
        add_tracked_file('.gitlab/duo/mcp.json', '{}')
      end

      it 'reports FAIL' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FAIL')
      end
    end

    context 'when AGENTS.local.md is force-committed at root' do
      before do
        add_tracked_file('AGENTS.local.md', '# personal')
      end

      it 'reports FAIL with the file path' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('AGENTS.local.md')
      end
    end

    context 'when CLAUDE.local.md is force-committed at root' do
      before do
        add_tracked_file('CLAUDE.local.md', '# personal')
      end

      it 'reports FAIL with the file path' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('CLAUDE.local.md')
      end
    end

    context 'when AGENTS.local.md is force-committed in a subdirectory' do
      before do
        add_tracked_file('sub/AGENTS.local.md', '# personal')
      end

      it 'reports FAIL with the file path' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        expect(check[:details].join).to include('sub/AGENTS.local.md')
      end
    end

    context 'when forbidden file exists but is gitignored' do
      before do
        File.write(File.join(repo_root, '.gitignore'), ".claude/\n")
        system('git', '-C', repo_root, 'add', '.gitignore', out: File::NULL, err: File::NULL)
        FileUtils.mkdir_p(File.join(repo_root, '.claude', 'rules'))
        File.write(File.join(repo_root, '.claude', 'rules', 'my-rule.md'), '# rule')
      end

      it 'reports OK (gitignored files are not flagged)' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('OK')
      end
    end

    context 'when multiple forbidden patterns are detected' do
      before do
        add_tracked_file('.claude/agents/my-agent.md')
        add_tracked_file('.claude/commands/my-cmd.md')
        add_tracked_file('.claude/settings.local.json', '{}')
        add_tracked_file('.claude/settings.local.jsonc', '{}')
      end

      it 'reports FAIL listing all file paths' do
        result = described_class.check(context)

        check = result[:results].last
        expect(check[:status]).to eq('FAIL')
        details = check[:details].join("\n")
        expect(details).to include('.claude/agents/my-agent.md')
        expect(details).to include('.claude/commands/my-cmd.md')
        expect(details).to include('.claude/settings.local.json')
        expect(details).to include('.claude/settings.local.jsonc')
      end
    end

    context 'with --fix when forbidden files are committed' do
      let(:context) { { repo_root: repo_root, config: config, fix: true, results: [] } }

      before do
        add_tracked_file('.claude/rules/foo.md')
      end

      it 'still reports FAIL (not auto-fixable)' do
        result = described_class.check(context)

        expect(result[:results].last[:status]).to eq('FAIL')
      end
    end

    it 'destructures context with type assertions' do
      bad_context = { repo_root: 123, config: config, results: [] }

      expect { described_class.check(bad_context) }.to raise_error(NoMatchingPatternError)
    end

    it 'raises NoMatchingPatternKeyError when config key is missing' do
      bad_context = { repo_root: repo_root, results: [] }

      expect { described_class.check(bad_context) }.to raise_error(NoMatchingPatternKeyError)
    end

    it 'raises when git ls-files fails and includes git stderr in the message' do
      bad_context = { repo_root: '/nonexistent/path', config: config, results: [] }

      expect { described_class.check(bad_context) }.to raise_error(
        RuntimeError, /git ls-files failed.*cannot change to/
      )
    end
  end

  private

  def add_tracked_file(relative_path, content = '# content')
    full_path = File.join(repo_root, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    system('git', '-C', repo_root, 'add', '--force', relative_path, out: File::NULL, err: File::NULL)
  end
end
