# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddTriggerOnCiJobArtifactStatesForGeoSummaries, migration: :gitlab_ci, feature_category: :geo_replication do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:trigger_name) { described_class::TRIGGER_NAME }

  describe '#up' do
    before do
      migrate!
      connection.execute(
        'ALTER TABLE ci_job_artifact_states DROP CONSTRAINT IF EXISTS fk_rails_80a9cba3b2_p'
      )
    end

    it 'creates a dirty summary row on insert', :aggregate_failures do
      insert_artifact_state(job_artifact_id: 1)

      summary = find_summary(bucket_number: 1 % 100_000)
      expect(summary).to be_present
      expect(summary['state']).to eq(1)
    end

    it 'marks the bucket dirty on verification_state update' do
      insert_artifact_state(job_artifact_id: 2)
      set_summary_state(bucket_number: 2 % 100_000, state: 0)

      connection.execute("UPDATE ci_job_artifact_states SET verification_state = 1 WHERE job_artifact_id = 2")

      summary = find_summary(bucket_number: 2 % 100_000)
      expect(summary['state']).to eq(1)
    end

    it 'marks the bucket dirty on delete' do
      insert_artifact_state(job_artifact_id: 3)
      set_summary_state(bucket_number: 3 % 100_000, state: 0)

      connection.execute("DELETE FROM ci_job_artifact_states WHERE job_artifact_id = 3")

      summary = find_summary(bucket_number: 3 % 100_000)
      expect(summary['state']).to eq(1)
    end

    it 'does not overwrite a calculating bucket' do
      insert_artifact_state(job_artifact_id: 4)
      set_summary_state(bucket_number: 4 % 100_000, state: 2)

      connection.execute("UPDATE ci_job_artifact_states SET verification_state = 1 WHERE job_artifact_id = 4")

      summary = find_summary(bucket_number: 4 % 100_000)
      expect(summary['state']).to eq(2)
    end
  end

  describe '#down' do
    it 'removes the trigger and function', :aggregate_failures do
      migrate!
      schema_migrate_down!

      trigger_result = connection.select_value("SELECT 1 FROM pg_trigger WHERE tgname = '#{trigger_name}'")
      expect(trigger_result).to be_nil

      function_result = connection.select_value(
        "SELECT 1 FROM pg_proc WHERE proname = '#{described_class::FUNCTION_NAME}'"
      )
      expect(function_result).to be_nil
    end
  end

  private

  def insert_artifact_state(job_artifact_id:)
    connection.execute(<<~SQL.squish)
      INSERT INTO ci_job_artifact_states (job_artifact_id, partition_id, project_id, verification_state)
      VALUES (#{job_artifact_id}, 100, 1, 0)
    SQL
  end

  def find_summary(bucket_number:)
    connection.select_one(<<~SQL.squish)
      SELECT * FROM geo_ci_job_artifact_verification_summaries WHERE bucket_number = #{bucket_number}
    SQL
  end

  def set_summary_state(bucket_number:, state:)
    connection.execute(<<~SQL.squish)
      UPDATE geo_ci_job_artifact_verification_summaries SET state = #{state} WHERE bucket_number = #{bucket_number}
    SQL
  end
end
