# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ClickHouse::SiphonGenerator, feature_category: :database do
  let(:table_name) { 'test_table' }

  subject(:generator) { described_class.new([table_name]) }

  before do
    allow(generator).to receive(:pg_primary_keys).and_return(['id'])
  end

  describe '#validate!' do
    context 'when PG table exists' do
      before do
        allow(generator).to receive(:pg_fields_metadata).and_return([
          { 'field_name' => 'id', 'field_type_id' => 23 }
        ])
      end

      it 'does not raise error' do
        expect { generator.validate! }.not_to raise_error
      end
    end

    context 'when PG table does not exist' do
      before do
        allow(generator).to receive(:pg_fields_metadata).and_return([])
      end

      it 'raises ArgumentError' do
        expect { generator.validate! }.to raise_error(ArgumentError, "PG test_table table does not exist")
      end
    end
  end

  describe '#generate_ch_table' do
    before do
      allow(Time).to receive_message_chain(:current, :strftime).and_return('20230101000000')
    end

    it 'generates migration file with correct path' do
      expect(generator).to receive(:template).with(
        'siphon_table.rb.template',
        'db/click_house/migrate/main/20230101000000_create_siphon_test_table.rb'
      )

      generator.generate_ch_table
    end
  end

  describe '#generate_siphon_yml' do
    let(:yml_path) { Rails.root.join('db/siphon/tables/test_table.yml') }

    before do
      allow(generator).to receive_messages(
        pg_fields_metadata: [{ 'field_name' => 'id', 'field_type_id' => 23, 'nullable' => 'NO' }],
        db_docs_yml: { 'gitlab_schema' => 'gitlab_main_org' }
      )
      allow(Gitlab::Database).to receive(:all_database_connections).and_return(
        { 'main' => instance_double(Gitlab::Database::DatabaseConnectionInfo, gitlab_schemas: [:gitlab_main_org]) }
      )
    end

    context 'when the yml file does not exist' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(yml_path).and_return(false)
      end

      it 'creates the yml file' do
        expect(generator).to receive(:create_file).with('db/siphon/tables/test_table.yml', anything)

        generator.generate_siphon_yml
      end
    end

    context 'when the yml file already exists' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(yml_path).and_return(true)
      end

      it 'skips creation and prints a warning' do
        expect(generator).not_to receive(:create_file)
        expect(generator).to receive(:say).with(/Skipping/, :yellow)

        generator.generate_siphon_yml
      end
    end
  end

  describe '#siphon_yml_content' do
    subject(:content) { YAML.safe_load(generator.send(:siphon_yml_content)) }

    before do
      allow(generator).to receive_messages(
        pg_fields_metadata: [
          { 'field_name' => 'id', 'field_type_id' => 23, 'nullable' => 'NO' },
          { 'field_name' => 'name', 'field_type_id' => 25, 'nullable' => 'NO' }
        ],
        siphon_database: 'main'
      )
    end

    it 'includes table and database' do
      expect(content['table']).to eq('test_table')
      expect(content['database']).to eq('main')
    end

    it 'does not include ignored_columns when no sensitive columns exist' do
      expect(content).not_to have_key('ignored_columns')
    end

    it 'includes correct replication target' do
      target = content['replication_targets'].first
      expect(target['name']).to eq('clickhouse_main')
      expect(target['target']).to eq('siphon_test_table')
      expect(target['dedup_by_table']).to eq('test_table')
      expect(target['dedup_by']).to eq(['id'])
    end

    it 'does not include reconcile block' do
      expect(content['replication_targets'].first).not_to have_key('reconcile')
    end

    context 'with sensitive columns' do
      before do
        allow(generator).to receive(:pg_fields_metadata).and_return([
          { 'field_name' => 'id', 'field_type_id' => 23, 'nullable' => 'NO' },
          { 'field_name' => 'reset_password_token', 'field_type_id' => 25, 'nullable' => 'NO' },
          { 'field_name' => 'title_html', 'field_type_id' => 25, 'nullable' => 'NO' }
        ])
      end

      it 'includes ignored_columns' do
        expect(content['ignored_columns']).to contain_exactly('reset_password_token', 'title_html')
      end
    end

    context 'with hierarchy_denormalization' do
      let(:generator) { described_class.new([table_name], with_traversal_path: true) }

      before do
        allow(generator).to receive_messages(
          pg_primary_keys: ['id'],
          siphon_database: 'main',
          pg_fields_metadata: [{ 'field_name' => 'id', 'field_type_id' => 23, 'nullable' => 'NO' }],
          db_docs_yml: { 'gitlab_schema' => 'gitlab_main_org', 'sharding_key' => { 'project_id' => 'projects' } }
        )
      end

      it 'includes reconcile block with traversal_path column and sharding key columns' do
        reconcile = content['replication_targets'].first['reconcile']
        expect(reconcile['column']).to eq('traversal_path')
        expect(reconcile['expression_key_columns']).to eq(['project_id'])
      end
    end
  end

  describe '#sensitive_columns' do
    before do
      allow(generator).to receive(:pg_fields_metadata).and_return([
        { 'field_name' => 'id', 'field_type_id' => 23 },
        { 'field_name' => 'reset_password_token', 'field_type_id' => 25 },
        { 'field_name' => 'title_html', 'field_type_id' => 25 },
        { 'field_name' => 'encrypted_otp_secret', 'field_type_id' => 25 },
        { 'field_name' => 'name', 'field_type_id' => 25 }
      ])
    end

    it 'returns columns matching sensitive patterns' do
      expect(generator.send(:sensitive_columns)).to contain_exactly(
        'reset_password_token', 'title_html', 'encrypted_otp_secret'
      )
    end
  end

  describe '#siphon_database' do
    before do
      allow(generator).to receive(:db_docs_yml).and_return({ 'gitlab_schema' => 'gitlab_main_org' })
      allow(Gitlab::Database).to receive(:all_database_connections).and_return(
        { 'main' => instance_double(Gitlab::Database::DatabaseConnectionInfo, gitlab_schemas: [:gitlab_main_org]) }
      )
    end

    it 'returns the database name matching the gitlab_schema' do
      expect(generator.send(:siphon_database)).to eq('main')
    end
  end

  describe '#ch_type_for' do
    context 'with known PostgreSQL type' do
      it 'maps to correct ClickHouse type' do
        field = { 'field_type_id' => 16, 'nullable' => 'NO' }
        expect(generator.send(:ch_type_for, field)).to eq('Bool')
      end

      it 'handles nullable fields' do
        field = { 'field_type_id' => 16, 'nullable' => 'YES' }
        expect(generator.send(:ch_type_for, field)).to eq('Nullable(Bool)')
      end

      it 'adds default value when present' do
        field = { 'field_type_id' => 16, 'nullable' => 'NO', 'default' => 'true' }
        expect(generator.send(:ch_type_for, field)).to eq('Bool DEFAULT true')
      end
    end

    context 'with unknown PostgreSQL type' do
      it 'returns placeholder' do
        field = { 'field_type_id' => 999999, 'nullable' => 'NO' }
        expect(generator.send(:ch_type_for, field)).to eq('INSERT_CH_TYPE')
      end
    end
  end

  describe '#ch_default_for' do
    it 'handles nextval sequences' do
      expect(generator.send(:ch_default_for, "nextval('sequence_name')")).to be_nil
    end

    it 'handles array defaults' do
      expect(generator.send(:ch_default_for, "ARRAY[]::integer[]")).to be_nil
    end

    it 'handles now() function' do
      expect(generator.send(:ch_default_for, 'now()')).to eq("now64(6, 'UTC')")
    end

    it 'handles numeric defaults' do
      expect(generator.send(:ch_default_for, '42')).to eq('42')
    end

    it 'handles boolean defaults' do
      expect(generator.send(:ch_default_for, 'true')).to eq('true')
      expect(generator.send(:ch_default_for, 'false')).to eq('false')
    end

    it 'handles type-cast strings' do
      expect(generator.send(:ch_default_for, "'some_value'::text")).to eq("'some_value'")
    end

    it 'returns placeholder for unsupported defaults' do
      expect(generator.send(:ch_default_for, 'unsupported_function()')).to eq('INSERT_COLUMN_DEFAULT')
    end
  end

  describe '#table_definition' do
    before do
      allow(generator).to receive(:pg_fields_metadata).and_return([
        { 'field_name' => 'id', 'field_type_id' => 23, 'nullable' => 'NO' },
        { 'field_name' => 'name', 'field_type_id' => 25, 'nullable' => 'YES' }
      ])
    end

    it 'generates correct table definition' do
      expected_definition = <<-SQL.chomp
CREATE TABLE IF NOT EXISTS siphon_test_table
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        name Nullable(String),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (id)
      SETTINGS index_granularity = 2048
      SQL

      expect(generator.send(:table_definition)).to eq(expected_definition)
    end

    describe 'when hierarchy_denormalization flag is enabled' do
      let(:generator) { described_class.new(['project_authorizations'], with_traversal_path: true) }

      subject(:table_definition) { generator.send(:table_definition) }

      before do
        allow(generator).to receive_messages(pg_primary_keys: %w[project_id user_id arr], pg_fields_metadata: [
          { 'field_name' => 'project_id', 'field_type_id' => 23, 'nullable' => 'NO' },
          { 'field_name' => 'user_id', 'field_type_id' => 25, 'nullable' => 'NO' },
          { 'field_name' => 'access_level', 'field_type_id' => 23, 'nullable' => 'NO' },
          { 'field_name' => 'arr', 'field_type_id' => 1016, 'nullable' => 'NO' }
        ])
      end

      it 'generates correct table definition' do
        expected_definition = <<-SQL.chomp
CREATE TABLE IF NOT EXISTS siphon_project_authorizations
      (
        project_id Int64 CODEC(DoubleDelta, ZSTD),
        user_id String CODEC(ZSTD(3)),
        access_level Int64,
        arr Array(Int64),
        traversal_path String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY project_id, user_id, arr
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, project_id, user_id, arr)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
        SQL

        expect(table_definition).to eq(expected_definition)
      end

      context 'when the table definition is missing' do
        let(:generator) { described_class.new(['unknown_table'], with_traversal_path: true) }

        it 'raises errors' do
          expect { table_definition }.to raise_error(/Table definition is missing/)
        end
      end

      context 'when the table has no sharding keys' do
        let(:generator) { described_class.new(['tags'], with_traversal_path: true) }

        it 'raises errors' do
          expect { table_definition }.to raise_error(/No sharding_key/)
        end
      end
    end

    context 'when use_null_engine is true' do
      let(:generator) { described_class.new([table_name], use_null_engine: true) }

      before do
        allow(generator).to receive(:pg_fields_metadata).and_return([
          { 'field_name' => 'id', 'field_type_id' => 23, 'nullable' => 'NO' }
        ])
      end

      it 'uses Null engine and no primary key' do
        definition = generator.send(:table_definition)
        expect(definition).to include('ENGINE = Null')
        expect(definition).not_to include('PRIMARY KEY')
      end

      context 'with hierarchy_denormalization' do
        let(:generator) { described_class.new([table_name], use_null_engine: true, with_traversal_path: true) }

        before do
          allow(File).to receive(:exist?).and_return(true)
          allow(YAML).to receive(:safe_load_file).and_return({ "sharding_key" => { "project_id" => "projects" } })
        end

        it 'does not include projection' do
          expect(generator.send(:table_projection)).to be_nil
          expect(generator.send(:table_definition)).not_to include('PROJECTION')
        end
      end
    end
  end

  describe '#pg_fields_metadata' do
    # rubocop:disable RSpec/VerifiedDoubles -- ApplicationRecord.connection.class returns a class which does not implement #execute method
    let(:connection) { double('connection', current_database: 'gitlab_db_name') }
    # rubocop:enable RSpec/VerifiedDoubles

    before do
      allow(ApplicationRecord).to receive(:connection).and_return(connection)
    end

    it 'executes the correct SQL query' do
      expected_sql = <<~SQL
        SELECT
            column_name AS field_name,
            column_default AS default,
            is_nullable AS nullable,
            pg_type.oid AS field_type_id
        FROM
            information_schema.columns
        JOIN
            pg_catalog.pg_type ON pg_catalog.pg_type.typname = information_schema.columns.udt_name
        WHERE
            table_name = 'test_table' AND
            table_catalog = 'gitlab_db_name';
      SQL

      expect(connection).to receive(:execute)
        .with(expected_sql)

      generator.send(:pg_fields_metadata)
    end
  end
end
