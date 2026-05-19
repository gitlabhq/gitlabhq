# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'
require 'fileutils'
require_relative '../../../../tooling/ai_harness/doctor/main'

RSpec.describe 'AiHarness::Doctor integration', :aggregate_failures, feature_category: :tooling do
  let(:repo_root) { Dir.mktmpdir }

  before do
    system('git', 'init', repo_root, out: File::NULL, err: File::NULL)
    allow(AiHarness::Doctor::Steps::PerformDoctorChecks::ResolveRepoRoot).to receive(:resolve) do |context|
      context[:repo_root] = repo_root
      context
    end
  end

  after do
    FileUtils.rm_rf(repo_root)
  end

  def run_doctor(args = [])
    stub_const('ARGV', args)
    stdout = +''
    stderr = +''
    allow($stdout).to receive(:print) { |text| stdout << text }
    allow($stderr).to receive(:print) { |text| stderr << text }
    exit_code = AiHarness::Doctor::Main.main
    { exit_code: exit_code, stdout: stdout, stderr: stderr }
  end

  def write_file(relative_path, content = '# content')
    full_path = File.join(repo_root, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  def add_tracked_file(relative_path, content = '# content')
    write_file(relative_path, content)
    system('git', '-C', repo_root, 'add', '--force', relative_path, out: File::NULL, err: File::NULL)
  end

  def setup_valid_repo
    write_file('AGENTS.md', "# Instructions\nRead .ai/git.md and .ai/testing.md")
    write_file('CLAUDE.md', "# Instructions\nRead .ai/git.md and .ai/testing.md")
    write_file('.ai/git.md', '# Git')
    write_file('.ai/testing.md', '# Testing')
    write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")
  end

  describe 'happy path' do
    it 'passes all checks on a clean repo' do
      setup_valid_repo

      result = run_doctor

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include('OK')
      expect(result[:stdout]).not_to include('FAIL')
    end

    it 'passes with subdirectory pairs' do
      setup_valid_repo
      write_file('sub/AGENTS.md', '# Sub')
      write_file('sub/CLAUDE.md', '# Sub')

      result = run_doctor

      expect(result[:exit_code]).to eq(0)
    end

    it 'resolves .ai/ references in subdirectory AGENTS.md relative to that subdirectory' do
      setup_valid_repo
      write_file('sub/.ai/local-module.md', '# Local module')
      add_tracked_file('sub/AGENTS.md', "# Sub\nRead .ai/local-module.md")
      add_tracked_file('sub/CLAUDE.md', "# Sub\nRead .ai/local-module.md")

      result = run_doctor

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).not_to include('FAIL')
    end

    it 'reports FAIL when subdirectory AGENTS.md .ai/ reference exists only at repo root' do
      setup_valid_repo
      add_tracked_file('sub/AGENTS.md', "# Sub\nRead .ai/testing.md")
      add_tracked_file('sub/CLAUDE.md', "# Sub\nRead .ai/testing.md")

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('.ai/testing.md')
    end

    it 'treats gitignored tool files as fine' do
      setup_valid_repo
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n.claude/\n.opencode/\n")
      write_file('.claude/rules/my-rule.md', '# rule')
      write_file('.opencode/config.json', '{}')

      result = run_doctor

      expect(result[:exit_code]).to eq(0)
    end

    it 'is a no-op when --fix is run on a valid repo' do
      setup_valid_repo
      agents_content = File.read(File.join(repo_root, 'AGENTS.md'))

      result = run_doctor(['--fix'])

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include('OK')
      expect(File.read(File.join(repo_root, 'AGENTS.md'))).to eq(agents_content)
    end

    it 'prints help to stdout and exits 0 for --help' do
      result = run_doctor(['--help'])

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include('Usage:')
      expect(result[:stdout]).to include('--fix')
      expect(result[:stdout]).to include('--help')
      expect(result[:stderr]).to be_empty
    end
  end

  describe 'parity check' do
    it 'fails when CLAUDE.md is missing at root' do
      write_file('AGENTS.md', '# Content')
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('CLAUDE.md not found')
    end

    it 'fails when AGENTS.md is missing at root' do
      write_file('CLAUDE.md', '# Content')
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('AGENTS.md not found')
    end

    it 'reports parity failure when content differs' do
      write_file('AGENTS.md', '# Source of truth')
      write_file('CLAUDE.md', '# Different content')
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('differs from AGENTS.md')
    end

    it 'fails when subdirectory pair content differs' do
      setup_valid_repo
      add_tracked_file('sub/AGENTS.md', '# Sub A')
      add_tracked_file('sub/CLAUDE.md', '# Sub C')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('sub/')
    end

    it 'fails when subdirectory file is missing' do
      setup_valid_repo
      add_tracked_file('sub/AGENTS.md', '# Sub')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('sub/')
    end

    it 'shows full relative path for deeply nested subdirectory' do
      setup_valid_repo
      add_tracked_file('a/b/c/AGENTS.md', '# Deep')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('a/b/c/')
    end

    it 'fails when CLAUDE.md is a symlink to AGENTS.md' do
      write_file('AGENTS.md', '# Content')
      File.symlink('AGENTS.md', File.join(repo_root, 'CLAUDE.md'))
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('symlink')
      expect(result[:stdout]).to include('CLAUDE.md')
    end

    it 'fails when AGENTS.md is a symlink' do
      write_file('CLAUDE.md', '# Content')
      File.symlink('CLAUDE.md', File.join(repo_root, 'AGENTS.md'))
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('symlink')
      expect(result[:stdout]).to include('AGENTS.md')
    end

    it 'fails when subdirectory file is a symlink' do
      setup_valid_repo
      add_tracked_file('sub/AGENTS.md', '# Sub')
      File.symlink('AGENTS.md', File.join(repo_root, 'sub', 'CLAUDE.md'))
      system('git', '-C', repo_root, 'add', '--force', 'sub/CLAUDE.md', out: File::NULL, err: File::NULL)

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('sub/')
      expect(result[:stdout]).to include('symlink')
    end
  end

  describe 'references check' do
    it 'passes when AGENTS.md has no .ai/ references' do
      write_file('AGENTS.md', '# No references here')
      write_file('CLAUDE.md', '# No references here')
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")

      result = run_doctor

      expect(result[:exit_code]).to eq(0)
    end
  end

  describe 'gitignore check' do
    it 'fails when CLAUDE.local.md entry is missing' do
      setup_valid_repo
      write_file('.gitignore', ".ai/*\n")

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('CLAUDE.local.md')
    end

    it 'fails when .ai/* entry is missing' do
      setup_valid_repo
      write_file('.gitignore', "CLAUDE.local.md\n")

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('.ai/*')
    end

    it 'fails when .gitignore does not exist' do
      write_file('AGENTS.md', '# Content')
      write_file('CLAUDE.md', '# Content')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
    end

    it 'fails when entries are rooted' do
      setup_valid_repo
      write_file('.gitignore', "/CLAUDE.local.md\n.ai/*\n")

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('CLAUDE.local.md')
    end
  end

  describe 'forbidden files check' do
    it 'reports .claude/skills/ file committed' do
      setup_valid_repo
      add_tracked_file('.claude/skills/my-skill.md')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
    end

    it 'reports .claude/settings.json committed' do
      setup_valid_repo
      add_tracked_file('.claude/settings.json', '{}')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
    end

    it 'reports .opencode/ file committed' do
      setup_valid_repo
      add_tracked_file('.opencode/config.json', '{}')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
    end

    it 'reports .gitlab/duo/chat-rules.md committed' do
      setup_valid_repo
      add_tracked_file('.gitlab/duo/chat-rules.md')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
    end

    it 'reports .gitlab/duo/mcp.json committed' do
      setup_valid_repo
      add_tracked_file('.gitlab/duo/mcp.json', '{}')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
    end

    it 'reports CLAUDE.local.md force-committed at root' do
      setup_valid_repo
      add_tracked_file('CLAUDE.local.md', '# personal overrides')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('CLAUDE.local.md')
    end

    it 'reports AGENTS.local.md force-committed in subdirectory' do
      setup_valid_repo
      add_tracked_file('sub/AGENTS.local.md', '# personal overrides')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('AGENTS.local.md')
    end

    it 'reports all remaining forbidden patterns' do
      setup_valid_repo
      add_tracked_file('.claude/agents/my-agent.md')
      add_tracked_file('.claude/commands/my-cmd.md')
      add_tracked_file('.claude/settings.local.json', '{}')
      add_tracked_file('.claude/settings.local.jsonc', '{}')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
    end

    it 'reports .claude/rules/ file committed' do
      setup_valid_repo
      add_tracked_file('.claude/rules/my-rule.md')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('.claude/rules/my-rule.md')
    end

    it 'allows .claude/skills/gitlab-coding-principles/SKILL.md committed' do
      setup_valid_repo
      add_tracked_file('.claude/skills/gitlab-coding-principles/SKILL.md')

      result = run_doctor

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).not_to include('.claude/skills/gitlab-coding-principles/SKILL.md')
    end

    it 'reports AGENTS.local.md as forbidden when force-committed at root' do
      setup_valid_repo
      add_tracked_file('AGENTS.local.md', '# personal overrides')

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('AGENTS.local.md')
    end
  end

  describe 'error cases' do
    it 'reports multiple failures and all four checks run' do
      write_file('AGENTS.md', "# Instructions\nRead .ai/missing.md")

      result = run_doctor

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout].scan('FAIL').count).to be >= 2
      expect(result[:stdout]).to include('CLAUDE.md / AGENTS.md parity')
      expect(result[:stdout]).to include('.ai/ reference resolution')
      expect(result[:stdout]).to include('.gitignore coverage')
      expect(result[:stdout]).to include('Forbidden committed files')
    end

    it 'prints error to stderr for unknown option' do
      result = run_doctor(['--unknown'])

      expect(result[:exit_code]).to eq(1)
      expect(result[:stderr]).to include('Unknown option: --unknown')
      expect(result[:stderr]).to include('Usage:')
      expect(result[:stdout]).to be_empty
    end

    it 'prints help when --fix and --help are both given' do
      result = run_doctor(['--fix', '--help'])

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include('Usage:')
      expect(result[:stdout]).to include('--fix')
      expect(result[:stdout]).to include('--help')
    end

    it 'raises UnmatchedResultError for unmatched result variants' do
      allow(AiHarness::Doctor::Steps::ParseArgv).to receive(:parse) do |_result|
        Gitlab::Fp::Result.ok({ unexpected_key: 'unexpected_value' })
      end
      allow(AiHarness::Doctor::Steps::HandleAction).to receive(:handle) do |context|
        context
      end
      allow(AiHarness::Doctor::Steps::PrintStdout).to receive(:print)

      expect { run_doctor }.to raise_error(Gitlab::Fp::UnmatchedResultError)
    end
  end

  describe '--fix mode' do
    it 'fixes parity and gitignore issues with exit code 0' do
      write_file('AGENTS.md', '# Source of truth')

      result = run_doctor(['--fix'])

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include('FIXED')
      expect(File.read(File.join(repo_root, 'CLAUDE.md'))).to eq('# Source of truth')
      gitignore = File.read(File.join(repo_root, '.gitignore'))
      expect(gitignore).to include('CLAUDE.local.md')
      expect(gitignore).to include('.ai/*')
    end

    it 'syncs CLAUDE.md from AGENTS.md when content differs' do
      write_file('AGENTS.md', '# Source of truth')
      write_file('CLAUDE.md', '# Different')
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")

      result = run_doctor(['--fix'])

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include('FIXED')
      expect(File.read(File.join(repo_root, 'CLAUDE.md'))).to eq('# Source of truth')
    end

    it 'fixes what it can and reports what it cannot' do
      write_file('AGENTS.md', '# Source of truth')
      write_file('CLAUDE.md', '# Different')
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")
      add_tracked_file('.claude/rules/foo.md')

      result = run_doctor(['--fix'])

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FIXED')
      expect(result[:stdout]).to include('FAIL')
      expect(File.read(File.join(repo_root, 'CLAUDE.md'))).to eq('# Source of truth')
    end

    it 'does not fix missing .ai/ references' do
      write_file('AGENTS.md', "Read .ai/missing.md")
      write_file('CLAUDE.md', "Read .ai/missing.md")
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")

      result = run_doctor(['--fix'])

      expect(result[:stdout]).to include('FAIL')
      expect(result[:stdout]).to include('.ai/missing.md')
    end

    it 'creates AGENTS.md from CLAUDE.md when only CLAUDE.md exists' do
      write_file('CLAUDE.md', '# Claude only')
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")

      result = run_doctor(['--fix'])

      expect(result[:stdout]).to include('FIXED')
      expect(File.read(File.join(repo_root, 'AGENTS.md'))).to eq('# Claude only')
    end

    it 'repairs subdirectory pair' do
      setup_valid_repo
      add_tracked_file('sub/AGENTS.md', '# Sub content')

      result = run_doctor(['--fix'])

      expect(result[:stdout]).to include('FIXED')
      expect(File.read(File.join(repo_root, 'sub', 'CLAUDE.md'))).to eq('# Sub content')
    end

    it 'replaces symlink with regular file' do
      write_file('AGENTS.md', '# Content')
      File.symlink('AGENTS.md', File.join(repo_root, 'CLAUDE.md'))
      write_file('.gitignore', "CLAUDE.local.md\n.ai/*\n")

      result = run_doctor(['--fix'])

      expect(result[:stdout]).to include('FIXED')
      claude_path = File.join(repo_root, 'CLAUDE.md')
      expect(File.symlink?(claude_path)).to be(false)
      expect(File.read(claude_path)).to eq('# Content')
    end

    it 'does not fix forbidden committed files' do
      setup_valid_repo
      add_tracked_file('.claude/rules/my-rule.md')

      result = run_doctor(['--fix'])

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include('FAIL')
    end
  end
end
