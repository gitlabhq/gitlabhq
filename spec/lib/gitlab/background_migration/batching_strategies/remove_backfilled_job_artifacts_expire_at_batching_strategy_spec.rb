# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::RemoveBackfilledJobArtifactsExpireAtBatchingStrategy, '#next_batch' do # rubocop:disable Layout/LineLength
  let_it_be(:namespace) { table(:namespaces).create!(id: 1, name: 'user', path: 'user') }
  let_it_be(:project) do
    table(:projects).create!(
      id: 1,
      name: 'gitlab1',
      path: 'gitlab1',
      project_namespace_id: 1,
      namespace_id: namespace.id
    )
  end

  let(:batching_strategy) { described_class.new(connection: Ci::ApplicationRecord.connection) }
  let(:job_artifact) { table(:ci_job_artifacts, database: :ci) }

  # job artifacts expiring at midnight in various timezones
  let!(:ci_job_artifact_1) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-21 00:00:00.000')) }
  let!(:ci_job_artifact_2) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-21 01:30:00.000')) }
  let!(:ci_job_artifact_3) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-22 12:00:00.000')) }
  let!(:ci_job_artifact_4) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-22 12:30:00.000')) }
  let!(:ci_job_artifact_5) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-23 23:00:00.000')) }
  let!(:ci_job_artifact_6) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-23 23:30:00.000')) }
  let!(:ci_job_artifact_7) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-23 06:45:00.000')) }
  # out ot scope job artifacts
  let!(:ci_job_artifact_8) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-21 00:00:00.001')) }
  let!(:ci_job_artifact_9) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-19 12:00:00.000')) }
  # job artifacts of trace type (file_type: 3)
  let!(:ci_job_artifact_10) { create_job_artifact(file_type: 3, expire_at: Time.zone.parse('2022-01-01 00:00:00.000')) }
  let!(:ci_job_artifact_11) { create_job_artifact(file_type: 3, expire_at: Time.zone.parse('2022-01-21 00:00:00.000')) }
  # out ot scope job artifacts
  let!(:ci_job_artifact_12) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-24 23:30:00.000')) }
  let!(:ci_job_artifact_13) { create_job_artifact(file_type: 1, expire_at: Time.zone.parse('2022-01-24 00:30:00.000')) }
  # job artifacts of trace type (file_type: 3)
  let!(:ci_job_artifact_14) { create_job_artifact(file_type: 3, expire_at: Time.zone.parse('2022-01-01 00:00:00.000')) }
  let!(:ci_job_artifact_15) { create_job_artifact(file_type: 3, expire_at: Time.zone.parse('2022-01-21 00:00:00.000')) }

  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy }

  context 'when starting on the first batch' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(
        :ci_job_artifacts,
        :id,
        batch_min_value: ci_job_artifact_1.id,
        batch_size: 5,
        job_arguments: []
      )
      expect(batch_bounds).to eq([ci_job_artifact_1.id, ci_job_artifact_5.id])
    end
  end

  context 'when the range includes out of scope records' do
    it 'returns the bounds of the next batch, skipping records outside the scope' do
      batch_bounds = batching_strategy.next_batch(
        :ci_job_artifacts,
        :id,
        batch_min_value: ci_job_artifact_1.id,
        batch_size: 10,
        job_arguments: []
      )
      expect(batch_bounds).to eq([ci_job_artifact_1.id, ci_job_artifact_14.id])
    end
  end

  context 'when the range begins on out of scope records' do
    it 'returns the bounds of the next batch, skipping records outside the scope' do
      batch_bounds = batching_strategy.next_batch(
        :ci_job_artifacts,
        :id,
        batch_min_value: ci_job_artifact_8.id,
        batch_size: 3,
        job_arguments: []
      )
      expect(batch_bounds).to eq([ci_job_artifact_10.id, ci_job_artifact_14.id])
    end
  end

  context 'when no additional batch remain' do
    it 'returns nil' do
      batch_bounds = batching_strategy.next_batch(
        :ci_job_artifacts,
        :id,
        batch_min_value: ci_job_artifact_15.id + 1,
        batch_size: 10,
        job_arguments: []
      )
      expect(batch_bounds).to be_nil
    end
  end

  private

  def create_job_artifact(file_type:, expire_at:)
    job = table(:ci_builds, database: :ci).create!
    job_artifact.create!(job_id: job.id, expire_at: expire_at, project_id: project.id, file_type: file_type)
  end
end
