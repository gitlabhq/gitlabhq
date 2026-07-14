# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/database/partitioning/shared_model_connection_enforcement'
require 'support/shared_examples/database/partitioning/shared_model_no_connection_enforcement'

RSpec.describe Gitlab::Database::Partitioning::Time::WeeklyStrategy, feature_category: :database do
  shared_context 'with shared model setup' do
    let(:shared_model) do
      Class.new(Gitlab::Database::SharedModel) do
        include PartitionedTable
        self.table_name = '_test_partitioned_shared_model'
        partitioned_by :created_at, strategy: :weekly, retain_for: :ever
      end
    end

    before do
      # Create the parent table
      connection.execute(<<~SQL)
        CREATE TABLE #{shared_model.table_name}
          (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
          PARTITION BY RANGE (created_at)
      SQL

      # Use PartitionManager to create initial partitions
      Gitlab::Database::Partitioning::PartitionManager.new(shared_model, connection: connection).sync_partitions
    end

    after do
      connection.execute("DROP TABLE IF EXISTS #{shared_model.table_name} CASCADE")
    end
  end

  let(:connection) { ApplicationRecord.connection }
  let(:weekly_strategy) do
    described_class.new(model, partitioning_key, retain_for: retention_period, retain_non_empty_partitions: retain_data)
  end

  let(:retention_period) { :ever }
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
    subject(:current_partitions) { weekly_strategy.current_partitions }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name}
          (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
          PARTITION BY RANGE (created_at);

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_00000000
        PARTITION OF #{table_name}
        FOR VALUES FROM (MINVALUE) TO ('2020-05-04');

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_20200504
        PARTITION OF #{table_name}
        FOR VALUES FROM ('2020-05-04') TO ('2020-05-11');
      SQL
    end

    it 'detects both partitions' do
      expect(current_partitions).to match_array(
        [
          time_partition(table_name, nil, '2020-05-04', "#{model.table_name}_00000000"),
          time_partition(table_name, '2020-05-04', '2020-05-11', "#{model.table_name}_20200504")
        ])
    end

    context 'with shared model' do
      include_context 'with shared model setup'

      subject { shared_model.partitioning_strategy.current_partitions }

      include_examples 'shared model connection enforcement'
    end
  end

  describe '#missing_partitions', time_travel_to: '2020-05-13' do
    subject(:missing_partitions) { weekly_strategy.missing_partitions }

    context 'with existing partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_00000000
          PARTITION OF #{table_name}
          FOR VALUES FROM (MINVALUE) TO ('2020-04-27');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_20200504
          PARTITION OF #{table_name}
          FOR VALUES FROM ('2020-05-04') TO ('2020-05-11');
        SQL

        # Insert some data, it doesn't make a difference
        model.create!(created_at: Date.parse('2020-04-15'))
        model.create!(created_at: Date.parse('2020-05-06'))
      end

      context 'when pruning partitions before the week of 2020-05-04' do
        let(:retention_period) { 1.week }

        it 'does not include the pre-retention partition because it would be dropped' do
          expect(missing_partitions).not_to include(
            time_partition(table_name, '2020-04-27', '2020-05-04', "#{model.table_name}_20200427")
          )
        end

        it 'detects the missing partition for the current week (2020-05-11)' do
          expect(missing_partitions).to include(
            time_partition(table_name, '2020-05-11', '2020-05-18', "#{model.table_name}_20200511")
          )
        end
      end

      it 'detects the gap and the missing partition for the week of 2020-04-27' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-04-27', '2020-05-04', "#{model.table_name}_20200427")
        )
      end

      it 'detects the missing partition for the current week (2020-05-11)' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-05-11', '2020-05-18', "#{model.table_name}_20200511")
        )
      end

      it 'creates partitions 4 weeks out from now (2020-05-11 through 2020-06-15)' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-05-11', '2020-05-18', "#{model.table_name}_20200511"),
          time_partition(table_name, '2020-05-18', '2020-05-25', "#{model.table_name}_20200518"),
          time_partition(table_name, '2020-05-25', '2020-06-01', "#{model.table_name}_20200525"),
          time_partition(table_name, '2020-06-01', '2020-06-08', "#{model.table_name}_20200601"),
          time_partition(table_name, '2020-06-08', '2020-06-15', "#{model.table_name}_20200608")
        )
      end

      it 'detects all missing partitions' do
        expect(missing_partitions.size).to eq(6)
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

      context 'when pruning partitions before the week of 2020-05-04' do
        let(:retention_period) { 1.week }

        it 'detects exactly the set of weekly partitions from 2020-05-04 to 2020-06-15' do
          weeks = %w[2020-05-04 2020-05-11 2020-05-18 2020-05-25 2020-06-01 2020-06-08 2020-06-15]
          expected = weeks[..-2].zip(weeks.drop(1)).map do |(from, to)|
            partition_name = "#{model.table_name}_#{Date.parse(from).strftime('%Y%m%d')}"
            time_partition(table_name, from, to, partition_name)
          end

          expect(missing_partitions).to match_array(expected)
        end
      end

      it 'detects the missing catch-all partition at the beginning' do
        expect(missing_partitions).to include(
          time_partition(table_name, nil, '2020-05-11', "#{model.table_name}_00000000")
        )
      end

      it 'detects the missing partition for the current week (2020-05-11)' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-05-11', '2020-05-18', "#{model.table_name}_20200511")
        )
      end

      it 'creates partitions 4 weeks out from now (2020-05-11 through 2020-06-15)' do
        expect(missing_partitions).to include(
          time_partition(table_name, '2020-05-11', '2020-05-18', "#{model.table_name}_20200511"),
          time_partition(table_name, '2020-05-18', '2020-05-25', "#{model.table_name}_20200518"),
          time_partition(table_name, '2020-05-25', '2020-06-01', "#{model.table_name}_20200525"),
          time_partition(table_name, '2020-06-01', '2020-06-08', "#{model.table_name}_20200601"),
          time_partition(table_name, '2020-06-08', '2020-06-15', "#{model.table_name}_20200608")
        )
      end

      it 'detects all missing partitions' do
        expect(missing_partitions.size).to eq(6)
      end
    end

    context 'with a regular partition but no catchall (MINVALUE, to) partition' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

            CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_20200504
            PARTITION OF #{table_name}
            FOR VALUES FROM ('2020-05-04') TO ('2020-05-11');
        SQL
      end

      it 'detects a missing catch-all partition to add before the existing partition' do
        expect(missing_partitions).to include(
          time_partition(table_name, nil, '2020-05-04', "#{model.table_name}_00000000")
        )
      end
    end

    context 'with shared model' do
      include_context 'with shared model setup'

      subject { shared_model.partitioning_strategy.missing_partitions }

      include_examples 'shared model connection enforcement'
    end
  end

  describe '#extra_partitions', time_travel_to: '2020-05-13' do
    subject(:extra_partitions) { weekly_strategy.extra_partitions }

    describe 'with existing partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_00000000
          PARTITION OF #{table_name}
          FOR VALUES FROM (MINVALUE) TO ('2020-04-27');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_20200427
          PARTITION OF #{table_name}
          FOR VALUES FROM ('2020-04-27') TO ('2020-05-04');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_20200504
          PARTITION OF #{table_name}
          FOR VALUES FROM ('2020-05-04') TO ('2020-05-11')
        SQL
      end

      context 'with :ever retention' do
        it 'has no extra partitions to prune' do
          expect(extra_partitions).to be_empty
        end
      end

      context 'with a time retention policy that excludes no partitions' do
        let(:retention_period) { 4.weeks }

        it 'has no extra partitions to prune' do
          expect(extra_partitions).to be_empty
        end
      end

      context 'with a time retention policy of 2 weeks' do
        let(:retention_period) { 2.weeks }

        it 'prunes the unbounded partition ending 2020-04-27' do
          min_value = time_partition(table_name, nil, '2020-04-27', "#{model.table_name}_00000000")

          expect(extra_partitions).to contain_exactly(min_value)
        end
      end

      context 'with a time retention policy of 1 week' do
        let(:retention_period) { 1.week }

        it 'prunes the unbounded partition and the partition for the week of 2020-04-27' do
          expect(extra_partitions).to contain_exactly(
            time_partition(table_name, nil, '2020-04-27', "#{model.table_name}_00000000"),
            time_partition(table_name, '2020-04-27', '2020-05-04', "#{model.table_name}_20200427")
          )
        end

        it 'contains partitions starting at least one week in the past' do
          prune_to = extra_partitions.map(&:to).max
          expect(1.week.ago).to be_after(prune_to)

          strategy = described_class.new(model, partitioning_key, retain_for: retention_period)
          desired_partitions = strategy.current_partitions - strategy.extra_partitions + strategy.missing_partitions
          # Double check this is equivalent to #desired_partitions
          expect(desired_partitions).to match_array(strategy.desired_partitions)
        end

        context 'when the retain_non_empty_partitions is true' do
          let(:retain_data) { true }

          it 'prunes empty partitions' do
            expect(extra_partitions).to contain_exactly(
              time_partition(table_name, nil, '2020-04-27', "#{model.table_name}_00000000"),
              time_partition(table_name, '2020-04-27', '2020-05-04', "#{model.table_name}_20200427")
            )
          end

          it 'does not prune non-empty partitions' do
            # inserting one record into _test_partitioned_test_20200427
            connection.execute("INSERT INTO #{table_name} (created_at) VALUES (('2020-04-28'))")

            expect(extra_partitions).to contain_exactly(
              time_partition(table_name, nil, '2020-04-27', "#{model.table_name}_00000000")
            )
          end
        end
      end
    end

    context 'with shared model' do
      include_context 'with shared model setup'

      subject { shared_model.partitioning_strategy.extra_partitions }

      include_examples 'shared model connection enforcement'
    end
  end

  describe 'attributes' do
    let(:partitioning_key) { :partition }
    let(:retain_non_empty_partitions) { true }
    let(:retain_for) { 12.weeks }
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

    context 'with shared model' do
      include_context 'with shared model setup'

      subject { shared_model.partitioning_strategy.current_partitions }

      include_examples 'shared model connection enforcement'
    end
  end

  describe '#oldest_active_date', time_travel_to: '2020-05-13' do
    subject(:oldest_active_date) { weekly_strategy.oldest_active_date }

    let(:retention_period) { 2.weeks }

    it 'anchors the retention cutoff to the Monday of that week' do
      # 2 weeks before Wednesday 2020-05-13 is Wednesday 2020-04-29,
      # which the strategy snaps back to its Monday, 2020-04-27.
      expect(oldest_active_date).to eq(Date.parse('2020-04-27'))
    end
  end

  describe '#partition_name' do
    let(:from) { Date.parse('2020-05-04 00:00:00') }
    let(:to) { Date.parse('2020-05-11 00:00:00') }

    subject(:partition_name) { weekly_strategy.partition_name(from) }

    it 'uses table_name as prefix' do
      expect(partition_name).to start_with(table_name)
    end

    it 'uses Year-Month-Day of the week start (from) as suffix' do
      expect(partition_name).to end_with("_20200504")
    end

    context 'without from date' do
      let(:from) { nil }

      it 'uses 00000000 as suffix for first partition' do
        expect(partition_name).to end_with("_00000000")
      end
    end

    context 'with shared model' do
      include_context 'with shared model setup'

      subject { shared_model.partitioning_strategy.partition_name(from) }

      include_examples 'shared model without connection enforcement'
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
