# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::NullifyBuildsAutoCanceledById,
  feature_category: :continuous_integration, migration: :gitlab_ci do
  let(:pipelines_table) { table(:p_ci_pipelines, database: :ci, primary_key: :id) }
  let(:builds_table) { table(:p_ci_builds, database: :ci, primary_key: :id) }

  let(:default_attributes) { { project_id: 600, partition_id: 100 } }
  let!(:regular_pipeline) { pipelines_table.create!(id: 1, **default_attributes) }
  let!(:deleted_pipeline) { pipelines_table.create!(id: 2, **default_attributes) }
  let!(:other_pipeline) { pipelines_table.create!(id: 3, **default_attributes) }

  let!(:regular_build) do
    builds_table.create!(commit_id: regular_pipeline.id, **default_attributes)
  end

  let!(:orphaned_build) do
    builds_table.create!(
      auto_canceled_by_id: deleted_pipeline.id,
      auto_canceled_by_partition_id: deleted_pipeline.partition_id,
      commit_id: regular_pipeline.id,
      **default_attributes
    )
  end

  let(:other_build) do
    builds_table.create!(
      auto_canceled_by_id: other_pipeline.id,
      auto_canceled_by_partition_id: other_pipeline.partition_id,
      commit_id: regular_pipeline.id,
      **default_attributes
    )
  end

  let(:connection) { Ci::ApplicationRecord.connection }

  around do |example|
    connection.transaction do
      connection.execute(<<~SQL)
        ALTER TABLE ci_pipelines DISABLE TRIGGER ALL;
      SQL

      example.run

      connection.execute(<<~SQL)
        ALTER TABLE ci_pipelines ENABLE TRIGGER ALL;
      SQL
    end
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: builds_table.minimum(:auto_canceled_by_id),
        end_id: builds_table.maximum(:auto_canceled_by_id),
        batch_table: :p_ci_builds,
        batch_column: :auto_canceled_by_id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      )
    end

    it 'nullifies canceled columns for non-existing pipelines', :aggregate_failures do
      expect { deleted_pipeline.delete }
        .to not_change { builds_table.where(auto_canceled_by_id: deleted_pipeline.id).count }

      expect { migration.perform }.to not_change { builds_table.count }

      expect(regular_build.reload).to be_persisted
      expect(orphaned_build.reload.auto_canceled_by_id).to be_nil
      expect(orphaned_build.reload.auto_canceled_by_partition_id).to be_nil
      expect(other_build.reload.auto_canceled_by_id).to be_present
      expect(other_build.reload.auto_canceled_by_partition_id).to be_present
    end
  end
end
