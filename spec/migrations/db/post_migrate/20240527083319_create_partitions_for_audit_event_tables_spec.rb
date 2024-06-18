# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreatePartitionsForAuditEventTables, feature_category: :audit_events do
  include Database::PartitioningHelpers

  let(:migration) { described_class.new(20240527083319) }
  let(:today) { '2024-04-23'.to_date }
  let(:beginning_of_next_month) { today.beginning_of_month.next_month }
  let(:connection) { ActiveRecord::Base.connection }

  shared_examples 'calls partition methods with correct args' do |min_date|
    it 'calls drop partitions and create daterange partitions with correct args' do
      expect(migration).to receive(:drop_partitions).with(:user_audit_events).ordered
      expect(migration).to receive(:drop_partitions).with(:group_audit_events).ordered
      expect(migration).to receive(:drop_partitions).with(:project_audit_events).ordered
      expect(migration).to receive(:drop_partitions).with(:instance_audit_events).ordered
      expect(migration).to receive(:create_daterange_partitions).with(:user_audit_events, "created_at", min_date,
        beginning_of_next_month).ordered
      expect(migration).to receive(:create_daterange_partitions).with(:group_audit_events, "created_at", min_date,
        beginning_of_next_month).ordered
      expect(migration).to receive(:create_daterange_partitions).with(:project_audit_events, "created_at", min_date,
        beginning_of_next_month).ordered
      expect(migration).to receive(:create_daterange_partitions).with(:instance_audit_events, "created_at", min_date,
        beginning_of_next_month).ordered

      migration.up
    end
  end

  describe '#up' do
    context "when audit event partitions exists" do
      before do
        mock_partitions = [
          {
            "identifier" => "gitlab_partitions_dynamic.audit_events_000000",
            "condition" => "FOR VALUES FROM (MINVALUE) TO ('2024-03-01 00:00:00')"
          },
          {
            "identifier" => "gitlab_partitions_dynamic.audit_events_202406",
            "condition" => "FOR VALUES FROM ('2024-03-01 00:00:00') TO ('2024-04-01 00:00:00')"
          }
        ]

        allow(Date).to receive(:today).and_return(today)
        allow(migration).to receive(:current_partitions).and_return(mock_partitions)
      end

      include_examples 'calls partition methods with correct args', "2024-03-01".to_date
    end

    context "when audit event partitions does not exist" do
      before do
        mock_partitions = []

        allow(Date).to receive(:today).and_return(today)
        allow(migration).to receive(:current_partitions).and_return(mock_partitions)
      end

      include_examples 'calls partition methods with correct args', '2024-04-01'.to_date
    end
  end

  describe '#down' do
    it 'calls drop partitions with correct args' do
      expect(migration).to receive(:drop_partitions).with(:user_audit_events)
      expect(migration).to receive(:drop_partitions).with(:group_audit_events)
      expect(migration).to receive(:drop_partitions).with(:project_audit_events)
      expect(migration).to receive(:drop_partitions).with(:instance_audit_events)

      migration.down
    end
  end

  describe '#drop_partitions' do
    let(:partitioned_table) { :_test_partitioned_table }
    let(:current_schema) { connection.select_value("SELECT current_schema()") }
    let(:identifier) { "gitlab_partitions_dynamic._test_partition_01" }

    subject(:drop_partitions) { migration.send(:drop_partitions, partitioned_table) }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{current_schema}._test_partitioned_table (
          id serial NOT NULL,
          created_at timestamptz NOT NULL,
          PRIMARY KEY (id, created_at)
        ) PARTITION BY RANGE(created_at);

        CREATE TABLE #{identifier} PARTITION OF #{current_schema}._test_partitioned_table
        FOR VALUES FROM ('2020-01-01') to ('2020-02-01');
      SQL
    end

    after do
      connection.execute("DROP TABLE IF EXISTS #{current_schema}._test_partitioned_table CASCADE;")
    end

    it 'drops all partitions' do
      expect_total_partitions(partitioned_table, 1)

      drop_partitions

      expect_total_partitions(partitioned_table, 0)
    end
  end
end
