# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ClickHouse::SiphonGenerator, feature_category: :code_suggestions do
  let(:table_name) { 'test_table' }

  subject(:generator) { described_class.new([table_name]) }

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
        id Int64,
        name Nullable(String),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
      SQL

      expect(generator.send(:table_definition)).to eq(expected_definition)
    end
  end

  describe '#pg_fields_metadata' do
    # rubocop:disable RSpec/VerifiedDoubles -- ApplicationRecord.connection.class returns a class which does not implement #execute method
    let(:connection) { double('connection') }
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
            table_name = 'test_table';
      SQL

      expect(connection).to receive(:execute)
        .with(expected_sql)

      generator.send(:pg_fields_metadata)
    end
  end
end
