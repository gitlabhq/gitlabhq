# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../support/tmpdir'
require_relative '../../../scripts/ai/sync_principles'

RSpec.describe SyncPrinciples, feature_category: :tooling do
  include TmpdirHelper

  before do
    described_class.file_cache = {}
  end

  describe '.load_frontmatter_data' do
    subject(:frontmatter_data) { described_class.load_frontmatter_data }

    let(:tmpdir) { mktmpdir }
    let(:principles_dir) { File.join(tmpdir, 'principles') }

    before do
      stub_const("#{described_class}::REPO_ROOT", tmpdir)
      stub_const("#{described_class}::PRINCIPLES_DIR", 'principles')
      FileUtils.mkdir_p(principles_dir)
    end

    context 'with file containing source_checksum frontmatter' do
      before do
        File.write(File.join(principles_dir, 'test.md'), "---\nsource_checksum: abc123\n---\n# Test")
      end

      it { is_expected.to eq({ 'test' => { checksum: 'abc123', distilled_at_sha: nil } }) }
    end

    context 'with file containing source_checksum and distilled_at_sha frontmatter' do
      before do
        File.write(File.join(principles_dir, 'test.md'),
          "---\nsource_checksum: abc123\ndistilled_at_sha: def456\n---\n# Test")
      end

      it { is_expected.to eq({ 'test' => { checksum: 'abc123', distilled_at_sha: 'def456' } }) }
    end

    context 'with file without frontmatter' do
      before do
        File.write(File.join(principles_dir, 'no-frontmatter.md'), '# No frontmatter here')
      end

      it { is_expected.to eq({}) }
    end

    context 'with file without source_checksum key' do
      before do
        File.write(File.join(principles_dir, 'other.md'), "---\nother_key: value\n---\n# Other")
      end

      it { is_expected.to eq({}) }
    end
  end

  describe '.generate_agents_md' do
    let(:tmpdir) { mktmpdir }
    let(:manifest) do
      {
        'principles' => {
          'backend' => { 'agents_md_dirs' => ['app/models', 'scripts'] },
          'qa' => { 'agents_md_dirs' => ['spec'] },
          'security' => {}
        }
      }
    end

    before do
      stub_const("#{described_class}::REPO_ROOT", tmpdir)
    end

    context 'when target directories exist' do
      before do
        FileUtils.mkdir_p(File.join(tmpdir, 'app/models'))
        FileUtils.mkdir_p(File.join(tmpdir, 'scripts'))
        FileUtils.mkdir_p(File.join(tmpdir, 'spec'))
        described_class.generate_agents_md(manifest)
      end

      it 'generates AGENTS.md files with principle references', :aggregate_failures do
        backend_agents = File.read(File.join(tmpdir, 'app/models/AGENTS.md'))

        expect(backend_agents).to start_with(described_class::AGENTS_MD_HEADER)
        expect(backend_agents).to include('@.ai/principles/distilled/backend.md')
      end

      it 'does not generate AGENTS.md for principles without agents_md_dirs' do
        expect(File.exist?(File.join(tmpdir, 'AGENTS.md'))).to be false
      end
    end

    context 'when target directory does not exist' do
      it 'skips the directory' do
        described_class.generate_agents_md(manifest)

        expect(File.exist?(File.join(tmpdir, 'app/models/AGENTS.md'))).to be false
      end
    end

    context 'when multiple principles target the same directory' do
      let(:manifest) do
        {
          'principles' => {
            'database' => { 'agents_md_dirs' => ['db/migrate'] },
            'backend' => { 'agents_md_dirs' => ['db/migrate'] }
          }
        }
      end

      before do
        FileUtils.mkdir_p(File.join(tmpdir, 'db/migrate'))
        described_class.generate_agents_md(manifest)
      end

      it 'merges principle references into one file', :aggregate_failures do
        content = File.read(File.join(tmpdir, 'db/migrate/AGENTS.md'))

        expect(content).to include('@.ai/principles/distilled/database.md')
        expect(content).to include('@.ai/principles/distilled/backend.md')
      end
    end

    context 'when an orphaned auto-generated AGENTS.md exists' do
      before do
        FileUtils.mkdir_p(File.join(tmpdir, 'old_dir'))
        File.write(File.join(tmpdir, 'old_dir/AGENTS.md'),
          "#{described_class::AGENTS_MD_HEADER}\n\n@.ai/principles/distilled/old.md\n")
        described_class.generate_agents_md(manifest)
      end

      it 'deletes the orphaned file' do
        expect(File.exist?(File.join(tmpdir, 'old_dir/AGENTS.md'))).to be false
      end
    end

    context 'when a hand-written AGENTS.md exists outside agents_md_dirs' do
      before do
        FileUtils.mkdir_p(File.join(tmpdir, 'workhorse'))
        File.write(File.join(tmpdir, 'workhorse/AGENTS.md'), "# Workhorse Guide\n\nHand-written.")
        described_class.generate_agents_md(manifest)
      end

      it 'does not delete the hand-written file' do
        expect(File.read(File.join(tmpdir, 'workhorse/AGENTS.md'))).to start_with('# Workhorse Guide')
      end
    end
  end

  describe '.sources_footer' do
    subject(:footer) { described_class.sources_footer(config) }

    context 'with sources' do
      let(:config) do
        {
          'sources' => [
            { 'path' => 'doc/development/testing_guide/best_practices.md' },
            { 'path' => 'doc/development/testing_guide/testing_levels.md' }
          ]
        }
      end

      it 'lists source paths', :aggregate_failures do
        expect(footer).to include('## Authoritative sources')
        expect(footer).to include('- doc/development/testing_guide/best_practices.md')
        expect(footer).to include('- doc/development/testing_guide/testing_levels.md')
      end
    end

    context 'without sources' do
      let(:config) { { 'sources' => [] } }

      it { is_expected.to eq('') }
    end
  end

  describe '.distill_and_write_principles' do
    let(:tmpdir) { mktmpdir }
    let(:principles_dir) { File.join(tmpdir, '.ai/principles/distilled') }
    let(:manifest) do
      {
        'principles' => {
          'qa' => {
            'sources' => [
              { 'path' => 'doc/development/testing_guide/best_practices.md' }
            ]
          }
        }
      }
    end

    let(:affected) do
      { 'qa' => { config: manifest.dig('principles', 'qa'), changed_sources: [] } }
    end

    let(:existing_content) { "# QA Principles\n\n## Checklist\n\n### Test Coverage\n\n- Old rule\n" }
    let(:distilled_content) { "# QA Principles\n\n## Checklist\n\n### Test Coverage\n\n- New code has tests\n" }

    before do
      stub_const("#{described_class}::REPO_ROOT", tmpdir)
      stub_const("#{described_class}::PRINCIPLES_DIR", '.ai/principles/distilled')
      FileUtils.mkdir_p(principles_dir)

      allow(described_class).to receive(:parallel_distill)
        .and_return({ 'qa' => [existing_content, distilled_content] })
    end

    it 'writes the file with frontmatter, header, content, and sources footer', :aggregate_failures do
      described_class.distill_and_write_principles(manifest, affected)

      written = File.read(File.join(principles_dir, 'qa.md'))

      expect(written).to start_with("---\nsource_checksum:")
      expect(written).to include('<!-- Auto-generated from docs.gitlab.com')
      expect(written).to include('### Test Coverage')
      expect(written).to include('## Authoritative sources')
      expect(written).to include('- doc/development/testing_guide/best_practices.md')
    end

    it 'returns updated principles and no failures', :aggregate_failures do
      updated, failed = described_class.distill_and_write_principles(manifest, affected)

      expect(updated.keys).to eq(['qa'])
      expect(failed).to be_empty
    end

    context 'when distillation fails' do
      before do
        allow(described_class).to receive(:parallel_distill)
          .and_return({ 'qa' => [nil, nil] })
      end

      it 'reports failure', :aggregate_failures do
        updated, failed = described_class.distill_and_write_principles(manifest, affected)

        expect(updated).to be_empty
        expect(failed).to eq(['qa'])
      end
    end

    context 'when content has no meaningful diff from existing file' do
      before do
        allow(described_class).to receive(:parallel_distill)
          .and_return({ 'qa' => [distilled_content, distilled_content] })
      end

      it 'skips the file', :aggregate_failures do
        updated, failed = described_class.distill_and_write_principles(manifest, affected)

        expect(updated).to be_empty
        expect(failed).to be_empty
      end
    end

    context 'when the distilled file does not exist yet (current is nil)' do
      before do
        allow(described_class).to receive(:parallel_distill)
          .and_return({ 'qa' => [nil, distilled_content] })
      end

      it 'writes the new file' do
        described_class.distill_and_write_principles(manifest, affected)

        expect(File.exist?(File.join(principles_dir, 'qa.md'))).to be true
      end

      it 'returns the new principle as updated and reports no failures', :aggregate_failures do
        updated, failed = described_class.distill_and_write_principles(manifest, affected)

        expect(updated.keys).to eq(['qa'])
        expect(failed).to be_empty
      end
    end
  end

  describe '.seed_current_agent' do
    let(:tmpdir) { mktmpdir }

    before do
      stub_const("#{described_class}::REPO_ROOT", tmpdir)
      stub_const("#{described_class}::PRINCIPLES_DIR", '.ai/principles/distilled')
      described_class.file_cache = {}
    end

    context 'when the distilled file exists' do
      before do
        FileUtils.mkdir_p(File.join(tmpdir, '.ai/principles/distilled'))
        File.write(File.join(tmpdir, '.ai/principles/distilled/qa-rspec.md'),
          "---\nsource_checksum: abc\n---\n# QA RSpec Principles\n\n## Checklist\n")
      end

      it 'returns the stripped file content' do
        result = described_class.seed_current_agent('qa-rspec', {}, nil)

        expect(result).to start_with('# QA RSpec Principles')
      end
    end

    context 'when the distilled file does not exist' do
      context 'when config has a description' do
        let(:config) { { 'description' => 'RSpec patterns, factories, shared examples' } }

        it 'uses the description as the title' do
          result = described_class.seed_current_agent('qa-rspec', config, nil)

          expect(result).to start_with('# RSpec patterns, factories, shared examples Principles')
        end
      end

      context 'when config has no description' do
        it 'falls back to a slug-derived title' do
          result = described_class.seed_current_agent('qa-rspec', {}, nil)

          expect(result).to start_with('# Qa Rspec Principles')
        end
      end
    end
  end

  describe '.agents_md_content' do
    subject(:content) { described_class.agents_md_content(refs) }

    let(:refs) { '@.ai/principles/distilled/backend.md' }

    it 'includes the auto-generated header' do
      expect(content).to start_with(described_class::AGENTS_MD_HEADER)
    end

    it 'includes the principle references' do
      expect(content).to include(refs)
    end

    it 'includes markdownlint and vale directives', :aggregate_failures do
      expect(content).to include('<!-- markdownlint-disable -->')
      expect(content).to include('<!-- vale off -->')
    end
  end

  describe '.generate_principles_skill' do
    let(:tmpdir) { mktmpdir }
    let(:agents_skill_path) { File.join(tmpdir, '.agents/skills/gitlab-coding-principles/SKILL.md') }
    let(:claude_skill_path) { File.join(tmpdir, '.claude/skills/gitlab-coding-principles/SKILL.md') }
    let(:manifest) do
      {
        'principles' => {
          'backend' => { 'group' => 'Backend', 'description' => 'Backend Ruby/Rails',
                         'file_filters' => ['app/**/*.rb'] },
          'security' => { 'group' => 'Security', 'description' => 'Security vulnerabilities',
                          'file_filters' => ['**/*'] }
        },
        'static_entries' => []
      }
    end

    before do
      stub_const("#{described_class}::REPO_ROOT", tmpdir)
      described_class.generate_principles_skill(manifest)
    end

    it 'writes SKILL.md to both .agents/skills/ and .claude/skills/', :aggregate_failures do
      expect(File.exist?(agents_skill_path)).to be true
      expect(File.exist?(claude_skill_path)).to be true
    end

    it 'generates identical content in both locations' do
      expect(File.read(agents_skill_path)).to eq(File.read(claude_skill_path))
    end

    it 'includes YAML frontmatter with name and description', :aggregate_failures do
      content = File.read(claude_skill_path)

      expect(content).to include('name: gitlab-coding-principles')
      expect(content).to include('description: Load all relevant GitLab development principles')
    end

    it 'includes principle entries from manifest', :aggregate_failures do
      content = File.read(claude_skill_path)

      expect(content).to include('Backend Ruby/Rails')
      expect(content).to include('Security vulnerabilities')
      expect(content).to include('.ai/principles/distilled/backend.md')
    end

    context 'when skill files are already up to date' do
      it 'does not rewrite them' do
        mtime_before = File.mtime(claude_skill_path)
        sleep 0.01
        described_class.generate_principles_skill(manifest)

        expect(File.mtime(claude_skill_path)).to eq(mtime_before)
      end
    end
  end

  describe '.extract_frontmatter' do
    subject(:extract_frontmatter) { described_class.extract_frontmatter(content) }

    context 'with YAML frontmatter' do
      let(:content) { "---\nsource_checksum: abc123\n---\n# Title\nBody" }

      it { is_expected.to eq({ 'source_checksum' => 'abc123' }) }
    end

    context 'without frontmatter' do
      let(:content) { '# Title\nBody' }

      it { is_expected.to be_nil }
    end

    context 'when content does not start with ---' do
      let(:content) { 'some text\n---\nmore' }

      it { is_expected.to be_nil }
    end
  end

  describe '.strip_frontmatter' do
    subject(:strip_frontmatter) { described_class.strip_frontmatter(content) }

    context 'with YAML frontmatter' do
      let(:content) { "---\nsource_checksum: abc123\n---\n# Title\nBody" }

      it { is_expected.to eq("# Title\nBody") }
    end

    context 'without frontmatter' do
      let(:content) { "# Title\nBody" }

      it { is_expected.to eq(content) }
    end

    context 'with leading whitespace after frontmatter' do
      let(:content) { "---\nkey: val\n---\n\n\n# Title" }

      it { is_expected.to eq('# Title') }
    end
  end

  describe '.compute_checksum' do
    subject(:checksum) { described_class.compute_checksum(config) }

    let(:tmpdir) { mktmpdir }

    before do
      stub_const("#{described_class}::REPO_ROOT", tmpdir)
    end

    context 'with no sources' do
      let(:config) { { 'sources' => [] } }

      it { is_expected.to match(/\A[a-f0-9]{16}\z/) }
    end

    context 'when source content changes' do
      let(:config) { { 'sources' => [{ 'path' => 'doc.md' }] } }

      it 'changes the checksum' do
        source_path = File.join(tmpdir, 'doc.md')
        File.write(source_path, 'original content')

        checksum1 = checksum

        described_class.file_cache = {}
        File.write(source_path, 'modified content')

        expect(described_class.compute_checksum(config)).not_to eq(checksum1)
      end
    end

    context 'with a baseline file' do
      let(:config) { { 'sources' => [], 'baseline' => 'baseline.md' } }

      before do
        File.write(File.join(tmpdir, 'baseline.md'), 'baseline rules')
      end

      it 'includes baseline content in checksum' do
        checksum_without = described_class.compute_checksum({ 'sources' => [] })

        expect(checksum).not_to eq(checksum_without)
      end
    end

    context 'when description changes' do
      it 'changes the checksum' do
        with_desc_a = described_class.compute_checksum({ 'sources' => [], 'description' => 'A' })
        with_desc_b = described_class.compute_checksum({ 'sources' => [], 'description' => 'B' })

        expect(with_desc_a).not_to eq(with_desc_b)
      end
    end

    context 'when group changes' do
      it 'changes the checksum' do
        in_group_a = described_class.compute_checksum({ 'sources' => [], 'group' => 'Backend' })
        in_group_b = described_class.compute_checksum({ 'sources' => [], 'group' => 'Database' })

        expect(in_group_a).not_to eq(in_group_b)
      end
    end

    context 'when prerequisite flag changes' do
      it 'changes the checksum' do
        as_prereq = described_class.compute_checksum({ 'sources' => [], 'prerequisite' => true })
        not_prereq = described_class.compute_checksum({ 'sources' => [], 'prerequisite' => false })

        expect(as_prereq).not_to eq(not_prereq)
      end
    end

    context 'when file_filters change' do
      it 'changes the checksum' do
        with_filters_a = described_class.compute_checksum({ 'sources' => [], 'file_filters' => ['app/**/*.rb'] })
        with_filters_b = described_class.compute_checksum({ 'sources' => [], 'file_filters' => ['lib/**/*.rb'] })

        expect(with_filters_a).not_to eq(with_filters_b)
      end
    end
  end

  describe '.load_distillation_prompt' do
    subject(:load_prompt) { described_class.load_distillation_prompt }

    let(:tmpdir) { mktmpdir }
    let(:prompt_path) { File.join(tmpdir, described_class::DISTILLATION_PROMPT_PATH) }

    before do
      stub_const("#{described_class}::REPO_ROOT", tmpdir)
      FileUtils.mkdir_p(File.join(tmpdir, File.dirname(described_class::DISTILLATION_PROMPT_PATH)))
    end

    context 'with valid prompt containing separator' do
      before do
        File.write(prompt_path, "Main prompt\n\n#{described_class::BASELINE_SEPARATOR}\n\nBaseline template")
      end

      it 'splits prompt on BASELINE_SEPARATOR and returns two parts', :aggregate_failures do
        main, baseline = load_prompt

        expect(main).to eq('Main prompt')
        expect(baseline).to eq('Baseline template')
      end
    end

    context 'when separator is missing' do
      before do
        File.write(prompt_path, 'No separator here')
      end

      it 'aborts' do
        expect { load_prompt }.to raise_error(SystemExit)
      end
    end
  end

  describe '.resolve_duo_backend' do
    subject(:backend) { described_class.resolve_duo_backend }

    context 'when GITLAB_DUO_API_TOKEN is set' do
      before do
        stub_env('GITLAB_DUO_API_TOKEN', 'token-abc')
      end

      it 'returns the API backend' do
        expect(backend).to eq({ type: :api, token: 'token-abc' })
      end

      it 'does not check for the CLI' do
        expect(described_class).not_to receive(:cli_available?)
        backend
      end
    end

    context 'when GITLAB_DUO_API_TOKEN is empty and the CLI is available' do
      before do
        stub_env('GITLAB_DUO_API_TOKEN', '')
        stub_env('DUO_CLI_PATH', 'duo')
        allow(described_class).to receive(:cli_available?).with('duo').and_return(true)
      end

      it 'returns the CLI backend' do
        expect(backend).to eq({ type: :cli, path: 'duo' })
      end
    end

    context 'when GITLAB_DUO_API_TOKEN is empty and the CLI is not available' do
      before do
        stub_env('GITLAB_DUO_API_TOKEN', '')
        stub_env('DUO_CLI_PATH', 'duo')
        allow(described_class).to receive(:cli_available?).with('duo').and_return(false)
      end

      it 'returns nil' do
        expect(backend).to be_nil
      end
    end

    context 'when DUO_CLI_PATH is set to a custom path' do
      before do
        stub_env('GITLAB_DUO_API_TOKEN', '')
        stub_env('DUO_CLI_PATH', '/custom/duo')
        allow(described_class).to receive(:cli_available?).with('/custom/duo').and_return(true)
      end

      it 'uses the custom path in the CLI backend' do
        expect(backend).to eq({ type: :cli, path: '/custom/duo' })
      end
    end

    def stub_env(key, value)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with(key, anything) { |_, default| value || default }
      allow(ENV).to receive(:fetch).with(key) { value }
    end
  end

  describe '.parse_duo_cli_output' do
    subject(:result) { described_class.parse_duo_cli_output(output) }

    context 'with a well-formed complete message' do
      let(:output) do
        <<~LOG
          [RunController] {
            "isComplete": true,
            "content": "# Title\\n\\n## Checklist\\n"
          }
        LOG
      end

      it { is_expected.to eq("# Title\n\n## Checklist\n") }
    end

    context 'with multiple RunController blocks, only last is complete' do
      let(:output) do
        <<~LOG
          [RunController] {
            "isComplete": false,
            "content": "partial"
          }
          [RunController] {
            "isComplete": true,
            "content": "# Final\\n"
          }
        LOG
      end

      it 'returns the last complete message' do
        expect(result).to eq("# Final\n")
      end
    end

    context 'when no message has isComplete: true' do
      let(:output) do
        <<~LOG
          [RunController] {
            "isComplete": false,
            "content": "nope"
          }
        LOG
      end

      it { is_expected.to be_nil }
    end

    context 'with malformed JSON inside a RunController block' do
      let(:output) do
        <<~LOG
          [RunController] {
            not valid json
          }
        LOG
      end

      it 'returns nil without raising' do
        expect(result).to be_nil
      end
    end

    context 'with empty output' do
      let(:output) { '' }

      it { is_expected.to be_nil }
    end

    context 'with output containing no RunController lines' do
      let(:output) { "Some other log output\nInfo: doing things\n" }

      it { is_expected.to be_nil }
    end
  end

  describe '.strip_preamble' do
    subject(:strip_preamble) { described_class.strip_preamble(content) }

    context 'with content before the first heading' do
      let(:content) { "Some preamble\nMore text\n# Title\n\nBody" }

      it { is_expected.to eq("# Title\n\nBody\n") }
    end

    context 'with trailing ## Output Format sentinel' do
      let(:content) { "# Title\n\n- Item 1\n\n## Output Format" }

      it { is_expected.to eq("# Title\n\n- Item 1\n") }
    end

    context 'with ## Output Format and trailing whitespace' do
      let(:content) { "# Title\n\n- Item 1\n\n## Output Format  \n" }

      it { is_expected.to eq("# Title\n\n- Item 1\n") }
    end

    context 'without trailing newline' do
      let(:content) { "# Title\n\n- Item 1" }

      it { is_expected.to end_with("\n") }
    end

    context 'without preamble' do
      let(:content) { "# Title\n\nBody" }

      it { is_expected.to eq("# Title\n\nBody\n") }
    end
  end

  describe '.reduce_diff_noise' do
    subject(:result) { described_class.reduce_diff_noise(old_content, new_content) }

    context 'when new line is a close rephrase' do
      let(:old_content) { "### Section A\n\n- Query changes validated for performance at GitLab.com scale\n" }
      let(:new_content) { "### Section A\n\n- Query changes must be validated for performance at GitLab.com scale\n" }

      it 'keeps old wording', :aggregate_failures do
        expect(result).to include('- Query changes validated for performance at GitLab.com scale')
        expect(result).not_to include('must be')
      end
    end

    context 'when new line is substantially different' do
      let(:old_content) { "### Section A\n\n- Use foo\n" }
      let(:new_content) { "### Section A\n\n- Completely different rule about bar\n" }

      it 'keeps new wording' do
        expect(result).to include('- Completely different rule about bar')
      end
    end

    context 'when new lines are added' do
      let(:old_content) { "### Section A\n\n- Existing rule\n" }
      let(:new_content) { "### Section A\n\n- Existing rule\n- Brand new rule\n" }

      it 'preserves genuinely new lines', :aggregate_failures do
        expect(result).to include('- Existing rule')
        expect(result).to include('- Brand new rule')
      end
    end

    context 'when new sections are added' do
      let(:old_content) { "### Section A\n\n- Item 1\n" }
      let(:new_content) { "### Section A\n\n- Item 1\n\n### Section B\n\n- New item\n" }

      it 'keeps new sections entirely', :aggregate_failures do
        expect(result).to include('### Section B')
        expect(result).to include('- New item')
      end
    end

    context 'when sections are removed' do
      let(:old_content) { "### Section A\n\n- Item 1\n\n### Section B\n\n- Item 2\n" }
      let(:new_content) { "### Section A\n\n- Item 1\n" }

      it 'drops sections removed by Duo', :aggregate_failures do
        expect(result).not_to include('### Section B')
        expect(result).not_to include('- Item 2')
      end
    end
  end

  describe '.parse_sections' do
    subject(:sections) { described_class.parse_sections(content) }

    context 'with multiple ### headings' do
      let(:content) { "# Title\n\n## Checklist\n\n### Section A\n\n- Item 1\n\n### Section B\n\n- Item 2\n" }

      it 'splits content by ### headings', :aggregate_failures do
        expect(sections.keys).to eq([nil, '### Section A', '### Section B'])
        expect(sections['### Section A']).to include('- Item 1')
        expect(sections['### Section B']).to include('- Item 2')
      end
    end

    context 'with preamble before first ### heading' do
      let(:content) { "# Title\n\n### Section\n\n- Item" }

      it 'puts preamble under nil key' do
        expect(sections[nil]).to eq(['# Title', ''])
      end
    end
  end

  describe '.word_similarity' do
    subject(:similarity) { described_class.word_similarity(line_a, line_b) }

    context 'with identical lines' do
      let(:line_a) { '- Use foo bar' }
      let(:line_b) { '- Use foo bar' }

      it { is_expected.to eq(1.0) }
    end

    context 'with completely different lines' do
      let(:line_a) { '- Alpha beta' }
      let(:line_b) { '- Gamma delta' }

      it { is_expected.to eq(0.0) }
    end

    context 'with two empty strings' do
      let(:line_a) { '' }
      let(:line_b) { '' }

      it { is_expected.to eq(0.0) }
    end

    context 'with partially overlapping words' do
      let(:line_a) { '- Use foo bar' }
      let(:line_b) { '- Use foo baz' }

      it 'calculates Jaccard similarity on word sets' do
        # words: [use, foo, bar] vs [use, foo, baz] => intersection=2, union=4 => 0.5
        expect(similarity).to eq(0.5)
      end
    end

    context 'with punctuation and case differences' do
      let(:line_a) { '- Use `Gitlab::SafeRequestStore` for memoization' }
      let(:line_b) { '- use gitlabsaferequeststore for memoization' }

      it { is_expected.to eq(1.0) }
    end
  end

  describe '.find_best_match' do
    subject(:best_match) { described_class.find_best_match(line, candidates) }

    context 'with matching candidates' do
      let(:line) { '- Use foo baz' }
      let(:candidates) { ['- Use foo bar', '- Completely different'] }

      it 'returns the best matching candidate and score', :aggregate_failures do
        match, score = best_match

        expect(match).to eq('- Use foo bar')
        expect(score).to be >= 0.5
      end
    end

    context 'with empty candidates' do
      let(:line) { '- Some line' }
      let(:candidates) { [] }

      it 'returns nil and 0.0', :aggregate_failures do
        match, score = best_match

        expect(match).to be_nil
        expect(score).to eq(0.0)
      end
    end
  end

  describe '.generate_agents_md_context_loading' do
    let(:tmpdir) { mktmpdir }
    let(:manifest) do
      {
        'principles' => {
          'database-queries' => { 'description' => 'SQL performance', 'group' => 'Database' },
          'database-schema' => { 'description' => 'Column types', 'group' => 'Database' },
          'backend-ruby' => { 'description' => 'Ruby style', 'group' => 'Backend' }
        },
        'static_entries' => [
          { 'description' => 'Git conventions', 'path' => '.ai/git.md' }
        ]
      }
    end

    let(:agents_md_content) do
      <<~MD
        # GitLab Project Guidelines

        ## Context Loading

        <!-- BEGIN GENERATED: scripts/ai/sync_principles.rb — do not edit manually -->
        ### OpenCode

        Old content that should be replaced.

        <!-- END GENERATED -->

        ### Claude Code

        Skip this section.
      MD
    end

    before do
      stub_const("#{described_class}::REPO_ROOT", tmpdir)
      File.write(File.join(tmpdir, 'AGENTS.md'), agents_md_content)
      File.write(File.join(tmpdir, 'CLAUDE.md'), agents_md_content)
    end

    it 'replaces the generated section with grouped principles' do
      described_class.generate_agents_md_context_loading(manifest)

      content = File.read(File.join(tmpdir, 'AGENTS.md'))

      expect(content).to include('<!-- BEGIN GENERATED: scripts/ai/sync_principles.rb — do not edit manually -->')
      expect(content).to include('<!-- END GENERATED -->')
      expect(content).to include('**Database:**')
      expect(content).to include('**Backend:**')
      expect(content).to include('- **SQL performance**: Read .ai/principles/distilled/database-queries.md')
      expect(content).to include('- **Ruby style**: Read .ai/principles/distilled/backend-ruby.md')
      expect(content).to include('- **Git conventions**: Read .ai/git.md')
      expect(content).not_to include('Old content that should be replaced')
    end

    it 'preserves group order from first appearance in manifest' do
      described_class.generate_agents_md_context_loading(manifest)

      content = File.read(File.join(tmpdir, 'AGENTS.md'))
      database_pos = content.index('**Database:**')
      backend_pos = content.index('**Backend:**')

      expect(database_pos).to be < backend_pos
    end

    it 'keeps CLAUDE.md identical to AGENTS.md' do
      described_class.generate_agents_md_context_loading(manifest)

      expect(File.read(File.join(tmpdir, 'AGENTS.md')))
        .to eq(File.read(File.join(tmpdir, 'CLAUDE.md')))
    end

    it 'does nothing when AGENTS.md does not exist' do
      File.delete(File.join(tmpdir, 'AGENTS.md'))

      expect { described_class.generate_agents_md_context_loading(manifest) }.not_to raise_error
    end

    it 'does nothing when content is unchanged' do
      described_class.generate_agents_md_context_loading(manifest)
      mtime_before = File.mtime(File.join(tmpdir, 'AGENTS.md'))

      sleep(0.01)
      described_class.generate_agents_md_context_loading(manifest)
      mtime_after = File.mtime(File.join(tmpdir, 'AGENTS.md'))

      expect(mtime_after).to eq(mtime_before)
    end
  end

  describe '.collect_ssot_docs source validation' do
    let(:tmpdir) { mktmpdir }

    before do
      stub_const("#{described_class}::REPO_ROOT", tmpdir)
      described_class.file_cache = {}
    end

    context 'when a source file does not exist' do
      let(:config) do
        { 'sources' => [{ 'path' => 'doc/missing.md', 'url' => 'https://example.com' }] }
      end

      it 'raises an error with the missing path' do
        expect { described_class.collect_ssot_docs(config) }
          .to raise_error(RuntimeError, %r{SSOT source file not found: doc/missing.md})
      end
    end

    context 'when all source files exist' do
      let(:config) do
        { 'sources' => [{ 'path' => 'doc/existing.md', 'url' => 'https://example.com' }] }
      end

      before do
        FileUtils.mkdir_p(File.join(tmpdir, 'doc'))
        File.write(File.join(tmpdir, 'doc/existing.md'), '# Content')
      end

      it 'does not raise' do
        expect { described_class.collect_ssot_docs(config) }.not_to raise_error
      end
    end
  end

  describe '.meaningful_diff?' do
    subject(:meaningful_diff) { described_class.meaningful_diff?(current, updated) }

    context 'when current is nil (new file)' do
      let(:current) { nil }
      let(:updated) { 'content' }

      it { is_expected.to be true }
    end

    context 'when updated is nil (distillation failure)' do
      let(:current) { 'content' }
      let(:updated) { nil }

      it { is_expected.to be false }
    end

    context 'when both are nil' do
      let(:current) { nil }
      let(:updated) { nil }

      it { is_expected.to be false }
    end

    context 'with whitespace-only differences' do
      let(:current) { "- Item 1\n\n" }
      let(:updated) { "- Item 1\n" }

      it { is_expected.to be false }
    end

    context 'with different content' do
      let(:current) { "- Item 1\n" }
      let(:updated) { "- Item 2\n" }

      it { is_expected.to be true }
    end
  end

  describe '.dirty_generated_paths' do
    # Stubs both backtick invocations: `git diff` (modified files) and
    # `git ls-files --others` (untracked files) used by the helper.
    def stub_git_calls(modified: '', untracked: '')
      allow(described_class).to receive(:`) do |cmd|
        if cmd.include?('ls-files --others')
          untracked
        elsif cmd.include?('diff --name-only')
          modified
        else
          ''
        end
      end
    end

    context 'when GENERATED_PATHS files have no uncommitted changes' do
      before do
        stub_git_calls
      end

      it { expect(described_class.dirty_generated_paths).to be_empty }
    end

    context 'when some GENERATED_PATHS files have uncommitted modifications' do
      before do
        stub_git_calls(modified: "AGENTS.md\n.ai/principles/distilled/qa-rspec.md\n")
      end

      it 'returns the modified paths' do
        expect(described_class.dirty_generated_paths)
          .to match_array(['AGENTS.md', '.ai/principles/distilled/qa-rspec.md'])
      end
    end

    context 'when GENERATED_PATHS contain untracked files' do
      before do
        stub_git_calls(untracked: ".claude/skills/gitlab-coding-principles/SKILL.md\n")
      end

      it 'returns the untracked paths' do
        expect(described_class.dirty_generated_paths)
          .to match_array(['.claude/skills/gitlab-coding-principles/SKILL.md'])
      end
    end

    context 'when both modified and untracked files exist' do
      before do
        stub_git_calls(
          modified: "AGENTS.md\n",
          untracked: ".agents/skills/gitlab-coding-principles/SKILL.md\n"
        )
      end

      it 'returns both, deduplicated' do
        expect(described_class.dirty_generated_paths)
          .to match_array(['AGENTS.md', '.agents/skills/gitlab-coding-principles/SKILL.md'])
      end
    end

    context 'when the same path appears in both lists' do
      before do
        stub_git_calls(modified: "AGENTS.md\n", untracked: "AGENTS.md\n")
      end

      it 'deduplicates' do
        expect(described_class.dirty_generated_paths).to match_array(['AGENTS.md'])
      end
    end
  end

  describe '.build_diff_hint' do
    subject(:hint) { described_class.build_diff_hint(sha, source_paths) }

    let(:sha) { 'abc123def456' }

    context 'with simple paths' do
      let(:source_paths) { ['doc/development/sql.md', 'doc/development/database/query_performance.md'] }

      it 'produces a valid shelljoin git diff command' do
        expected = 'git diff abc123def456..HEAD -- ' \
          'doc/development/sql.md doc/development/database/query_performance.md'
        expect(hint).to eq(expected)
      end
    end

    context 'with a path containing spaces' do
      let(:source_paths) { ['doc/my dir/file.md'] }

      it 'shell-escapes the path so it is safe to copy-paste' do
        expect(hint).not_to include('doc/my dir/file.md')
      end
    end
  end

  describe '.read_repo_file (thread safety)' do
    let(:tmpdir) { mktmpdir }

    before do
      stub_const("#{described_class}::REPO_ROOT", tmpdir)
      described_class.file_cache = {}
      File.write(File.join(tmpdir, 'shared.md'), 'content')
    end

    it 'returns the same content from all threads and caches it exactly once' do
      results = Array.new(10)
      threads = Array.new(10) do |i|
        Thread.new { results[i] = described_class.read_repo_file('shared.md') }
      end
      threads.each(&:join)

      expect(results).to all(eq('content'))
      expect(described_class.file_cache.keys).to eq(['shared.md'])
    end
  end

  describe 'MAX_CONCURRENT_DISTILLATIONS' do
    subject(:cap) { described_class::MAX_CONCURRENT_DISTILLATIONS }

    it 'is a positive integer' do
      expect(cap).to be_a(Integer).and(be_positive)
    end

    it 'is small enough to avoid overwhelming the Duo API' do
      expect(cap).to be <= 8
    end
  end

  describe 'GENERATED_PATHS' do
    subject(:paths) { described_class::GENERATED_PATHS }

    it 'includes the distilled principles directory' do
      expect(paths).to include(described_class::PRINCIPLES_DIR)
    end

    it 'includes the agents skill directory' do
      expect(paths).to include('.agents/skills/gitlab-coding-principles')
    end

    it 'includes the claude skill directory' do
      expect(paths).to include(described_class::CLAUDE_SKILL_DIR)
    end

    it 'includes AGENTS.md and CLAUDE.md' do
      expect(paths).to include('AGENTS.md', 'CLAUDE.md')
    end
  end

  describe '.parse_options' do
    def parse(*args)
      original_argv = ARGV.dup
      ARGV.replace(args)
      described_class.parse_options
    ensure
      ARGV.replace(original_argv)
    end

    it 'defaults push to false (absent from result)' do
      expect(parse[:push]).to be_nil
    end

    it 'sets push: true when --push is passed' do
      expect(parse('--push')[:push]).to be true
    end

    it 'sets force: true when --force is passed' do
      expect(parse('--force')[:force]).to be true
    end

    it 'sets dry_run: true when --dry-run is passed' do
      expect(parse('--dry-run')[:dry_run]).to be true
    end

    it 'sets only: array when --only is passed' do
      expect(parse('--only', 'backend,qa')[:only]).to eq(%w[backend qa])
    end

    it 'sets rewrite: true when --rewrite is passed' do
      expect(parse('--rewrite')[:rewrite]).to be true
    end
  end
end
