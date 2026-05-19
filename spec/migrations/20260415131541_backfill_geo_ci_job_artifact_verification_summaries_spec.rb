# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillGeoCiJobArtifactVerificationSummaries, migration: :gitlab_ci, feature_category: :geo_replication do
  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#up' do
    it 'creates 100,000 summary rows' do
      migrate!

      expect(summary_count).to eq(100_000)
    end

    it 'creates rows with state dirty (1) and zero counts', :aggregate_failures do
      migrate!

      sample = connection.select_one('SELECT * FROM geo_ci_job_artifact_verification_summaries LIMIT 1')
      expect(sample['state']).to eq(1)
      expect(sample['total_count']).to eq(0)
      expect(sample['verified_count']).to eq(0)
      expect(sample['failed_count']).to eq(0)
    end

    it 'creates bucket numbers from 0 to 99,999', :aggregate_failures do
      migrate!

      min = connection.select_value('SELECT MIN(bucket_number) FROM geo_ci_job_artifact_verification_summaries')
      max = connection.select_value('SELECT MAX(bucket_number) FROM geo_ci_job_artifact_verification_summaries')
      expect(min).to eq(0)
      expect(max).to eq(99_999)
    end

    it 'is idempotent and does not fail on re-run' do
      migrate!
      expect(summary_count).to eq(100_000)

      expect { migrate! }.not_to raise_error
      expect(summary_count).to eq(100_000)
    end

    it 'does not overwrite existing rows' do
      connection.execute(<<~SQL.squish)
        INSERT INTO geo_ci_job_artifact_verification_summaries
          (bucket_number, state, total_count, verified_count, failed_count, state_changed_at, created_at, updated_at)
        VALUES (0, 0, 42, 40, 2, NOW(), NOW(), NOW())
      SQL

      migrate!

      existing = connection.select_one(
        'SELECT * FROM geo_ci_job_artifact_verification_summaries WHERE bucket_number = 0'
      )
      expect(existing['total_count']).to eq(42)
    end
  end

  describe '#down' do
    it 'removes all summary rows' do
      migrate!
      expect(summary_count).to eq(100_000)

      schema_migrate_down!
      expect(summary_count).to eq(0)
    end
  end

  private

  def summary_count
    connection.select_value('SELECT COUNT(*) FROM geo_ci_job_artifact_verification_summaries')
  end
end
