# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Migration, :click_house, feature_category: :database do
  describe '#execute_when_idle', :aggregate_failures do
    let(:connection) { instance_double(ClickHouse::Connection, replicated_engine?: false, version: '25.3') }
    let(:migration) { described_class.new(connection) }
    let(:sql) { 'ALTER TABLE some_table ADD COLUMN IF NOT EXISTS new_id UInt64 DEFAULT 0' }

    before do
      allow(migration).to receive(:sleep)
    end

    where(:message) do
      [
        'Code: 517. DB::Exception: Previous 2 mutation queries are not finished yet. (CANNOT_ASSIGN_ALTER)',
        "Code: 36. DB::Exception: Cannot drop projection by_id because it's affected by mutation " \
          "with ID 'mutation_1.txt' which is not finished yet. (BAD_ARGUMENTS)"
      ]
    end

    with_them do
      let(:running_mutation_error) { ClickHouse::Client::DatabaseError.new(message) }

      it 'retries until the mutation finishes' do
        attempts = 0
        allow(connection).to receive(:execute) do
          attempts += 1
          raise running_mutation_error if attempts < 3
        end

        migration.execute_when_idle(sql, interval: 1.second)

        expect(connection).to have_received(:execute).with(sql).exactly(3).times
        expect(migration).to have_received(:sleep).with(1.0).twice
      end

      it 'raises TableBusyError when the mutation is still running after the timeout' do
        allow(connection).to receive(:execute).and_raise(running_mutation_error)

        expect { migration.execute_when_idle(sql, timeout: 0.seconds) }
          .to raise_error(ClickHouse::MigrationSupport::Errors::TableBusyError, /still running after 0 seconds/)
        expect(migration).not_to have_received(:sleep)
      end
    end

    it 're-raises other database errors without retrying' do
      error = ClickHouse::Client::DatabaseError.new('Code: 62. DB::Exception: Syntax error. (SYNTAX_ERROR)')
      allow(connection).to receive(:execute).and_raise(error)

      expect { migration.execute_when_idle(sql) }.to raise_error(error)
      expect(connection).to have_received(:execute).once
    end
  end

  describe '#create_dictionary' do
    let(:connection) { ClickHouse::Connection.new(:main) }
    let(:migration) { described_class.new(connection) }
    let(:sql) do
      <<~SQL
        CREATE DICTIONARY test_dict
        (
            `id` UInt64,
            `traversal_ids` Array(UInt64)
        )
        PRIMARY KEY id
        SOURCE(
          CLICKHOUSE(
            QUERY 'SELECT id, traversal_ids FROM siphon_namespaces'
          )
        )
        LIFETIME(MIN 60 MAX 300)
        LAYOUT(CACHE(SIZE_IN_CELLS 3000000))
      SQL
    end

    subject(:create_dictionary) { migration.create_dictionary(sql, source_tables: ['siphon_namespaces']) }

    it 'correctly creates a dictionary' do
      connection.execute("INSERT INTO siphon_namespaces (id, organization_id, traversal_ids) VALUES (3, 10, '[1,2,3]')")

      create_dictionary

      result = connection
        .select("SELECT arrayStringConcat(dictGet(test_dict, 'traversal_ids', 3), ',') AS traversal_ids")
        .first['traversal_ids']

      expect(result).to eq('1,2,3')
    end

    context 'when different source is given' do
      let(:sql) do
        <<~SQL
          CREATE DICTIONARY test_dict
          (
              `id` UInt64,
              `traversal_ids` Array(UInt64)
          )
          PRIMARY KEY id
          SOURCE(
            UNKNOWN_SOURCE(
              QUERY 'SELECT id, traversal_ids FROM siphon_namespaces'
            )
          )
          LIFETIME(MIN 60 MAX 300)
          LAYOUT(CACHE(SIZE_IN_CELLS 3000000))
        SQL
      end

      it 'raises error' do
        expect { create_dictionary }.to raise_error(/Unsupported dictionary source/)
      end
    end
  end

  describe '#safe_table_swap' do
    let(:connection) { ClickHouse::Connection.new(:main) }
    let(:migration) { described_class.new(connection) }

    before do
      connection.execute('CREATE TABLE IF NOT EXISTS table_a (id UInt64) ENGINE = MergeTree() ORDER BY id')
      connection.execute('CREATE TABLE IF NOT EXISTS table_b (id UInt64) ENGINE = MergeTree() ORDER BY id')
    end

    after do
      connection.execute('DROP TABLE IF EXISTS table_a')
      connection.execute('DROP TABLE IF EXISTS table_b')
      connection.execute('DROP TABLE IF EXISTS table_a_temp')
    end

    context 'when running in CI' do
      before do
        stub_env('CI', 'true')
      end

      it 'uses RENAME TABLE for swapping' do
        expected_sql = 'RENAME TABLE table_a TO table_a_temp, table_b TO table_a, ' \
          'table_a_temp TO table_b'
        expect(migration).to receive(:execute).with(expected_sql)

        migration.safe_table_swap('table_a', 'table_b', '_temp')
      end

      it 'validates tables exist before swapping' do
        expect { migration.safe_table_swap('nonexistent', 'table_b', '_temp') }
          .to raise_error(ClickHouse::MigrationSupport::Errors::Base, /Table nonexistent does not exist/)

        expect { migration.safe_table_swap('table_a', 'nonexistent', '_temp') }
          .to raise_error(ClickHouse::MigrationSupport::Errors::Base, /Table nonexistent does not exist/)
      end

      it 'validates temporary table does not exist' do
        connection.execute('CREATE TABLE table_a_temp (id UInt64) ENGINE = MergeTree() ORDER BY id')

        expect { migration.safe_table_swap('table_a', 'table_b', '_temp') }
          .to raise_error(ClickHouse::MigrationSupport::Errors::Base, /Temporary table table_a_temp already exists/)

        connection.execute('DROP TABLE table_a_temp')
      end
    end

    context 'when running outside CI' do
      before do
        stub_env('CI', nil)
      end

      it 'uses EXCHANGE TABLES for swapping' do
        expect(migration).to receive(:execute).with('EXCHANGE TABLES table_a AND table_b')

        migration.safe_table_swap('table_a', 'table_b', '_temp')
      end

      it 'does not perform pre-flight validation' do
        expect(connection).not_to receive(:table_exists?)
        expect(migration).to receive(:execute).with('EXCHANGE TABLES table_a AND table_b')

        migration.safe_table_swap('table_a', 'table_b', '_temp')
      end
    end
  end
end
