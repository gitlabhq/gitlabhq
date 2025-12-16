# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PartitionedTable, feature_category: :database do
  subject { my_class.partitioned_by(key, strategy: :monthly) }

  let(:key) { :foo }

  let(:my_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = :p_ci_builds

      include PartitionedTable
    end
  end

  describe '.partitioned_by' do
    context 'with keyword arguments passed to the strategy' do
      subject { my_class.partitioned_by(key, strategy: :monthly, retain_for: 3.months) }

      it 'passes the keyword arguments to the strategy' do
        expect(Gitlab::Database::Partitioning::Time::MonthlyStrategy).to receive(:new).with(my_class, key, retain_for: 3.months).and_call_original

        subject
      end
    end

    it 'assigns the MonthlyStrategy as the partitioning strategy' do
      subject

      expect(my_class.partitioning_strategy).to be_a(Gitlab::Database::Partitioning::Time::MonthlyStrategy)
    end

    it 'passes the partitioning key to the strategy instance' do
      subject

      expect(my_class.partitioning_strategy.partitioning_key).to eq(key)
    end
  end

  describe 'self._returning_columns_for_insert' do
    it 'identifies the columns that are returned on insert' do
      columns = my_class._returning_columns_for_insert(my_class.connection)

      expect(columns).to eq(Array.wrap(my_class.primary_key))
    end

    it 'allows creating a partitionable record' do
      expect { create(:ci_build) }.not_to raise_error
    end
  end

  describe '.with_each_partition' do
    let(:partition1) { instance_double(Gitlab::Database::PostgresPartition, name: 'partition_1') }
    let(:partition2) { instance_double(Gitlab::Database::PostgresPartition, name: 'partition_2') }

    before do
      allow(Gitlab::Database::PostgresPartitionedTable).to receive(:each_partition)
        .with(my_class.table_name)
        .and_yield(partition1)
        .and_yield(partition2)
    end

    it 'yields a relation for each partition' do
      yielded_relations = []

      my_class.with_each_partition do |relation|
        yielded_relations << relation
      end

      expect(yielded_relations.size).to eq(2)
      expect(yielded_relations.first).to be_a(ActiveRecord::Relation)
      expect(yielded_relations.last).to be_a(ActiveRecord::Relation)
    end

    it 'constructs relations with correct partition schema and table name' do
      sql_queries = []

      my_class.with_each_partition do |relation|
        sql_queries << relation.to_sql
      end

      expect(sql_queries.size).to eq(2)
      expect(sql_queries[0]).to include(Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA.to_s)
      expect(sql_queries[0]).to include('partition_1')
      expect(sql_queries[1]).to include(Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA.to_s)
      expect(sql_queries[1]).to include('partition_2')
    end
  end
end
