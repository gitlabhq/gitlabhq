# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::Time::DailyStrategy, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }
  let(:daily_strategy) do
    described_class.new(model, partitioning_key, retain_for: retention_period, retain_non_empty_partitions: retain_data)
  end

  let(:retention_period) { nil }
  let(:retain_data) { false }
  let(:partitioning_key) { :created_at }
  let(:table_name) { model.table_name }
  let(:model) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_partitioned_test'
      self.primary_key = :id
    end
  end

  describe '#current_partitions' do
    subject(:current_partitions) { daily_strategy.current_partitions }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name}
          (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
          PARTITION BY RANGE (created_at);

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_00000000
        PARTITION OF #{table_name}
        FOR VALUES FROM (MINVALUE) TO ('2020-05-01');

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_20200501
        PARTITION OF #{table_name}
        FOR VALUES FROM ('2020-05-01') TO ('2020-05-02');
      SQL
    end

    it 'detects both partitions' do
      expect(current_partitions).to eq(
        [
          time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_00000000"),
          time_partition(table_name, '2020-05-01', '2020-05-02', "#{model.table_name}_20200501")
        ])
    end
  end

  describe '#missing_partitions', time_travel_to: '2020-05-04' do
    subject(:missing_partitions) { daily_strategy.missing_partitions }

    context 'with existing partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_00000000
          PARTITION OF #{table_name}
          FOR VALUES FROM (MINVALUE) TO ('2020-05-01');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_20200502
          PARTITION OF #{table_name}
          FOR VALUES FROM ('2020-05-02') TO ('2020-05-03');
        SQL

        # Insert some data, it doesn't make a difference
        model.create!(created_at: Date.parse('2020-04-15'))
        model.create!(created_at: Date.parse('2020-05-02'))
      end

      context 'when pruning partitions before 2020-05-02' do
        let(:retention_period) { 1.day }

        it 'does not include the missing partition from 2020-05-02 because it would be dropped' do
          expect(missing_partitions).not_to include(
            time_partition(table_name, '2020-05-01', '2020-05-02', "#{model.table_name}_20200501")
          )
        end

        it 'detects the missing partition for 1 day ago (2020-05-03)' do
          expect(missing_partitions).to include(
            time_partition(table_name, '2020-05-03', '2020-05-04', "#{model.table_name}_20200503")
          )
        end
      end

      it 'detects the gap and the missing partition for 2020-05-01' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-05-01', '2020-05-02', "#{model.table_name}_20200501")
        )
      end

      it 'detects the missing partitions at the end of the range and expects a partition for 2020-05-03' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-05-03', '2020-05-04', "#{model.table_name}_20200503")
        )
      end

      it 'detects the missing partitions at the end of the range and expects a partition for 2020-05-05' do
        expect(missing_partitions).to include(
          time_partition(model.table_name, '2020-05-05', '2020-05-06', "#{model.table_name}_20200505")
        )
      end

      it 'creates partitions 7 days out from now (2020-05-04 to 2020-05-10)' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-05-04', '2020-05-05', "#{model.table_name}_20200504"),
          time_partition(table_name, '2020-05-05', '2020-05-06', "#{model.table_name}_20200505"),
          time_partition(table_name, '2020-05-06', '2020-05-07', "#{model.table_name}_20200506"),
          time_partition(table_name, '2020-05-07', '2020-05-08', "#{model.table_name}_20200507"),
          time_partition(table_name, '2020-05-08', '2020-05-09', "#{model.table_name}_20200508"),
          time_partition(table_name, '2020-05-09', '2020-05-10', "#{model.table_name}_20200509"),
          time_partition(table_name, '2020-05-10', '2020-05-11', "#{model.table_name}_20200510")
        )
      end

      it 'detects all missing partitions' do
        expect(missing_partitions.size).to eq(30)
      end
    end

    context 'without existing partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);
        SQL
      end

      context 'when pruning partitions before 2020-05-02' do
        let(:retention_period) { 1.day }

        it 'detects exactly the set of partitions from 2020-05-03 to 2020-05-31' do
          days = (Date.parse('2020-05-03')..Date.parse('2020-06-01')).map(&:to_s)
          expected = days[..-2].zip(days.drop(1)).map do |(from, to)|
            partition_name = "#{model.table_name}_#{Date.parse(from).strftime('%Y%m%d')}"
            time_partition(model.table_name, from, to, partition_name)
          end

          expect(missing_partitions).to match_array(expected)
        end
      end

      it 'detects the missing catch-all partition at the beginning' do
        expect(missing_partitions).to include(
          time_partition(table_name, nil, '2020-05-04', "#{model.table_name}_00000000")
        )
      end

      it 'detects the missing partition for today and expects a partition for 2020-05-04' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-05-04', '2020-05-05', "#{model.table_name}_20200504")
        )
      end

      it 'creates partitions 7 days out from now (2020-05-04 through 2020-05-10)' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-05-04', '2020-05-05', "#{model.table_name}_20200504"),
          time_partition(table_name, '2020-05-05', '2020-05-06', "#{model.table_name}_20200505"),
          time_partition(table_name, '2020-05-06', '2020-05-07', "#{model.table_name}_20200506"),
          time_partition(table_name, '2020-05-07', '2020-05-08', "#{model.table_name}_20200507"),
          time_partition(table_name, '2020-05-08', '2020-05-09', "#{model.table_name}_20200508"),
          time_partition(table_name, '2020-05-09', '2020-05-10', "#{model.table_name}_20200509"),
          time_partition(table_name, '2020-05-10', '2020-05-11', "#{model.table_name}_20200510")
        )
      end

      it 'detects all missing partitions' do
        expect(missing_partitions.size).to eq(29)
      end
    end

    context 'with a regular partition but no catchall (MINVALUE, to) partition' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

            CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_20200501
            PARTITION OF #{table_name}
            FOR VALUES FROM ('2020-05-01') TO ('2020-05-02');
        SQL
      end

      it 'detects a missing catch-all partition to add before the existing partition' do
        expect(missing_partitions).to include(
          time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_00000000")
        )
      end
    end
  end

  describe '#extra_partitions', time_travel_to: '2020-05-04' do
    subject(:extra_partitions) { daily_strategy.extra_partitions }

    describe 'with existing partitions' do
      before do
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE #{table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_00000000
          PARTITION OF #{table_name}
          FOR VALUES FROM (MINVALUE) TO ('2020-05-01');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_20200501
          PARTITION OF #{table_name}
          FOR VALUES FROM ('2020-05-01') TO ('2020-05-02');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_20200502
          PARTITION OF #{table_name}
          FOR VALUES FROM ('2020-05-02') TO ('2020-05-03')
        SQL
      end

      context 'without a time retention policy' do
        it 'has no extra partitions to prune' do
          expect(extra_partitions).to be_empty
        end
      end

      context 'with a time retention policy that excludes no partitions' do
        let(:retention_period) { 4.days }

        it 'has no extra partitions to prune' do
          expect(extra_partitions).to be_empty
        end
      end

      context 'with a time retention policy of 3 days' do
        let(:retention_period) { 3.days }

        it 'prunes the unbounded partition ending 2020-05-01' do
          min_value = time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_00000000")

          expect(extra_partitions).to contain_exactly(min_value)
        end
      end

      context 'with a time retention policy of 2 days' do
        let(:retention_period) { 2.days }

        it 'prunes the unbounded partition and the partition for min value to 2020-05-01' do
          expect(extra_partitions).to contain_exactly(
            time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_00000000"),
            time_partition(table_name, '2020-05-01', '2020-05-02', "#{model.table_name}_20200501")
          )
        end

        context 'when the retain_non_empty_partitions is true' do
          let(:retain_data) { true }

          it 'prunes empty partitions' do
            expect(extra_partitions).to contain_exactly(
              time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_00000000"),
              time_partition(table_name, '2020-05-01', '2020-05-02', "#{model.table_name}_20200501")
            )
          end

          it 'does not prune non-empty partitions' do
            # inserting one record into _test_partitioned_test_20200501
            connection.execute("INSERT INTO #{table_name} (created_at) VALUES (('2020-05-01'))")

            expect(extra_partitions).to contain_exactly(
              time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_00000000")
            )
          end
        end
      end

      context 'with a time retention policy of 1 day' do
        let(:retention_period) { 1.day }

        it 'prunes the unbounded partition and the partitions for 2020-05-01 and 2020-05-02' do
          expect(extra_partitions).to contain_exactly(
            time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_00000000"),
            time_partition(table_name, '2020-05-01', '2020-05-02', "#{model.table_name}_20200501"),
            time_partition(table_name, '2020-05-02', '2020-05-03', "#{model.table_name}_20200502")
          )
        end

        context 'when the retain_non_empty_partitions is true' do
          let(:retain_data) { true }

          it 'prunes empty partitions' do
            expect(extra_partitions).to contain_exactly(
              time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_00000000"),
              time_partition(table_name, '2020-05-01', '2020-05-02', "#{model.table_name}_20200501"),
              time_partition(table_name, '2020-05-02', '2020-05-03', "#{model.table_name}_20200502")
            )
          end

          it 'does not prune non-empty partitions' do
            # inserting one record into _test_partitioned_test_20200501
            connection.execute("INSERT INTO #{table_name} (created_at) VALUES (('2020-05-01'))")

            expect(extra_partitions).to contain_exactly(
              time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_00000000"),
              time_partition(table_name, '2020-05-02', '2020-05-03', "#{model.table_name}_20200502")
            )
          end
        end
      end
    end
  end

  describe '#partition_name' do
    let(:from) { Date.parse('2020-05-01 00:00:00') }
    let(:to) { Date.parse('2020-05-02 00:00:00') }

    subject(:partition_name) { daily_strategy.partition_name(from) }

    it 'uses table_name as prefix' do
      expect(partition_name).to start_with(table_name)
    end

    it 'uses Year-Month-Day (from) as suffix' do
      expect(partition_name).to end_with("_20200501")
    end

    context 'without from date' do
      let(:from) { nil }

      it 'uses 00000000 as suffix for first partition' do
        expect(partition_name).to end_with("_00000000")
      end
    end
  end

  private

  def time_partition(table_name, lower_bound, upper_bound, partition_name)
    Gitlab::Database::Partitioning::TimePartition.new(
      table_name,
      lower_bound,
      upper_bound,
      partition_name: partition_name
    )
  end
end
