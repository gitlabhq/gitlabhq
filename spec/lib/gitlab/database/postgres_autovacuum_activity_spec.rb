# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresAutovacuumActivity, type: :model, feature_category: :database do
  include Database::DatabaseHelpers

  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe '.for_tables' do
    subject { described_class.for_tables(tables) }

    before do
      swapout_view_for_table(:postgres_autovacuum_activity, connection: ApplicationRecord.connection)

      expect(Gitlab::Database::LoadBalancing::SessionMap.current(ApplicationRecord.load_balancer))
        .to receive(:use_primary).and_yield
    end

    context 'with regular tables' do
      let(:tables) { %w[foo test] }

      before do
        # unrelated
        create(:postgres_autovacuum_activity, table: 'bar')

        tables.each do |table|
          create(:postgres_autovacuum_activity, table: table)
        end
      end

      it 'returns autovacuum activity for queried tables' do
        expect(subject.map(&:table).sort).to eq(tables)
      end

      it 'executes the query' do
        is_expected.to be_a Array
      end
    end

    context 'with partitioned tables' do
      let(:partitioned_table) { 'partitioned_events' }
      let(:regular_table) { 'regular_table' }
      let(:tables) { [partitioned_table, regular_table] }
      let(:partition_schema) { 'gitlab_partitions_dynamic' }
      let(:partition_name) { 'partitioned_events_202310' }

      before do
        allow(Gitlab::Database::PostgresPartitionedTable)
          .to receive(:find_by_name_in_current_schema)
          .with(partitioned_table)
          .and_return(instance_double(Gitlab::Database::PostgresPartitionedTable, present?: true))

        allow(Gitlab::Database::PostgresPartitionedTable)
          .to receive(:find_by_name_in_current_schema)
          .with(regular_table)
          .and_return(nil)

        allow(Gitlab::Database::PostgresPartition)
          .to receive(:with_parent_tables)
          .with([partitioned_table])
          .and_return(instance_double(ActiveRecord::Relation, pluck: [[partition_schema, partition_name]]))

        create(:postgres_autovacuum_activity, table: regular_table, schema: 'public')
        create(:postgres_autovacuum_activity, table: partition_name, schema: partition_schema)
        create(:postgres_autovacuum_activity, table: 'unrelated', schema: 'public')
      end

      it 'returns autovacuum activity for regular tables and partitions' do
        result_tables = subject.map { |activity| [activity.schema, activity.table] }

        expect(result_tables).to contain_exactly(
          ['public', regular_table],
          [partition_schema, partition_name]
        )
      end

      it 'executes the query' do
        is_expected.to be_a Array
      end
    end

    context 'with only partitioned tables' do
      let(:partitioned_table) { 'events' }
      let(:tables) { [partitioned_table] }
      let(:partition_schema) { 'gitlab_partitions_dynamic' }
      let(:partition_names) { %w[events_202310 events_202311] }

      before do
        allow(Gitlab::Database::PostgresPartitionedTable)
          .to receive(:find_by_name_in_current_schema)
          .with(partitioned_table)
          .and_return(instance_double(Gitlab::Database::PostgresPartitionedTable, present?: true))

        partition_data = partition_names.map { |name| [partition_schema, name] }
        allow(Gitlab::Database::PostgresPartition)
          .to receive(:with_parent_tables)
          .with([partitioned_table])
          .and_return(instance_double(ActiveRecord::Relation, pluck: partition_data))

        partition_names.each do |partition_name|
          create(:postgres_autovacuum_activity, table: partition_name, schema: partition_schema)
        end
      end

      it 'returns autovacuum activity for all partitions' do
        result_tables = subject.map { |activity| [activity.schema, activity.table] }

        expected_results = partition_names.map { |name| [partition_schema, name] }
        expect(result_tables).to match_array(expected_results)
      end
    end
  end

  describe '.wraparound_prevention' do
    subject { described_class.wraparound_prevention }

    it { expect(subject.where_values_hash).to match(a_hash_including('wraparound_prevention' => true)) }
  end
end
