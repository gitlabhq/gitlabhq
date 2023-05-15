# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveBackfilledJobArtifactsExpireAt do
  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchedMigrationJob }

  describe '#perform' do
    let(:job_artifact) { table(:ci_job_artifacts, database: :ci) }

    let(:test_worker) do
      described_class.new(
        start_id: 1,
        end_id: 100,
        batch_table: :ci_job_artifacts,
        batch_column: :id,
        sub_batch_size: 10,
        pause_ms: 0,
        connection: Ci::ApplicationRecord.connection
      )
    end

    let!(:namespace) { table(:namespaces).create!(id: 1, name: 'user', path: 'user') }
    let!(:project) do
      table(:projects).create!(
        id: 1,
        name: 'gitlab1',
        path: 'gitlab1',
        project_namespace_id: 1,
        namespace_id: namespace.id
      )
    end

    subject { test_worker.perform }

    context 'with artifacts that has backfilled expire_at' do
      let!(:created_on_00_30_45_minutes_on_21_22_23) do
        create_job_artifact(id: 1, file_type: 1, expire_at: Time.zone.parse('2022-01-21 00:00:00.000'))
        create_job_artifact(id: 2, file_type: 1, expire_at: Time.zone.parse('2022-01-21 01:30:00.000'))
        create_job_artifact(id: 3, file_type: 1, expire_at: Time.zone.parse('2022-01-22 12:00:00.000'))
        create_job_artifact(id: 4, file_type: 1, expire_at: Time.zone.parse('2022-01-22 12:30:00.000'))
        create_job_artifact(id: 5, file_type: 1, expire_at: Time.zone.parse('2022-01-23 23:00:00.000'))
        create_job_artifact(id: 6, file_type: 1, expire_at: Time.zone.parse('2022-01-23 23:30:00.000'))
        create_job_artifact(id: 7, file_type: 1, expire_at: Time.zone.parse('2022-01-23 06:45:00.000'))
      end

      let!(:created_close_to_00_or_30_minutes) do
        create_job_artifact(id: 8, file_type: 1, expire_at: Time.zone.parse('2022-01-21 00:00:00.001'))
        create_job_artifact(id: 9, file_type: 1, expire_at: Time.zone.parse('2022-01-21 00:30:00.999'))
      end

      let!(:created_on_00_or_30_minutes_on_other_dates) do
        create_job_artifact(id: 10, file_type: 1, expire_at: Time.zone.parse('2022-01-01 00:00:00.000'))
        create_job_artifact(id: 11, file_type: 1, expire_at: Time.zone.parse('2022-01-19 12:00:00.000'))
        create_job_artifact(id: 12, file_type: 1, expire_at: Time.zone.parse('2022-01-24 23:30:00.000'))
      end

      let!(:created_at_other_times) do
        create_job_artifact(id: 13, file_type: 1, expire_at: Time.zone.parse('2022-01-19 00:00:00.000'))
        create_job_artifact(id: 14, file_type: 1, expire_at: Time.zone.parse('2022-01-19 00:30:00.000'))
        create_job_artifact(id: 15, file_type: 1, expire_at: Time.zone.parse('2022-01-24 00:00:00.000'))
        create_job_artifact(id: 16, file_type: 1, expire_at: Time.zone.parse('2022-01-24 00:30:00.000'))
      end

      it 'removes expire_at on job artifacts that have expire_at on 00, 30 or 45 minute of 21, 22, 23 of the month' do
        expect { subject }.to change { job_artifact.where(expire_at: nil).count }.from(0).to(7)
      end

      it 'keeps expire_at on other job artifacts' do
        expect { subject }.to change { job_artifact.where.not(expire_at: nil).count }.from(16).to(9)
      end
    end

    context 'with trace artifacts that has backfilled expire_at' do
      let!(:trace_artifacts) do
        create_job_artifact(id: 1, file_type: 3, expire_at: Time.zone.parse('2022-01-01 00:00:00.000'))
        create_job_artifact(id: 2, file_type: 3, expire_at: Time.zone.parse('2022-01-21 00:00:00.000'))
      end

      it 'removes expire_at on trace job artifacts' do
        expect { subject }.to change { job_artifact.where(expire_at: nil).count }.from(0).to(2)
      end
    end

    private

    def create_job_artifact(id:, file_type:, expire_at:)
      job = table(:ci_builds, database: :ci).create!(id: id, partition_id: 100)
      job_artifact.create!(
        id: id, job_id: job.id, expire_at: expire_at, project_id: project.id,
        file_type: file_type, partition_id: 100
      )
    end
  end
end
