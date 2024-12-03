# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::Time::MonthlyStrategy, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }
  let(:monthly_strategy) do
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
    subject(:current_partitions) { monthly_strategy.current_partitions }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name}
          (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
          PARTITION BY RANGE (created_at);

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_000000
        PARTITION OF #{table_name}
        FOR VALUES FROM (MINVALUE) TO ('2020-05-01');

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_202005
        PARTITION OF #{table_name}
        FOR VALUES FROM ('2020-05-01') TO ('2020-06-01');
      SQL
    end

    it 'detects both partitions' do
      expect(current_partitions).to eq(
        [
          time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_000000"),
          time_partition(table_name, '2020-05-01', '2020-06-01', "#{model.table_name}_202005")
        ]
      )
    end
  end

  describe '#missing_partitions', time_travel_to: '2020-08-22' do
    subject(:missing_partitions) { monthly_strategy.missing_partitions }

    context 'with existing partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{model.table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_000000
          PARTITION OF #{model.table_name}
          FOR VALUES FROM (MINVALUE) TO ('2020-05-01');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_202006
          PARTITION OF #{model.table_name}
          FOR VALUES FROM ('2020-06-01') TO ('2020-07-01');
        SQL

        # Insert some data, it doesn't make a difference
        model.create!(created_at: Date.parse('2020-04-20'))
        model.create!(created_at: Date.parse('2020-06-15'))
      end

      context 'when pruning partitions before June 2020' do
        let(:retention_period) { 1.month }

        it 'does not include the missing partition from May 2020 because it would be dropped' do
          expect(missing_partitions).not_to include(
            time_partition(table_name, '2020-05-01', '2020-06-01', "#{model.table_name}_202005")
          )
        end

        it 'detects the missing partition for 1 month ago (July 2020)' do
          expect(missing_partitions).to include(
            time_partition(table_name, '2020-07-01', '2020-08-01', "#{model.table_name}_202007")
          )
        end
      end

      it 'detects the gap and the missing partition in May 2020' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-05-01', '2020-06-01', "#{model.table_name}_202005")
        )
      end

      it 'detects the missing partitions at the end of the range and expects a partition for July 2020' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-07-01', '2020-08-01', "#{model.table_name}_202007")
        )
      end

      it 'detects the missing partitions at the end of the range and expects a partition for August 2020' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-08-01', '2020-09-01', "#{model.table_name}_202008")
        )
      end

      it 'creates partitions 6 months out from now (Sep 2020 through Feb 2021)' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-09-01', '2020-10-01', "#{model.table_name}_202009"),
          time_partition(table_name, '2020-10-01', '2020-11-01', "#{model.table_name}_202010"),
          time_partition(table_name, '2020-11-01', '2020-12-01', "#{model.table_name}_202011"),
          time_partition(table_name, '2020-12-01', '2021-01-01', "#{model.table_name}_202012"),
          time_partition(table_name, '2021-01-01', '2021-02-01', "#{model.table_name}_202101"),
          time_partition(table_name, '2021-02-01', '2021-03-01', "#{model.table_name}_202102")
        )
      end

      it 'detects all missing partitions' do
        expect(missing_partitions.size).to eq(9)
      end
    end

    context 'without existing partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{model.table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);
        SQL
      end

      context 'when pruning partitions before June 2020' do
        let(:retention_period) { 1.month }

        it 'detects exactly the set of partitions from June 2020 to March 2021' do
          months = %w[2020-07-01 2020-08-01 2020-09-01 2020-10-01 2020-11-01 2020-12-01 2021-01-01 2021-02-01
            2021-03-01]
          expected = months[..-2].zip(months.drop(1)).map do |(from, to)|
            partition_name = "#{model.table_name}_#{Date.parse(from).strftime('%Y%m')}"
            time_partition(table_name, from, to, partition_name)
          end

          expect(missing_partitions).to match_array(expected)
        end
      end

      it 'detects the missing catch-all partition at the beginning' do
        expect(missing_partitions).to include(
          time_partition(table_name, nil, '2020-08-01', "#{model.table_name}_000000")
        )
      end

      it 'detects the missing partition for today and expects a partition for August 2020' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-08-01', '2020-09-01', "#{model.table_name}_202008")
        )
      end

      it 'creates partitions 6 months out from now (Sep 2020 through Feb 2021' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-09-01', '2020-10-01', "#{model.table_name}_202009"),
          time_partition(table_name, '2020-10-01', '2020-11-01', "#{model.table_name}_202010"),
          time_partition(table_name, '2020-11-01', '2020-12-01', "#{model.table_name}_202011"),
          time_partition(table_name, '2020-12-01', '2021-01-01', "#{model.table_name}_202012"),
          time_partition(table_name, '2021-01-01', '2021-02-01', "#{model.table_name}_202101"),
          time_partition(table_name, '2021-02-01', '2021-03-01', "#{model.table_name}_202102")
        )
      end

      it 'detects all missing partitions' do
        expect(missing_partitions.size).to eq(8)
      end
    end

    context 'with a regular partition but no catchall (MINVALUE, to) partition' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{model.table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

            CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_202006
            PARTITION OF #{model.table_name}
            FOR VALUES FROM ('2020-06-01') TO ('2020-07-01');
        SQL
      end

      it 'detects a missing catch-all partition to add before the existing partition' do
        expect(missing_partitions).to include(
          time_partition(table_name, nil, '2020-06-01', "#{model.table_name}_000000")
        )
      end
    end
  end

  describe '#extra_partitions', time_travel_to: '2020-08-22' do
    subject(:extra_partitions) { monthly_strategy.extra_partitions }

    describe 'with existing partitions' do
      before do
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE #{table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_000000
          PARTITION OF #{table_name}
          FOR VALUES FROM (MINVALUE) TO ('2020-05-01');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_202005
          PARTITION OF #{table_name}
          FOR VALUES FROM ('2020-05-01') TO ('2020-06-01');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_202006
          PARTITION OF #{table_name}
          FOR VALUES FROM ('2020-06-01') TO ('2020-07-01')
        SQL
      end

      context 'without a time retention policy' do
        it 'has no extra partitions to prune' do
          expect(extra_partitions).to be_empty
        end
      end

      context 'with a time retention policy that excludes no partitions' do
        let(:retention_period) { 4.months }

        it 'has no extra partitions to prune' do
          expect(extra_partitions).to be_empty
        end
      end

      context 'with a time retention policy of 3 months' do
        let(:retention_period) { 3.months }

        it 'prunes the unbounded partition ending 2020-05-01' do
          min_value_to_may = time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_000000")

          expect(extra_partitions).to contain_exactly(min_value_to_may)
        end
      end

      context 'with a time retention policy of 2 months' do
        let(:retention_period) { 2.months }

        it 'prunes the unbounded partition and the partition for May-June' do
          expect(extra_partitions).to contain_exactly(
            time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_000000"),
            time_partition(table_name, '2020-05-01', '2020-06-01', "#{model.table_name}_202005")
          )
        end

        context 'when the retain_non_empty_partitions is true' do
          let(:retain_data) { true }

          it 'prunes empty partitions' do
            expect(extra_partitions).to contain_exactly(
              time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_000000"),
              time_partition(table_name, '2020-05-01', '2020-06-01', "#{model.table_name}_202005")
            )
          end

          it 'does not prune non-empty partitions' do
            # inserting one record into _test_partitioned_test_202005
            connection.execute("INSERT INTO #{table_name} (created_at) VALUES (('2020-05-15'))")

            expect(extra_partitions).to contain_exactly(
              time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_000000")
            )
          end
        end
      end

      context 'with a time retention policy of 1 month' do
        let(:retention_period) { 1.month }

        it 'prunes the unbounded partition and the partitions for May-June and June-July' do
          expect(extra_partitions).to contain_exactly(
            time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_000000"),
            time_partition(table_name, '2020-05-01', '2020-06-01', "#{model.table_name}_202005"),
            time_partition(table_name, '2020-06-01', '2020-07-01', "#{model.table_name}_202006")
          )
        end

        it 'contains partitions starting at least one month in the past' do
          prune_to = extra_partitions.map(&:to).max
          expect(1.month.ago).to be_after(prune_to)

          strategy = described_class.new(model, partitioning_key, retain_for: retention_period)
          desired_partitions = strategy.current_partitions - strategy.extra_partitions + strategy.missing_partitions
          # Double check this is equivalent to the private method
          expect(desired_partitions).to match_array(strategy.send(:desired_partitions))
        end

        context 'when the retain_non_empty_partitions is true' do
          let(:retain_data) { true }

          it 'prunes empty partitions' do
            expect(extra_partitions).to contain_exactly(
              time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_000000"),
              time_partition(table_name, '2020-05-01', '2020-06-01', "#{model.table_name}_202005"),
              time_partition(table_name, '2020-06-01', '2020-07-01', "#{model.table_name}_202006")
            )
          end

          it 'does not prune non-empty partitions' do
            # inserting one record into _test_partitioned_test_202005
            connection.execute("INSERT INTO #{table_name} (created_at) VALUES (('2020-05-15'))")

            expect(extra_partitions).to contain_exactly(
              time_partition(table_name, nil, '2020-05-01', "#{model.table_name}_000000"),
              time_partition(table_name, '2020-06-01', '2020-07-01', "#{model.table_name}_202006")
            )
          end
        end
      end
    end
  end

  describe 'attributes' do
    let(:partitioning_key) { :partition }
    let(:retain_non_empty_partitions) { true }
    let(:retain_for) { 12.months }
    let(:analyze_interval) { 1.week }
    let(:model) { class_double(ApplicationRecord, table_name: table_name, connection: connection) }
    let(:table_name) { :_test_partitioned_test }

    subject(:strategy) do
      described_class.new(
        model, partitioning_key,
        retain_for: retain_for,
        retain_non_empty_partitions: retain_non_empty_partitions,
        analyze_interval: analyze_interval
      )
    end

    specify do
      expect(strategy).to have_attributes({
        model: model,
        partitioning_key: partitioning_key,
        retain_for: retain_for,
        retain_non_empty_partitions: retain_non_empty_partitions,
        analyze_interval: analyze_interval
      })
    end
  end

  describe '#partition_name' do
    let(:from) { Date.parse('2020-04-01 00:00:00') }
    let(:to) { Date.parse('2020-05-01 00:00:00') }

    subject(:partition_name) { monthly_strategy.partition_name(from) }

    it 'uses table_name as prefix' do
      expect(partition_name).to start_with(table_name)
    end

    it 'uses Year-Month (from) as suffix' do
      expect(partition_name).to end_with("_202004")
    end

    context 'without from date' do
      let(:from) { nil }

      it 'uses 000000 as suffix for first partition' do
        expect(partition_name).to end_with("_000000")
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
