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
      let(:partitioned_table) { '_test_table_partitioned_events' }
      let(:regular_table) { '_test_table_regular_events' }
      let(:tables) { [partitioned_table, regular_table] }
      let(:partition_schema) { 'gitlab_partitions_dynamic' }
      let(:partition_name) { '_test_table_partitioned_events_1' }

      before do
        create_table(partitioned_table, [["#{partition_schema}.#{partition_name}", 1]])
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
      let(:partitioned_table) { '_test_table_partitioned_events' }
      let(:tables) { [partitioned_table] }
      let(:partition_schema) { 'gitlab_partitions_dynamic' }
      let(:partition_names) { %w[events_202310 events_202311] }

      before do
        create_table(
          partitioned_table,
          partition_names.map.with_index { |name, index| ["#{partition_schema}.#{name}", index] }
        )
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

    context 'with partitioned tables, table partitions and regular tables' do
      let(:partitioned_table) { '_test_table_partitioned_events' }
      let(:other_partitioned_table) { '_test_table_partitioned_event_details' }
      let(:regular_table) { '_test_table_regular_events' }
      let(:partition_schema) { 'gitlab_partitions_dynamic' }
      let(:partition_names) { %w[_test_table_events_202310 _test_table_events_202311] }
      let(:other_partition_names) { %w[_test_table_event_details_202410 _test_table_event_details_202411] }
      let(:specific_partition_name) { "#{partition_schema}.#{other_partition_names.first}" }
      let(:tables) { [partitioned_table, regular_table, specific_partition_name] }

      before do
        create_table(
          partitioned_table,
          partition_names.map.with_index { |name, index| ["#{partition_schema}.#{name}", index] }
        )

        create_table(
          other_partitioned_table,
          other_partition_names.map.with_index { |name, index| ["#{partition_schema}.#{name}", index] }
        )

        (partition_names + other_partition_names).each do |partition_name|
          create(:postgres_autovacuum_activity, table: partition_name, schema: partition_schema)
        end

        create(:postgres_autovacuum_activity, table: regular_table, schema: 'public')
      end

      it 'returns autovacuum activity' do
        result_tables = subject.map { |activity| [activity.schema, activity.table] }
        expected_results = partition_names.map { |name| [partition_schema, name] }
        expected_results << specific_partition_name.split('.')
        expected_results << ['public', regular_table]

        expect(result_tables).to match_array(expected_results)
      end
    end

    def create_table(table_name, partitions)
      options = {
        primary_key: [:id, :partition_id],
        options: 'PARTITION BY LIST (partition_id)',
        if_not_exists: true
      }

      ApplicationRecord.connection.create_table(table_name, **options) do |t|
        t.bigserial :id, null: false
        t.bigint :partition_id, null: false
      end

      partitions.each do |partition_name, values|
        ApplicationRecord.connection.execute(<<~SQL)
          CREATE TABLE #{partition_name} PARTITION OF #{table_name} FOR VALUES IN (#{values});
        SQL
      end
    end
  end

  describe '.wraparound_prevention' do
    subject { described_class.wraparound_prevention }

    it { expect(subject.where_values_hash).to match(a_hash_including('wraparound_prevention' => true)) }
  end
end
