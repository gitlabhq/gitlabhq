# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveOldJobTokens,
  feature_category: :continuous_integration, migration: :gitlab_ci do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:pipelines_table) { table(:p_ci_pipelines, database: :ci, primary_key: :id) }
  let(:builds_table) { table(:p_ci_builds, database: :ci, primary_key: :id) }

  let(:default_attributes) { { project_id: 500, partition_id: 100 } }
  let!(:old_pipeline) { pipelines_table.create!(default_attributes) }
  let!(:new_pipeline) { pipelines_table.create!(default_attributes) }

  let(:all_statuses) do
    %w[created
      waiting_for_resource
      preparing
      waiting_for_callback
      pending
      running
      success
      failed
      canceling
      canceled
      skipped
      manual
      scheduled]
  end

  let(:active_statuses) { described_class::ACTIVE_STATUSES }
  let(:inactive_statuses) { all_statuses - active_statuses }

  before do
    insert_jobs(pipeline: old_pipeline, created_at: 2.months.ago)
    insert_jobs(pipeline: new_pipeline, created_at: 1.week.ago)
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: builds_table.minimum(:id),
        end_id: builds_table.maximum(:id),
        batch_table: :p_ci_builds,
        batch_column: :id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      )
    end

    it 'nullifies tokens for old not running jobs', :aggregate_failures do
      expect(builds_table.where(token_encrypted: nil).any?).to be_falsey

      expect { migration.perform }.to not_change { builds_table.count }

      expect(builds_for(new_pipeline).where.not(token_encrypted: nil).count)
        .to eq(all_statuses.count)

      expect(builds_for(old_pipeline, status: active_statuses, token_encrypted: nil))
        .to be_empty

      expect(builds_for(old_pipeline, status: inactive_statuses, token_encrypted: nil).count)
        .to eq(inactive_statuses.count)
    end
  end

  def insert_jobs(pipeline:, created_at:)
    data = all_statuses.map do |status|
      default_attributes.merge(
        status: status,
        token_encrypted: SecureRandom.hex,
        commit_id: pipeline.id,
        created_at: created_at
      )
    end

    builds_table.insert_all(data, unique_by: [:id, :partition_id])
  end

  def builds_for(pipeline, attrs = {})
    builds_table.where(commit_id: pipeline, **attrs)
  end
end
