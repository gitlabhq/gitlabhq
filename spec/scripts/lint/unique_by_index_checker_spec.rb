# frozen_string_literal: true

require 'fast_spec_helper'
require 'open3'

require_relative '../../../scripts/lint/check_unique_by_indexes'

RSpec.describe UniqueByIndexChecker, feature_category: :tooling do
  let(:checker) { described_class.new }
  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  describe '#run' do
    before do
      allow(checker).to receive(:changed_files).and_return(changed_files)
    end

    context 'when no files changed' do
      let(:changed_files) { [] }

      it 'returns 0' do
        expect(checker.run).to eq(0)
      end
    end

    context 'when only non-code files changed' do
      let(:changed_files) { ['db/post_migrate/123_add_index.rb', 'spec/models/user_spec.rb'] }

      it 'returns 0' do
        expect(checker.run).to eq(0)
      end
    end

    context 'when code adds unique_by matching index in base schema' do
      let(:changed_files) { ['app/services/foo_service.rb'] }

      let(:code_diff) do
        <<~DIFF
          +        unique_by: %i[project_id fingerprint]
        DIFF
      end

      let(:base_structure) do
        <<~SQL
          CREATE UNIQUE INDEX idx_on_project_fingerprint ON some_table USING btree (project_id, fingerprint);
        SQL
      end

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(Open3).to receive(:capture3).with('git', 'diff', anything, '--', anything)
          .and_return([code_diff, '', success_status])
        allow(Open3).to receive(:capture3).with('git', 'show', anything)
          .and_return([base_structure, '', success_status])
      end

      it 'returns 0 (index already deployed)' do
        expect(checker.run).to eq(0)
      end
    end

    context 'when code adds unique_by matching index in db/migrate/' do
      let(:changed_files) do
        ['app/services/foo_service.rb', 'db/migrate/123_add_index.rb']
      end

      let(:code_diff) do
        <<~DIFF
          +        unique_by: %i[project_id user_id]
        DIFF
      end

      let(:base_structure) { '' }

      let(:migrate_content) do
        <<~RUBY
          add_concurrent_index :some_table, %i[project_id user_id], unique: true
        RUBY
      end

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(Open3).to receive(:capture3).with('git', 'diff', anything, '--', anything)
          .and_return([code_diff, '', success_status])
        allow(Open3).to receive(:capture3).with('git', 'show', anything)
          .and_return([base_structure, '', success_status])
        allow(File).to receive(:read).with('db/migrate/123_add_index.rb').and_return(migrate_content)
      end

      it 'returns 0 (index added in migrate, runs before code deploy)' do
        expect(checker.run).to eq(0)
      end
    end

    context 'when code adds unique_by with index only in db/post_migrate/' do
      let(:changed_files) do
        ['app/services/foo_service.rb', 'db/post_migrate/123_add_index.rb']
      end

      let(:code_diff) do
        <<~DIFF
          +        unique_by: %i[project_id fingerprint partition_id]
        DIFF
      end

      let(:base_structure) { '' }

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(Open3).to receive(:capture3).with('git', 'diff', anything, '--', anything)
          .and_return([code_diff, '', success_status])
        allow(Open3).to receive(:capture3).with('git', 'show', anything)
          .and_return([base_structure, '', success_status])
      end

      it 'detects violation and returns 1' do
        result = nil
        expect { result = checker.run }
          .to output(/unique_by declarations reference indexes not available at deploy time/).to_stdout
        expect(result).to eq(1)
      end
    end

    context 'when code adds unique_by with no matching index anywhere' do
      let(:changed_files) { ['app/services/foo_service.rb'] }

      let(:code_diff) do
        <<~DIFF
          +        unique_by: %i[nonexistent_col1 nonexistent_col2]
        DIFF
      end

      let(:base_structure) do
        <<~SQL
          CREATE UNIQUE INDEX idx_other ON some_table USING btree (other_col);
        SQL
      end

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(Open3).to receive(:capture3).with('git', 'diff', anything, '--', anything)
          .and_return([code_diff, '', success_status])
        allow(Open3).to receive(:capture3).with('git', 'show', anything)
          .and_return([base_structure, '', success_status])
      end

      it 'detects violation (missing index) and returns 1' do
        result = nil
        expect { result = checker.run }
          .to output(/unique_by declarations reference indexes not available at deploy time/).to_stdout
        expect(result).to eq(1)
      end
    end

    context 'when unique_by uses array syntax [:col1, :col2]' do
      let(:changed_files) { ['app/models/some_model.rb'] }

      let(:code_diff) do
        <<~DIFF
          +        unique_by: [:project_id, :user_id]
        DIFF
      end

      let(:base_structure) do
        <<~SQL
          CREATE UNIQUE INDEX idx_proj_user ON some_table USING btree (project_id, user_id);
        SQL
      end

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(Open3).to receive(:capture3).with('git', 'diff', anything, '--', anything)
          .and_return([code_diff, '', success_status])
        allow(Open3).to receive(:capture3).with('git', 'show', anything)
          .and_return([base_structure, '', success_status])
      end

      it 'matches array syntax against schema' do
        expect(checker.run).to eq(0)
      end
    end

    context 'when unique_by uses single symbol syntax :column' do
      let(:changed_files) { ['app/models/some_model.rb'] }

      let(:code_diff) do
        <<~DIFF
          +        unique_by: :uuid
        DIFF
      end

      let(:base_structure) do
        <<~SQL
          CREATE UNIQUE INDEX idx_uuid ON some_table USING btree (uuid);
        SQL
      end

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(Open3).to receive(:capture3).with('git', 'diff', anything, '--', anything)
          .and_return([code_diff, '', success_status])
        allow(Open3).to receive(:capture3).with('git', 'show', anything)
          .and_return([base_structure, '', success_status])
      end

      it 'matches single symbol syntax against schema' do
        expect(checker.run).to eq(0)
      end
    end

    context 'when unique_by is removed (not added)' do
      let(:changed_files) { ['app/services/foo_service.rb'] }

      let(:code_diff) do
        <<~DIFF
          -        self.unique_by = %i[project_id fingerprint]
        DIFF
      end

      let(:base_structure) { '' }

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(Open3).to receive(:capture3).with('git', 'diff', anything, '--', anything)
          .and_return([code_diff, '', success_status])
        allow(Open3).to receive(:capture3).with('git', 'show', anything)
          .and_return([base_structure, '', success_status])
      end

      it 'does not report violation for removed lines' do
        expect(checker.run).to eq(0)
      end
    end

    context 'when schema has index with WHERE clause' do
      let(:changed_files) { ['app/models/some_model.rb'] }

      let(:code_diff) do
        <<~DIFF
          +        unique_by: [:upstream_id, :group_id, :relative_path]
        DIFF
      end

      let(:base_structure) do
        <<~SQL
          CREATE UNIQUE INDEX idx_uniq ON some_table USING btree (upstream_id, group_id, relative_path) WHERE (status = 0);
        SQL
      end

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(Open3).to receive(:capture3).with('git', 'diff', anything, '--', anything)
          .and_return([code_diff, '', success_status])
        allow(Open3).to receive(:capture3).with('git', 'show', anything)
          .and_return([base_structure, '', success_status])
      end

      it 'matches index columns ignoring WHERE clause' do
        expect(checker.run).to eq(0)
      end
    end

    context 'when schema has partitioned index (ON ONLY)' do
      let(:changed_files) { ['app/models/some_model.rb'] }

      let(:code_diff) do
        <<~DIFF
          +        unique_by: [:relative_path, :object_storage_key, :group_id]
        DIFF
      end

      let(:base_structure) do
        <<~SQL
          CREATE UNIQUE INDEX i_v_container ON ONLY virtual_registries USING btree (relative_path, object_storage_key, group_id);
        SQL
      end

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(Open3).to receive(:capture3).with('git', 'diff', anything, '--', anything)
          .and_return([code_diff, '', success_status])
        allow(Open3).to receive(:capture3).with('git', 'show', anything)
          .and_return([base_structure, '', success_status])
      end

      it 'matches partitioned index syntax' do
        expect(checker.run).to eq(0)
      end
    end

    context 'when schema has unique constraint (ADD CONSTRAINT)' do
      let(:changed_files) { ['app/models/some_model.rb'] }

      let(:code_diff) do
        <<~DIFF
          +        unique_by: [:registry_id, :position]
        DIFF
      end

      let(:base_structure) do
        <<~SQL
          ADD CONSTRAINT constraint_unique_registry_pos UNIQUE (registry_id, "position") DEFERRABLE INITIALLY DEFERRED;
        SQL
      end

      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(Open3).to receive(:capture3).with('git', 'diff', anything, '--', anything)
          .and_return([code_diff, '', success_status])
        allow(Open3).to receive(:capture3).with('git', 'show', anything)
          .and_return([base_structure, '', success_status])
      end

      it 'matches unique constraint syntax' do
        expect(checker.run).to eq(0)
      end
    end
  end

  describe '#run_git_command' do
    context 'when git command succeeds' do
      it 'returns stdout' do
        allow(Open3).to receive(:capture3)
          .with('git', 'status')
          .and_return(["on branch main\n", '', success_status])

        expect(checker.send(:run_git_command, 'status')).to eq("on branch main\n")
      end
    end

    context 'when git command fails' do
      it 'returns empty string and warns' do
        allow(Open3).to receive(:capture3)
          .with('git', 'diff', 'invalid...ref')
          .and_return(['', 'fatal: bad revision', failure_status])

        expect { checker.send(:run_git_command, 'diff', 'invalid...ref') }
          .to output(/Warning: git diff failed/).to_stderr

        expect(checker.send(:run_git_command, 'diff', 'invalid...ref')).to eq('')
      end

      it 'returns empty string without warning when stderr is empty' do
        allow(Open3).to receive(:capture3)
          .with('git', 'diff', 'invalid...ref')
          .and_return(['', '', failure_status])

        expect { checker.send(:run_git_command, 'diff', 'invalid...ref') }
          .not_to output.to_stderr
      end
    end
  end

  describe '#parse_columns' do
    it 'parses space-separated symbols' do
      expect(checker.send(:parse_columns, 'project_id fingerprint')).to eq(%w[fingerprint project_id])
    end

    it 'parses colon-prefixed symbols' do
      expect(checker.send(:parse_columns, ':project_id, :user_id')).to eq(%w[project_id user_id])
    end

    it 'parses single symbol' do
      expect(checker.send(:parse_columns, 'uuid')).to eq(%w[uuid])
    end

    it 'sorts columns alphabetically' do
      expect(checker.send(:parse_columns, 'z_col a_col m_col')).to eq(%w[a_col m_col z_col])
    end
  end

  describe '#parse_sql_columns' do
    it 'parses comma-separated columns' do
      expect(checker.send(:parse_sql_columns, 'project_id, fingerprint')).to eq(%w[fingerprint project_id])
    end

    it 'handles column with type cast' do
      expect(checker.send(:parse_sql_columns, 'project_id, lower(name)')).to eq(%w[lower(name) project_id])
    end

    it 'handles quoted identifiers' do
      expect(checker.send(:parse_sql_columns, 'registry_id, "position"')).to eq(%w[position registry_id])
    end

    it 'sorts columns alphabetically' do
      expect(checker.send(:parse_sql_columns, 'z_col, a_col, m_col')).to eq(%w[a_col m_col z_col])
    end
  end

  describe '#code_file?' do
    it 'returns true for app ruby files' do
      expect(checker.send(:code_file?, 'app/models/user.rb')).to be true
    end

    it 'returns true for lib ruby files' do
      expect(checker.send(:code_file?, 'lib/gitlab/foo.rb')).to be true
    end

    it 'returns true for ee app files' do
      expect(checker.send(:code_file?, 'ee/app/services/foo.rb')).to be true
    end

    it 'returns false for db files' do
      expect(checker.send(:code_file?, 'db/migrate/123_foo.rb')).to be false
    end

    it 'returns false for spec files' do
      expect(checker.send(:code_file?, 'spec/models/user_spec.rb')).to be false
    end

    it 'returns false for non-ruby files' do
      expect(checker.send(:code_file?, 'app/models/user.js')).to be false
    end
  end
end
