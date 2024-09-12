# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe TruncateCiFinishedBuildChSyncEventsIfClickHouseNotConfigured,
  migration: :gitlab_ci, feature_category: :fleet_visibility do
  let(:migration) { described_class.new }
  let(:connection) { ::Ci::ApplicationRecord.connection }
  let(:table_name) { :p_ci_finished_build_ch_sync_events }
  let(:sync_events_table) { table(table_name, primary_key: :build_id, database: :ci) }
  let(:partition) { 100 }

  before do
    # NOTE: p_ci_finished_build_ch_sync_events does not have a default partition attached,
    # and the partitioned_table helper does not create one if the :disallow_database_ddl_feature_flags ops FF
    # is enabled, so we need to create one here temporarily.
    connection.execute <<~SQL
      DROP TABLE IF EXISTS #{table_name}_#{partition};

      CREATE TABLE #{table_name}_#{partition} PARTITION OF #{table_name}
        FOR VALUES IN (#{partition});
    SQL

    sync_events_table.create!(partition: partition, build_id: 1, build_finished_at: Time.current, project_id: 1)
    sync_events_table.create!(partition: partition, build_id: 2, build_finished_at: Time.current)
  end

  after do
    connection.execute <<~SQL
      DROP TABLE #{table_name}_#{partition};
    SQL
  end

  context 'when ClickHouse is not configured' do
    before do
      allow(::Gitlab::ClickHouse).to receive(:configured?).and_return(false)
    end

    it 'truncates p_ci_finished_build_ch_sync_events table' do
      expect { migrate! }.to change { sync_events_table.count }.from(2).to(0)
      expect { schema_migrate_down! }.not_to change { sync_events_table.count }.from(0)
    end
  end

  context 'when ClickHouse is configured' do
    before do
      allow(::Gitlab::ClickHouse).to receive(:configured?).and_return(true)
    end

    it 'does not truncate p_ci_finished_build_ch_sync_events table' do
      expect { migrate! }.not_to change { sync_events_table.count }.from(2)
      expect { schema_migrate_down! }.not_to change { sync_events_table.count }.from(2)
    end
  end
end
