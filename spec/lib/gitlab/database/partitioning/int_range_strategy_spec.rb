# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::IntRangeStrategy, feature_category: :database do
  include Database::PartitioningHelpers

  let(:connection) { ActiveRecord::Base.connection }
  let(:model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = '_test_partitioned_test'
    end
  end

  after do
    model.reset_column_information
  end

  describe '#current_partitions' do
    subject(:current_partitions) { described_class.new(model, partitioning_key, partition_size: 10).current_partitions }

    let(:partitioning_key) { double }
    let(:table_name) { :_test_partitioned_test }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name}
          (id serial not null, external_id integer not null, PRIMARY KEY (id, external_id))
          PARTITION BY RANGE (external_id);

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_1
        PARTITION OF #{table_name}
        FOR VALUES FROM ('1') TO ('5');

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_5
        PARTITION OF #{table_name}
        FOR VALUES FROM ('5') TO ('10');

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_10
        PARTITION OF #{table_name}
        FOR VALUES FROM ('10') TO ('100');

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_100
        PARTITION OF #{table_name}
        FOR VALUES FROM ('100') TO ('110');
      SQL
    end

    it 'returns partitions order by range bound' do
      expect(current_partitions).to eq(
        [
          Gitlab::Database::Partitioning::IntRangePartition.new(table_name, 1, 5,
            partition_name: '_test_partitioned_test_1'),
          Gitlab::Database::Partitioning::IntRangePartition.new(table_name, 5, 10,
            partition_name: '_test_partitioned_test_5'),
          Gitlab::Database::Partitioning::IntRangePartition.new(table_name, 10, 100,
            partition_name: '_test_partitioned_test_10'),
          Gitlab::Database::Partitioning::IntRangePartition.new(table_name, 100, 110,
            partition_name: '_test_partitioned_test_100')
        ])
    end
  end

  describe '#extra_partitions' do
    let(:partitioning_key) { double }
    let(:table_name) { :_test_partitioned_test }

    subject(:extra_partitions) { described_class.new(model, partitioning_key, partition_size: 10).extra_partitions }

    it 'returns an empty array' do
      expect(extra_partitions).to eq([])
    end
  end

  describe '#missing_partitions' do
    subject(:missing_partitions) { described_class.new(model, partitioning_key, partition_size: 10).missing_partitions }

    let(:model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = '_test_partitioned_test'
        self.primary_key = :id
      end
    end

    let(:partitioning_key) { :external_id }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{model.table_name}
          (id serial not null, external_id integer not null, PRIMARY KEY (id, external_id))
          PARTITION BY RANGE (external_id);
      SQL
    end

    context 'when the current partitions are not completed' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_11
          PARTITION OF #{model.table_name}
          FOR VALUES FROM ('11') TO ('21');
        SQL
      end

      context 'when partitions have data' do
        before do
          model.create!(external_id: 15)
        end

        it 'returns missing partitions', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444872' do
          expect(missing_partitions.size).to eq(7)

          expect(missing_partitions).to include(
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 1,  11),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 21, 31),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 31, 41),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 41, 51),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 51, 61),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 61, 71),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 71, 81)
          )

          expect(missing_partitions).not_to include(
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 11, 21)
          )
        end
      end

      context 'when partitions are empty' do
        before do
          model.delete_all
        end

        it 'returns missing partitions' do
          expect(missing_partitions.size).to eq(7)

          expect(missing_partitions).to include(
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 1,  11),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 21, 31),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 31, 41),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 41, 51),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 51, 61),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 61, 71),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 71, 81)
          )

          expect(missing_partitions).not_to include(
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 11, 21)
          )
        end
      end
    end

    context 'with existing partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_1
          PARTITION OF #{model.table_name}
          FOR VALUES FROM ('1') TO ('11');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_partitioned_test_11
          PARTITION OF #{model.table_name}
          FOR VALUES FROM ('11') TO ('21');
        SQL
      end

      context 'when partitions have data' do
        before do
          model.create!(external_id: 1)
          model.create!(external_id: 15)
        end

        it 'returns missing partitions' do
          expect(missing_partitions.size).to eq(6)

          expect(missing_partitions).to include(
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 21, 31),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 31, 41),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 41, 51),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 51, 61),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 61, 71),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 71, 81)
          )

          expect(missing_partitions).not_to include(
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 1, 11),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 11, 21)
          )
        end
      end

      context 'when partitions are empty' do
        before do
          model.delete_all
        end

        it 'returns missing partitions' do
          expect(missing_partitions.size).to eq(6)

          expect(missing_partitions).to include(
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 21, 31),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 31, 41),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 41, 51),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 51, 61),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 61, 71),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 71, 81)
          )

          expect(missing_partitions).not_to include(
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 1, 11),
            Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 11, 21)
          )
        end
      end
    end

    context 'without partitions' do
      it 'returns missing partitions' do
        expect(missing_partitions.size).to eq(6)

        expect(missing_partitions).to include(
          Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 1, 11),
          Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 11, 21),
          Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 21, 31),
          Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 31, 41),
          Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 41, 51),
          Gitlab::Database::Partitioning::IntRangePartition.new(model.table_name, 51, 61)
        )
      end
    end
  end

  describe 'attributes' do
    let(:partitioning_key) { :partition }
    let(:table_name) { :_test_partitioned_test }
    let(:partition_size) { 5 }
    let(:analyze_interval) { 1.week }

    subject(:strategy) do
      described_class.new(
        model, partitioning_key,
        partition_size: partition_size,
        analyze_interval: analyze_interval
      )
    end

    specify do
      expect(strategy).to have_attributes({
        model: model,
        partitioning_key: partitioning_key,
        partition_size: partition_size,
        analyze_interval: analyze_interval
      })
    end
  end

  describe 'simulates the merge_request_diff_commits partition creation' do
    let(:table_name) { '_test_partitioned_test' }
    let(:model) do
      Class.new(ApplicationRecord) do
        include PartitionedTable

        self.table_name = '_test_partitioned_test'
        self.primary_key = :merge_request_diff_id

        partitioned_by :merge_request_diff_id, strategy: :int_range, partition_size: 2
      end
    end

    before do
      connection.execute(<<~SQL)
        create table #{table_name}
          (
            merge_request_diff_id int not null,
            relative_order int not null,
            created_at timestamptz,
            primary key (merge_request_diff_id, relative_order)
          )
          PARTITION BY RANGE (merge_request_diff_id);

        create table gitlab_partitions_dynamic.#{table_name}_1
        PARTITION of #{table_name} FOR VALUES FROM (1) TO (3);

        create table gitlab_partitions_dynamic.#{table_name}_3
        PARTITION of #{table_name} FOR VALUES FROM (3) TO (5);
      SQL
    end

    it 'redirects to the new partition', :aggregate_failures,
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444881' do
      expect_range_partitions_for(table_name, {
        '1' => %w[1 3],
        '3' => %w[3 5]
      })

      expect do
        model.create!(merge_request_diff_id: 1, relative_order: 1, created_at: Time.zone.now) # Goes in partition 1
      end.to change { model.count }.by(1)

      expect do
        model.create!(merge_request_diff_id: 5, relative_order: 1, created_at: Time.zone.now)
      end.to raise_error(ActiveRecord::StatementInvalid, /no partition of relation/)

      Gitlab::Database::Partitioning::PartitionManager.new(model).sync_partitions # Generates more 6 partitions

      expect_range_partitions_for(table_name, {
        '1' => %w[1 3],
        '3' => %w[3 5],
        '5' => %w[5 7],
        '7' => %w[7 9],
        '9' => %w[9 11],
        '11' => %w[11 13],
        '13' => %w[13 15],
        '15' => %w[15 17]
      })

      expect do
        model.create!(merge_request_diff_id: 5, relative_order: 1, created_at: Time.zone.now) # Goes in partition 5
      end.to change { model.count }.by(1)
    end
  end
end
