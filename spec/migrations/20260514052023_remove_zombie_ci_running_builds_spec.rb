# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveZombieCiRunningBuilds, migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:builds) { table(:p_ci_builds, database: :ci, primary_key: :id) }
  let(:pipelines) { table(:p_ci_pipelines, database: :ci, primary_key: :id) }
  let(:running_builds) { table(:ci_running_builds, database: :ci) }

  let(:default_attributes) { { project_id: non_existing_record_id, partition_id: 100 } }
  let!(:pipeline) { pipelines.create!(default_attributes) }

  let!(:success_build) do
    builds.create!(
      default_attributes.merge(
        commit_id: pipeline.id,
        type: 'Ci::Build',
        status: 'success'
      )
    )
  end

  let!(:failed_build) do
    builds.create!(
      default_attributes.merge(
        commit_id: pipeline.id,
        type: 'Ci::Build',
        status: 'failed'
      )
    )
  end

  let!(:canceled_build) do
    builds.create!(
      default_attributes.merge(
        commit_id: pipeline.id,
        type: 'Ci::Build',
        status: 'canceled'
      )
    )
  end

  let!(:skipped_build) do
    builds.create!(
      default_attributes.merge(
        commit_id: pipeline.id,
        type: 'Ci::Build',
        status: 'skipped'
      )
    )
  end

  let!(:running_build) do
    builds.create!(
      default_attributes.merge(
        commit_id: pipeline.id,
        type: 'Ci::Build',
        status: 'running'
      )
    )
  end

  let!(:pending_build) do
    builds.create!(
      default_attributes.merge(
        commit_id: pipeline.id,
        type: 'Ci::Build',
        status: 'pending'
      )
    )
  end

  let(:running_build_default_attributes) { { runner_id: non_existing_record_id, runner_type: 1 } }

  let!(:success_running_build) do
    running_builds.create!(
      running_build_default_attributes.merge(
        build_id: success_build.id,
        partition_id: success_build.partition_id,
        project_id: success_build.project_id
      )
    )
  end

  let!(:failed_running_build) do
    running_builds.create!(
      running_build_default_attributes.merge(
        build_id: failed_build.id,
        partition_id: failed_build.partition_id,
        project_id: failed_build.project_id
      )
    )
  end

  let!(:canceled_running_build) do
    running_builds.create!(
      running_build_default_attributes.merge(
        build_id: canceled_build.id,
        partition_id: canceled_build.partition_id,
        project_id: canceled_build.project_id
      )
    )
  end

  let!(:skipped_running_build) do
    running_builds.create!(
      running_build_default_attributes.merge(
        build_id: skipped_build.id,
        partition_id: skipped_build.partition_id,
        project_id: skipped_build.project_id
      )
    )
  end

  let!(:valid_running_build) do
    running_builds.create!(
      running_build_default_attributes.merge(
        build_id: running_build.id,
        partition_id: running_build.partition_id,
        project_id: running_build.project_id
      )
    )
  end

  let!(:pending_running_build) do
    running_builds.create!(
      running_build_default_attributes.merge(
        build_id: pending_build.id,
        partition_id: pending_build.partition_id,
        project_id: pending_build.project_id
      )
    )
  end

  describe '#up' do
    it 'wraps the cleanup in without_data_isolation' do
      expect(Gitlab::Database::DataIsolation::ScopeHelper).to receive(:without_data_isolation).and_call_original

      migrate!
    end

    it 'removes ci_running_builds rows for completed builds and keeps non-completed ones', :aggregate_failures do
      expect { migrate! }.to change { running_builds.count }.from(6).to(2)

      expect(running_builds.where(id: success_running_build.id)).to be_empty
      expect(running_builds.where(id: failed_running_build.id)).to be_empty
      expect(running_builds.where(id: canceled_running_build.id)).to be_empty
      expect(running_builds.where(id: skipped_running_build.id)).to be_empty

      expect(running_builds.where(id: valid_running_build.id)).to be_present
      expect(running_builds.where(id: pending_running_build.id)).to be_present
    end

    context 'when more zombie rows exist than fit in one batch' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)
      end

      it 'keeps looping until all matching rows are deleted' do
        expect { migrate! }.to change { running_builds.count }.from(6).to(2)
      end
    end

    context 'when there are no zombie rows' do
      before do
        running_builds.where(id: [
          success_running_build.id,
          failed_running_build.id,
          canceled_running_build.id,
          skipped_running_build.id
        ]).delete_all
      end

      it 'does not delete anything' do
        expect { migrate! }.not_to change { running_builds.count }
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { schema_migrate_down! }.not_to raise_error
    end
  end
end
