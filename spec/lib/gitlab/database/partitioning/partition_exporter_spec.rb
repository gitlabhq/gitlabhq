# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::PartitionExporter, feature_category: :database do
  include Database::PartitioningHelpers

  let(:connection) { ApplicationRecord.connection }

  subject(:exporter) { described_class.new(connection: connection) }

  describe '#export' do
    context 'with an integer range-partitioned table' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_int_range_partitioned
            (id serial NOT NULL, project_id bigint NOT NULL, PRIMARY KEY (id, project_id))
            PARTITION BY RANGE (project_id);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_int_range_partitioned_1
          PARTITION OF _test_int_range_partitioned
          FOR VALUES FROM ('1') TO ('100');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_int_range_partitioned_100
          PARTITION OF _test_int_range_partitioned
          FOR VALUES FROM ('100') TO ('200');
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_int_range_partitioned CASCADE')
      end

      it 'includes the table with its partition definitions' do
        result = exporter.export

        table_result = result.find { |r| r[:table_name] == '_test_int_range_partitioned' }
        expect(table_result).not_to be_nil
        expect(table_result[:partition_type]).to eq('bigint')
        expect(table_result[:partitions]).to contain_exactly(
          { partition_name: '_test_int_range_partitioned_1', from: 1, to: 100 },
          { partition_name: '_test_int_range_partitioned_100', from: 100, to: 200 }
        )
      end

      it 'returns results sorted by table name' do
        result = exporter.export
        names = result.pluck(:table_name)
        expect(names).to eq(names.sort)
      end
    end

    context 'with a date range-partitioned table' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_date_range_partitioned
            (id serial NOT NULL, event_date date NOT NULL, PRIMARY KEY (id, event_date))
            PARTITION BY RANGE (event_date);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_date_range_partitioned_202601
          PARTITION OF _test_date_range_partitioned
          FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_date_range_partitioned_202602
          PARTITION OF _test_date_range_partitioned
          FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_date_range_partitioned CASCADE')
      end

      it 'includes the table with its partition definitions' do
        result = exporter.export

        table_result = result.find { |r| r[:table_name] == '_test_date_range_partitioned' }
        expect(table_result).not_to be_nil
        expect(table_result[:partition_type]).to eq('date')
        expect(table_result[:partitions]).to contain_exactly(
          { partition_name: '_test_date_range_partitioned_202601', from: '2026-01-01', to: '2026-02-01' },
          { partition_name: '_test_date_range_partitioned_202602', from: '2026-02-01', to: '2026-03-01' }
        )
      end
    end

    context 'with a timestamp range-partitioned table' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_ts_range_partitioned
            (id serial NOT NULL, created_at timestamp without time zone NOT NULL,
             PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_ts_range_partitioned_202601
          PARTITION OF _test_ts_range_partitioned
          FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_ts_range_partitioned_202602
          PARTITION OF _test_ts_range_partitioned
          FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_ts_range_partitioned CASCADE')
      end

      it 'includes the table with partition_type' do
        result = exporter.export

        table_result = result.find { |r| r[:table_name] == '_test_ts_range_partitioned' }
        expect(table_result).not_to be_nil
        expect(table_result[:partition_type]).to eq('timestamp without time zone')
        expect(table_result[:partitions]).to contain_exactly(
          { partition_name: '_test_ts_range_partitioned_202601', from: '2026-01-01', to: '2026-02-01' },
          { partition_name: '_test_ts_range_partitioned_202602', from: '2026-02-01', to: '2026-03-01' }
        )
      end
    end

    context 'with a timestamp with time zone range-partitioned table' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_tstz_range_partitioned
            (id serial NOT NULL, created_at timestamp with time zone NOT NULL,
             PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_tstz_range_partitioned_202601
          PARTITION OF _test_tstz_range_partitioned
          FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_tstz_range_partitioned_202602
          PARTITION OF _test_tstz_range_partitioned
          FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_tstz_range_partitioned CASCADE')
      end

      it 'includes the table with its partition definitions and timestamptz type' do
        result = exporter.export

        table_result = result.find { |r| r[:table_name] == '_test_tstz_range_partitioned' }
        expect(table_result).not_to be_nil
        expect(table_result[:partition_type]).to eq('timestamp with time zone')
        expect(table_result[:partitions]).to contain_exactly(
          { partition_name: '_test_tstz_range_partitioned_202601', from: '2026-01-01', to: '2026-02-01' },
          { partition_name: '_test_tstz_range_partitioned_202602', from: '2026-02-01', to: '2026-03-01' }
        )
      end
    end

    context 'with a range-partitioned table whose key_columns is empty' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_no_key_partitioned
            (id serial NOT NULL, project_id bigint NOT NULL, PRIMARY KEY (id, project_id))
            PARTITION BY RANGE (project_id);
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_no_key_partitioned CASCADE')
      end

      it 'excludes the table' do
        allow_any_instance_of(Gitlab::Database::PostgresPartitionedTable).to receive(:key_columns) # rubocop:disable RSpec/AnyInstanceOf -- simplest way to stub the PG view column
          .and_return([])

        result = exporter.export
        table_names = result.pluck(:table_name)
        expect(table_names).not_to include('_test_no_key_partitioned')
      end
    end

    context 'when an integer partition condition cannot be parsed' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_parse_error_partitioned
            (id serial NOT NULL, project_id bigint NOT NULL, PRIMARY KEY (id, project_id))
            PARTITION BY RANGE (project_id);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_parse_error_partitioned_1
          PARTITION OF _test_parse_error_partitioned
          FOR VALUES FROM ('1') TO ('100');
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_parse_error_partitioned CASCADE')
      end

      it 'skips partitions that raise ArgumentError' do
        allow(Gitlab::Database::Partitioning::IntRangePartition).to receive(:from_sql)
          .and_call_original
        allow(Gitlab::Database::Partitioning::IntRangePartition).to receive(:from_sql)
          .with('_test_parse_error_partitioned', anything, anything)
          .and_raise(ArgumentError)

        result = exporter.export
        table_result = result.find { |r| r[:table_name] == '_test_parse_error_partitioned' }
        expect(table_result).not_to be_nil
        expect(table_result[:partitions]).to be_empty
      end
    end

    context 'when a date partition condition cannot be parsed' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_date_parse_error_partitioned
            (id serial NOT NULL, event_date date NOT NULL, PRIMARY KEY (id, event_date))
            PARTITION BY RANGE (event_date);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_date_parse_error_partitioned_202601
          PARTITION OF _test_date_parse_error_partitioned
          FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_date_parse_error_partitioned CASCADE')
      end

      it 'skips partitions that raise ArgumentError' do
        allow(Gitlab::Database::Partitioning::TimePartition).to receive(:from_sql)
          .and_call_original
        allow(Gitlab::Database::Partitioning::TimePartition).to receive(:from_sql)
          .with('_test_date_parse_error_partitioned', anything, anything)
          .and_raise(ArgumentError)

        result = exporter.export
        table_result = result.find { |r| r[:table_name] == '_test_date_parse_error_partitioned' }
        expect(table_result).not_to be_nil
        expect(table_result[:partitions]).to be_empty
      end
    end

    context 'with a range-partitioned table that has no partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_empty_partitioned
            (id serial NOT NULL, project_id bigint NOT NULL, PRIMARY KEY (id, project_id))
            PARTITION BY RANGE (project_id);
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_empty_partitioned CASCADE')
      end

      it 'includes the table with an empty partitions array' do
        result = exporter.export
        table_result = result.find { |r| r[:table_name] == '_test_empty_partitioned' }
        expect(table_result).not_to be_nil
        expect(table_result[:partitions]).to be_empty
      end
    end
  end
end
