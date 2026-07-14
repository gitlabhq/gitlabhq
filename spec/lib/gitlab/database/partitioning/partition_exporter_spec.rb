# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::PartitionExporter, feature_category: :database do
  include Database::PartitioningHelpers
  include Database::MultipleDatabasesHelpers

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

    context 'with a list-partitioned table' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_list_partitioned
          (id serial NOT NULL, partition_id bigint NOT NULL, PRIMARY KEY (id, partition_id))
          PARTITION BY LIST (partition_id);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_list_partitioned_1
          PARTITION OF _test_list_partitioned
          FOR VALUES IN ('1');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_list_partitioned_2
          PARTITION OF _test_list_partitioned
          FOR VALUES IN ('2');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_list_partitioned_3_4
          PARTITION OF _test_list_partitioned
          FOR VALUES IN ('3', '4');
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_list_partitioned CASCADE')
      end

      it 'includes single-value list partitions', :aggregate_failures do
        result = exporter.export

        table_result = result.find { |r| r[:table_name] == '_test_list_partitioned' }
        expect(table_result).not_to be_nil
        expect(table_result[:partition_type]).to eq('bigint')
        expect(table_result[:partition_strategy]).to eq('list')
        expect(table_result[:partitions]).to contain_exactly(
          { partition_name: '_test_list_partitioned_1', values: [1] },
          { partition_name: '_test_list_partitioned_2', values: [2] }
        )
      end

      it 'excludes multi-value list partitions' do
        result = exporter.export

        table_result = result.find { |r| r[:table_name] == '_test_list_partitioned' }
        partition_names = table_result[:partitions].map { |p| p[:partition_name] }
        expect(partition_names).not_to include('_test_list_partitioned_3_4')
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

  # Happy-path UTC session guard (UNTAGGED).
  #
  # Under the default (UTC) session the guard must be a no-op and #export must
  # behave exactly as before. These run in the normal `rspec unit` jobs against
  # CI's primary `postgres`. Note that CI's primary may report a UTC-equivalent
  # value such as `Etc/UTC` or `GMT` rather than the literal `UTC`, which is why
  # the guard normalizes those values (see EnsureUtcSession::UTC_TIMEZONES)
  # instead of comparing strictly against `'UTC'`.
  describe '#export (UTC session guard)' do
    it 'does not raise under the default (UTC) session' do
      expect { exporter.export }.not_to raise_error
    end
  end

  # Guard proof (TAGGED :partition_tz).
  #
  # Under a genuinely non-UTC session the guard must raise before doing any
  # work. No SQL stubbing; the subject is constructed with a real side
  # connection (the `postgres-tz` instance) whose SESSION TimeZone is forced
  # non-UTC in the `before` hook.
  #
  # This test asserts only the OUTCOME (a raise under a non-UTC state). It puts
  # the connection into a non-UTC state via a session `SET timezone`, which is a
  # reliable lever regardless of whether the guard inspects the session zone or
  # the database's configured default.
  #
  # The assertion matches on a message substring rather than an exact error
  # class, so it remains valid if the guard's error class is ever changed.
  describe '#export (non-UTC session guard)', :partition_tz do
    before do
      skip_unless_non_utc_database_available

      tz_connection.execute("SET timezone TO 'America/Los_Angeles'")
    end

    after do
      tz_connection.execute("SET timezone TO 'UTC'")
    end

    subject(:exporter) { described_class.new(connection: tz_connection) }

    it 'raises because the session TimeZone is not UTC' do
      expect { exporter.export }.to raise_error(/TimeZone.*UTC/i)
    end
  end

  # No-silent-corruption proof (TAGGED :partition_tz, exporter only).
  #
  # Asserts the good end-state this guard protects: an export of a timestamptz
  # partition under a non-UTC session must NEVER silently return a corrupted
  # boundary. This is a black-box assertion through the public API only (no
  # internals, no `from_sql`). It accepts TWO good outcomes and fails on the ONE
  # bad outcome:
  #   - PASS if #export raises (a guard prevented corruption), OR
  #   - PASS if #export returns the correct boundary ('2026-01-01'), OR
  #   - FAIL if #export returns the wrong boundary ('2025-12-31') -- silent
  #     corruption.
  # Because it tests the outcome (not the mechanism) it stays valid regardless of
  # how the bug is fixed (a raise-guard, or a future zone-normalizing fix).
  describe 'no silent timestamptz boundary corruption under non-UTC', :partition_tz do
    before do
      skip_unless_non_utc_database_available

      # CRITICAL: the corruption requires an ASYMMETRY between the session zone
      # at CREATE time and the session zone at READ (#export) time. It is NOT
      # enough to merely run #export under a non-UTC session.
      #
      # A `timestamp with time zone` partition boundary is stored as an absolute
      # instant, fixed by the session TimeZone in effect WHEN THE PARTITION IS
      # CREATED. `pg_get_expr(relpartbound, ...)` (the `condition` column of the
      # `postgres_partitions` view that #export reads) then RENDERS that instant
      # in the session TimeZone in effect WHEN IT IS READ. The exported date is
      # corrupted only when those two zones differ.
      #
      # The real cross-cell scenario this guards against is exactly that
      # asymmetry: the source cell writes the boundary under a UTC session
      # (instant = 2026-01-01 00:00:00+00) and the target cell reads/renders it
      # under a non-UTC session (-> 2025-12-31 16:00:00-08 -> date 2025-12-31).
      #
      # Setting the session to America/Los_Angeles for BOTH the CREATE and the
      # #export would make the round-trip self-consistent: the literal
      # '2026-01-01' is interpreted as LA midnight (instant 2026-01-01
      # 08:00:00+00) and then rendered back under the SAME LA session as
      # 2026-01-01 00:00:00-08 -> date '2026-01-01'. With no asymmetry there is
      # no observable corruption and this test would pass vacuously.
      #
      # So instead: CREATE the partition under the default (UTC) session so the
      # stored instant is 2026-01-01 00:00:00+00, THEN switch the session to
      # America/Los_Angeles so #export renders that fixed instant under a
      # DIFFERENT zone and produces the corrupted '2025-12-31'.
      #
      # NOTE: AR 7.2's PG adapter forces `SET timezone TO 'UTC'` on every
      # connection it opens (ActiveRecord.default_timezone == :utc), so the side
      # connection's session starts in UTC -- which is precisely the CREATE-time
      # zone we want here. We rely on that default for the CREATE, then override
      # it for the read.

      tz_connection.execute(<<~SQL)
        CREATE TABLE _test_tstz_corruption
          (id serial NOT NULL, created_at timestamp with time zone NOT NULL,
           PRIMARY KEY (id, created_at))
          PARTITION BY RANGE (created_at);

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_tstz_corruption_202601
        PARTITION OF _test_tstz_corruption
        FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
      SQL

      # Now (and only now, AFTER the partition's instant is fixed under UTC)
      # switch the read session to the non-UTC zone so #export renders the
      # boundary under a different zone than it was created in.
      tz_connection.execute("SET timezone TO 'America/Los_Angeles'")
    end

    after do
      # Reset the session TimeZone back to UTC FIRST so the `SET timezone` above
      # does not leak onto the pooled side connection and affect other
      # :partition_tz examples that share it. Order does not matter for the DROP
      # (DDL is zone-insensitive), but resetting first keeps the session clean
      # even if the DROP raises.
      tz_connection.execute("SET timezone TO 'UTC'")
      tz_connection.execute('DROP TABLE IF EXISTS _test_tstz_corruption CASCADE')
    end

    subject(:exporter) { described_class.new(connection: tz_connection) }

    it 'never silently produces a corrupted boundary (raise OR correct value both pass)' do
      # Mechanism-agnostic, but NOT vacuous: accepts exactly two "did not
      # corrupt" outcomes and fails on everything else.
      #   - PASS if #export raises THE GUARD error (/TimeZone.*UTC/i) -- the
      #     guard prevents corruption by raising.
      #   - PASS if #export returns the CORRECT boundary ('2026-01-01').
      #   - FAIL if #export returns the WRONG boundary ('2025-12-31') -- the
      #     silent corruption this test exists to catch.
      #   - FAIL if #export raises any OTHER error -- deliberately NOT swallowed,
      #     so a setup/schema regression surfaces as a failure instead of a
      #     false green.
      result =
        begin
          exporter.export
        rescue StandardError => e
          raise unless e.message.match?(/TimeZone.*UTC/i)

          :guard_raised_so_no_corruption
        end

      next if result == :guard_raised_so_no_corruption

      table_result = result.find { |r| r[:table_name] == '_test_tstz_corruption' }
      exported_from = table_result[:partitions].first[:from]
      expect(exported_from).to eq('2026-01-01') # must NOT be the corrupted '2025-12-31'
    end
  end
end
