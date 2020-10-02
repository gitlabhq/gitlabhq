# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::MonthlyStrategy do
  describe '#current_partitions' do
    subject { described_class.new(model, partitioning_key).current_partitions }

    let(:model) { double('model', table_name: table_name) }
    let(:partitioning_key) { double }
    let(:table_name) { :partitioned_test }

    before do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE #{table_name}
          (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
          PARTITION BY RANGE (created_at);

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.partitioned_test_000000
        PARTITION OF #{table_name}
        FOR VALUES FROM (MINVALUE) TO ('2020-05-01');

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.partitioned_test_202005
        PARTITION OF #{table_name}
        FOR VALUES FROM ('2020-05-01') TO ('2020-06-01');
      SQL
    end

    it 'detects both partitions' do
      expect(subject).to eq([
        Gitlab::Database::Partitioning::TimePartition.new(table_name, nil, '2020-05-01', partition_name: 'partitioned_test_000000'),
        Gitlab::Database::Partitioning::TimePartition.new(table_name, '2020-05-01', '2020-06-01', partition_name: 'partitioned_test_202005')
    ])
    end
  end

  describe '#missing_partitions' do
    subject { described_class.new(model, partitioning_key).missing_partitions }

    let(:model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'partitioned_test'
        self.primary_key = :id
      end
    end

    let(:partitioning_key) { :created_at }

    around do |example|
      travel_to(Date.parse('2020-08-22')) { example.run }
    end

    context 'with existing partitions' do
      before do
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE #{model.table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.partitioned_test_000000
          PARTITION OF #{model.table_name}
          FOR VALUES FROM (MINVALUE) TO ('2020-05-01');

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.partitioned_test_202006
          PARTITION OF #{model.table_name}
          FOR VALUES FROM ('2020-06-01') TO ('2020-07-01');
        SQL

        # Insert some data, it doesn't make a difference
        model.create!(created_at: Date.parse('2020-04-20'))
        model.create!(created_at: Date.parse('2020-06-15'))
      end

      it 'detects the gap and the missing partition in May 2020' do
        expect(subject).to include(Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-05-01', '2020-06-01'))
      end

      it 'detects the missing partitions at the end of the range and expects a partition for July 2020' do
        expect(subject).to include(Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-07-01', '2020-08-01'))
      end

      it 'detects the missing partitions at the end of the range and expects a partition for August 2020' do
        expect(subject).to include(Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-08-01', '2020-09-01'))
      end

      it 'creates partitions 6 months out from now (Sep 2020 through Feb 2021)' do
        expect(subject).to include(
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-09-01', '2020-10-01'),
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-10-01', '2020-11-01'),
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-11-01', '2020-12-01'),
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-12-01', '2021-01-01'),
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2021-01-01', '2021-02-01'),
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2021-02-01', '2021-03-01')
        )
      end

      it 'detects all missing partitions' do
        expect(subject.size).to eq(9)
      end
    end

    context 'without existing partitions' do
      before do
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE #{model.table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);
        SQL
      end

      it 'detects the missing catch-all partition at the beginning' do
        expect(subject).to include(Gitlab::Database::Partitioning::TimePartition.new(model.table_name, nil, '2020-08-01'))
      end

      it 'detects the missing partition for today and expects a partition for August 2020' do
        expect(subject).to include(Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-08-01', '2020-09-01'))
      end

      it 'creates partitions 6 months out from now (Sep 2020 through Feb 2021' do
        expect(subject).to include(
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-09-01', '2020-10-01'),
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-10-01', '2020-11-01'),
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-11-01', '2020-12-01'),
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2020-12-01', '2021-01-01'),
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2021-01-01', '2021-02-01'),
          Gitlab::Database::Partitioning::TimePartition.new(model.table_name, '2021-02-01', '2021-03-01')
        )
      end

      it 'detects all missing partitions' do
        expect(subject.size).to eq(8)
      end
    end

    context 'with a regular partition but no catchall (MINVALUE, to) partition' do
      before do
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE #{model.table_name}
            (id serial not null, created_at timestamptz not null, PRIMARY KEY (id, created_at))
            PARTITION BY RANGE (created_at);

            CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.partitioned_test_202006
            PARTITION OF #{model.table_name}
            FOR VALUES FROM ('2020-06-01') TO ('2020-07-01');
        SQL
      end

      it 'detects a missing catch-all partition to add before the existing partition' do
        expect(subject).to include(Gitlab::Database::Partitioning::TimePartition.new(model.table_name, nil, '2020-06-01'))
      end
    end
  end
end
