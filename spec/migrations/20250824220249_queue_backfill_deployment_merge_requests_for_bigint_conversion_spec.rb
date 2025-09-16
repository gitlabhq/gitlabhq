# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillDeploymentMergeRequestsForBigintConversion, feature_category: :deployment_management do
  let!(:batched_migration) { described_class::MIGRATION }

  context 'when columns to backfill exist' do
    let(:connection) { ApplicationRecord.connection }

    around do |example|
      connection.add_column :deployment_merge_requests, :deployment_id_convert_to_bigint, :bigint, if_not_exists: true
      connection.add_column :deployment_merge_requests, :merge_request_id_convert_to_bigint, :bigint,
        if_not_exists: true
      connection.add_column :deployment_merge_requests, :environment_id_convert_to_bigint, :bigint, if_not_exists: true

      example.run

      connection.remove_column :deployment_merge_requests, :deployment_id_convert_to_bigint, :bigint, if_exists: true
      connection.remove_column :deployment_merge_requests, :merge_request_id_convert_to_bigint, :bigint, if_exists: true
      connection.remove_column :deployment_merge_requests, :environment_id_convert_to_bigint, :bigint, if_exists: true
    end

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: :deployment_merge_requests,
            column_name: :deployment_id,
            interval: described_class::DELAY_INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE,
            gitlab_schema: :gitlab_main_org,
            job_arguments: [
              %i[deployment_id merge_request_id environment_id],
              %i[deployment_id_convert_to_bigint merge_request_id_convert_to_bigint environment_id_convert_to_bigint]
            ]
          )
        }
      end
    end
  end

  context 'when no columns to backfill do not exist' do
    it 'does not schedule a batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end
  end
end
