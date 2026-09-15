# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Checks::SchemaResolution, feature_category: :database do
  describe '#execute' do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
    let(:search_path) { '"$user", public' }

    let(:schema_rows) do
      [{ 'name' => 'public', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }]
    end

    let(:schema_table_rows) do
      [{ 'schema_name' => 'public', 'table_name' => 'projects' }]
    end

    subject(:result) { described_class.new(connection).execute }

    before do
      allow(connection).to receive(:select_value).with('SELECT current_user').and_return('gitlab')
      allow(connection).to receive(:select_value).with('SHOW search_path').and_return(search_path)
      allow(connection).to receive(:select_all).with(described_class::SCHEMAS_SQL).and_return(schema_rows)
      allow(connection).to receive(:select_all)
        .with(described_class::SCHEMA_TABLES_SQL).and_return(schema_table_rows)
    end

    it 'reports the connected role, the live search path and the schemas', :aggregate_failures do
      expect(result[:current_user]).to eq('gitlab')
      expect(result[:search_path]).to eq('"$user", public')
      expect(result[:schemas]).to eq(
        [{ name: 'public', current: true, owner: 'gitlab', has_tables: true }]
      )
    end

    it 'normalizes the current and has_tables flags to booleans', :aggregate_failures do
      schema_rows.first['is_current'] = 'f'
      schema_rows.first['has_tables'] = 't'

      expect(result[:schemas].first[:current]).to be(false)
      expect(result[:schemas].first[:has_tables]).to be(true)
    end

    context 'with search_path findings' do
      subject(:findings) { result[:findings] }

      context 'when the search path is the default of "$user", public' do
        it 'returns no findings' do
          expect(findings).to be_empty
        end
      end

      context 'when a partition schema is present in the search path' do
        let(:search_path) { '"$user", public, gitlab_partitions_dynamic' }

        it 'returns only a partition-schema warning', :aggregate_failures do
          codes = findings.map { |f| f[:code] }

          expect(codes).to contain_exactly('search_path_contains_partition_schema')
          expect(findings.first[:severity]).to eq('warning')
        end
      end

      context 'when a populated partition schema is in the search path' do
        let(:search_path) { '"$user", public, gitlab_partitions_dynamic' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab_partitions_dynamic', 'is_current' => false, 'owner' => 'gitlab',
              'has_tables' => true }
          ]
        end

        it 'is flagged only as a partition schema, not as split objects', :aggregate_failures do
          codes = findings.map { |f| f[:code] }

          expect(codes).to include('search_path_contains_partition_schema')
          expect(codes).not_to include('search_path_objects_split_across_schemas')
        end
      end

      context 'when all objects live in a single non-public schema and public is empty' do
        let(:search_path) { 'gitlab, public' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => false },
            { 'name' => 'gitlab', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        let(:schema_table_rows) do
          [{ 'schema_name' => 'gitlab', 'table_name' => 'projects' }]
        end

        it 'returns no findings' do
          expect(findings).to be_empty
        end
      end

      context 'when GitLab objects are split across more than one populated schema' do
        let(:search_path) { 'gitlab, public' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        let(:schema_table_rows) do
          [
            { 'schema_name' => 'public', 'table_name' => 'projects' },
            { 'schema_name' => 'gitlab', 'table_name' => 'namespaces' }
          ]
        end

        it 'reports a split-objects warning and a split-GitLab-objects error', :aggregate_failures do
          generic = findings.find { |f| f[:code] == 'search_path_objects_split_across_schemas' }
          gitlab = findings.find { |f| f[:code] == 'search_path_gitlab_objects_split_across_schemas' }

          expect(generic).to be_present
          expect(generic[:severity]).to eq('warning')
          expect(generic[:message]).to include('public').and(include('gitlab'))

          expect(gitlab).to be_present
          expect(gitlab[:severity]).to eq('error')
          expect(gitlab[:message]).to include('public').and(include('gitlab'))
        end
      end

      context 'when a second populated schema contains only non-GitLab objects' do
        let(:search_path) { 'gitlab, public' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        let(:schema_table_rows) do
          [
            { 'schema_name' => 'public', 'table_name' => 'projects' },
            { 'schema_name' => 'gitlab', 'table_name' => 'some_extension_table' }
          ]
        end

        it 'warns about split objects but does not raise a GitLab-objects error', :aggregate_failures do
          codes = findings.map { |f| f[:code] }

          expect(codes).to include('search_path_objects_split_across_schemas')
          expect(codes).not_to include('search_path_gitlab_objects_split_across_schemas')
        end
      end

      context 'when a second populated schema contains only internal bookkeeping tables' do
        let(:search_path) { 'gitlab, public' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        # 'schema_migrations' resolves to :gitlab_internal - Rails bookkeeping,
        # not one of GitLab's own objects - so it must not raise the error.
        let(:schema_table_rows) do
          [
            { 'schema_name' => 'public', 'table_name' => 'projects' },
            { 'schema_name' => 'gitlab', 'table_name' => 'schema_migrations' }
          ]
        end

        it 'warns about split objects but does not raise a GitLab-objects error', :aggregate_failures do
          codes = findings.map { |f| f[:code] }

          expect(codes).to include('search_path_objects_split_across_schemas')
          expect(codes).not_to include('search_path_gitlab_objects_split_across_schemas')
        end
      end

      context 'when a second populated schema holds a GitLab view rather than a table' do
        let(:search_path) { 'gitlab, public' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        let(:schema_table_rows) do
          [
            { 'schema_name' => 'public', 'table_name' => 'projects' },
            { 'schema_name' => 'gitlab', 'table_name' => 'personal_snippets_view' }
          ]
        end

        it 'raises the GitLab-objects error' do
          expect(findings.map { |f| f[:code] }).to include('search_path_gitlab_objects_split_across_schemas')
        end
      end

      context 'when the "$user" token resolves to a populated user schema alongside public' do
        let(:search_path) { '"$user", public' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        let(:schema_table_rows) do
          [
            { 'schema_name' => 'public', 'table_name' => 'projects' },
            { 'schema_name' => 'gitlab', 'table_name' => 'namespaces' }
          ]
        end

        it 'resolves "$user" and raises the GitLab-objects error' do
          expect(findings.map { |f| f[:code] }).to include('search_path_gitlab_objects_split_across_schemas')
        end
      end

      context 'when a schema outside the search path contains GitLab objects' do
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'foobar', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        let(:schema_table_rows) do
          [
            { 'schema_name' => 'public', 'table_name' => 'projects' },
            { 'schema_name' => 'foobar', 'table_name' => 'users' }
          ]
        end

        it 'reports only an outside-search-path warning', :aggregate_failures do
          expect(findings.map { |f| f[:code] }).to contain_exactly('gitlab_objects_outside_search_path')

          finding = findings.first
          expect(finding[:severity]).to eq('warning')
          expect(finding[:message]).to include('foobar')
        end
      end

      context 'when a schema outside the search path contains only non-GitLab objects' do
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'foobar', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        let(:schema_table_rows) do
          [
            { 'schema_name' => 'public', 'table_name' => 'projects' },
            { 'schema_name' => 'foobar', 'table_name' => 'not_a_gitlab_table' }
          ]
        end

        it 'returns no findings' do
          expect(findings).to be_empty
        end
      end

      context 'when partition schemas outside the search path hold GitLab partitions' do
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab_partitions_dynamic', 'is_current' => false, 'owner' => 'gitlab',
              'has_tables' => true }
          ]
        end

        let(:schema_table_rows) do
          [
            { 'schema_name' => 'public', 'table_name' => 'projects' },
            { 'schema_name' => 'gitlab_partitions_dynamic', 'table_name' => 'ci_builds' }
          ]
        end

        it 'returns no findings' do
          expect(findings).to be_empty
        end
      end
    end

    describe 'the verdict it hands to the renderers' do
      context 'when there are no findings' do
        it 'reports no severity and no counts', :aggregate_failures do
          expect(result[:severity]).to be_nil
          expect(result[:counts]).to eq({})
        end
      end

      context 'when findings of several severities are present' do
        let(:search_path) { '"$user", public, legacy, gitlab_partitions_static' }

        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'legacy', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab_partitions_static', 'is_current' => false, 'owner' => 'gitlab',
              'has_tables' => true }
          ]
        end

        let(:schema_table_rows) do
          [
            { 'schema_name' => 'public', 'table_name' => 'projects' },
            { 'schema_name' => 'legacy', 'table_name' => 'issues' }
          ]
        end

        it 'reports the worst severity and a count per severity', :aggregate_failures do
          expect(result[:severity]).to eq('error')
          expect(result[:counts]).to eq({ 'error' => 1, 'warning' => 2 })
        end

        it 'returns findings with errors first' do
          expect(result[:findings].pluck(:severity)).to eq(%w[error warning warning])
        end
      end
    end
  end

  # Uses the real connection, so it sits outside the stubbed describe above.
  describe 'SCHEMA_TABLES_SQL' do
    context 'when resolving sequences in SCHEMA_TABLES_SQL' do
      let(:connection) { ApplicationRecord.connection }

      # An `around` hook runs before RSpec opens its transactional fixture, so this DDL is
      # committed, not rolled back. The schema is dropped before it is created as well as
      # after, so an interrupted run cannot leave it behind and break the next one.
      # Table names use the `_test_` prefix, the convention for throwaway relations.
      around do |example|
        drop_test_schema
        connection.execute('CREATE SCHEMA db_info_seq_test')
        # bigserial -> sequence with an 'a' (auto) dependency on the column
        connection.execute('CREATE TABLE db_info_seq_test._test_widgets (id bigserial PRIMARY KEY)')
        # identity -> sequence with an 'i' (internal) dependency on the column
        connection.execute('CREATE TABLE db_info_seq_test._test_gadgets (id bigint GENERATED BY DEFAULT AS IDENTITY)')
        # a standalone sequence owned by no table
        connection.execute('CREATE SEQUENCE db_info_seq_test._test_orphan_seq')
        example.run
      ensure
        drop_test_schema
      end

      subject(:names) do
        connection.select_all(described_class::SCHEMA_TABLES_SQL).to_a
          .select { |row| row['schema_name'] == 'db_info_seq_test' }
          .map { |row| row['table_name'] }
      end

      # Each owned sequence collapses onto its table's name, so the three relations that
      # carry a GitLab-recognizable name are the two tables and the standalone sequence.
      it 'reports owned sequences under their owning table and leaves standalone ones as-is' do
        expect(names).to match_array(%w[_test_widgets _test_gadgets _test_orphan_seq])
      end

      def drop_test_schema
        connection.execute('DROP SCHEMA IF EXISTS db_info_seq_test CASCADE')
      end
    end
  end
end
