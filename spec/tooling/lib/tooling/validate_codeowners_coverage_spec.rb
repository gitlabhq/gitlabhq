# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require_relative '../../../../tooling/lib/tooling/validate_codeowners_coverage'

RSpec.describe Tooling::ValidateCodeownersCoverage, feature_category: :tooling do
  let(:codeowners_file) { Tempfile.new('CODEOWNERS') }
  let(:git_ls_tree_output) do
    <<~DIRS
      .github
      .gitlab
      app
      changelogs
      db
      doc
    DIRS
  end

  let(:codeowners_content) do
    <<~CODEOWNERS
      * @everyone

      [Backend] @backend-team
      /app/ @backend-team
      /db/ @database-team
      /.gitlab/ @pipeline-team

      ^[Documentation]
      /doc/ @docs-team

      !/.gitlab/issue_templates/*.md
    CODEOWNERS
  end

  let(:config) { { 'excluded_directories' => ['changelogs', '.github'] } }
  let(:config_file) { Tempfile.new('config.yml') }
  let(:codeowners_path) { codeowners_file.path }
  let(:config_path) { config_file.path }

  subject(:validator) { described_class.new(codeowners_path: codeowners_path, config_path: config_path) }

  before do
    codeowners_file.write(codeowners_content)
    codeowners_file.flush
    config_file.write(config.to_yaml)
    config_file.flush
    allow(validator).to receive(:git_ls_tree).and_return(git_ls_tree_output)
  end

  after do
    codeowners_file.close!
    config_file.close!
  end

  describe '#missing_coverage' do
    context 'when all directories have explicit entries' do
      it 'returns an empty array' do
        expect(validator.missing_coverage).to be_empty
      end
    end

    context 'when a directory lacks an explicit entry' do
      let(:config) { { 'excluded_directories' => [] } }

      it 'returns the missing directories' do
        # .gitlab/ has an explicit entry in codeowners_content so it is not missing
        expect(validator.missing_coverage).to contain_exactly('.github', 'changelogs')
      end
    end

    context 'with CODEOWNERS entry matching' do
      let(:config) { { 'excluded_directories' => ['.github', '.gitlab', 'db', 'doc', 'changelogs'] } }

      context 'when the directory has a direct entry' do
        let(:codeowners_content) { "/app/ @backend-team\n" }

        it 'treats it as covered' do
          expect(validator.missing_coverage).to be_empty
        end
      end

      context 'when the entry is for a sub-path' do
        let(:codeowners_content) { "/app/assets/ @frontend-team\n" }

        it 'treats it as not covering the parent directory' do
          expect(validator.missing_coverage).to contain_exactly('app')
        end
      end

      context 'when the entry is a catch-all * rule' do
        let(:codeowners_content) { "* @everyone\n" }

        it 'does not treat it as explicit coverage' do
          expect(validator.missing_coverage).to contain_exactly('app')
        end
      end

      context 'when the entry is a negation rule' do
        let(:config) { { 'excluded_directories' => ['.github', '.gitlab', 'db', 'app', 'changelogs'] } }
        let(:codeowners_content) { "!/doc/**/*.md\n" }

        it 'does not treat it as explicit coverage' do
          expect(validator.missing_coverage).to contain_exactly('doc')
        end
      end

      context 'when the entry is a section header' do
        let(:codeowners_content) { "[Backend] @backend-team\n^[Frontend] @frontend-team\n" }

        it 'does not treat it as explicit coverage' do
          expect(validator.missing_coverage).to contain_exactly('app')
        end
      end

      context 'when the entry is for a similarly named directory' do
        let(:codeowners_content) { "/apparel/ @team\n" }

        it 'does not treat it as coverage for the directory' do
          expect(validator.missing_coverage).to contain_exactly('app')
        end
      end

      context 'when the line is a comment' do
        let(:codeowners_content) { "# /app/ is not included\n" }

        it 'does not treat it as explicit coverage' do
          expect(validator.missing_coverage).to contain_exactly('app')
        end
      end
    end

    it 'invokes git ls-tree to list top-level directories from HEAD' do
      unstubbed_validator = described_class.new(codeowners_path: codeowners_path, config_path: config_path)

      expect(IO).to receive(:popen)
        .with(%w[git ls-tree --name-only -d HEAD])
        .and_yield(StringIO.new(git_ls_tree_output))

      unstubbed_validator.missing_coverage
    end
  end

  describe '#covered_exclusions' do
    context 'when no excluded directory has an explicit entry' do
      it 'returns an empty array' do
        # config excludes 'changelogs' and '.github', neither has an explicit entry
        expect(validator.covered_exclusions).to be_empty
      end
    end

    context 'when an excluded directory has an explicit CODEOWNERS entry' do
      let(:config) { { 'excluded_directories' => ['changelogs', '.gitlab'] } }

      it 'returns the covered excluded directories' do
        expect(validator.covered_exclusions).to contain_exactly('.gitlab')
      end
    end

    context 'when multiple excluded directories have explicit entries' do
      let(:config) { { 'excluded_directories' => %w[app db changelogs] } }

      it 'returns all covered excluded directories' do
        expect(validator.covered_exclusions).to contain_exactly('app', 'db')
      end
    end

    context 'when excluded_directories is empty' do
      let(:config) { { 'excluded_directories' => [] } }

      it 'returns an empty array' do
        expect(validator.covered_exclusions).to be_empty
      end
    end
  end
end
