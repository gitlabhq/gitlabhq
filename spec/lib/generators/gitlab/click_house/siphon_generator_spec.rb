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
      expect(generator.send(:ch_default_for, 'now()')).to eq('now()')
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
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
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
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
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
          expect { table_definition }.to raise_error(/Unknown PostgreSQL table/)
        end
      end

      context 'when the table has no sharding keys' do
        let(:generator) { described_class.new(['tags'], with_traversal_path: true) }

        it 'raises errors' do
          expect { table_definition }.to raise_error(/No sharding_key/)
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
