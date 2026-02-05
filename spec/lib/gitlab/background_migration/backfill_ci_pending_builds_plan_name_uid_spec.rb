# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiPendingBuildsPlanNameUid,
  feature_category: :continuous_integration do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:plans) { table(:plans, database: :main, primary_key: :id) }
  let(:ci_builds) { table(:p_ci_builds, database: :ci, primary_key: :id) }
  let(:ci_pending_builds) { table(:ci_pending_builds, database: :ci, primary_key: :id) }

  let!(:premium_plan) { plans.create!(name: 'premium', title: 'Premium', plan_name_uid: 5) }
  let!(:ultimate_plan) { plans.create!(name: 'ultimate', title: 'Ultimate', plan_name_uid: 7) }

  let!(:build1) { ci_builds.create!(partition_id: 100, project_id: 1) }
  let!(:build2) { ci_builds.create!(partition_id: 100, project_id: 1) }
  let!(:build3) { ci_builds.create!(partition_id: 100, project_id: 1) }

  let!(:build_to_backfill) do
    ci_pending_builds.create!(
      build_id: build1.id,
      project_id: 1,
      plan_id: premium_plan.id,
      plan_name_uid: nil,
      partition_id: 100
    )
  end

  let!(:build_already_set) do
    ci_pending_builds.create!(
      build_id: build2.id,
      project_id: 1,
      plan_id: ultimate_plan.id,
      plan_name_uid: 7,
      partition_id: 100
    )
  end

  let!(:build_null_plan_id) do
    ci_pending_builds.create!(
      build_id: build3.id,
      project_id: 1,
      plan_id: nil,
      plan_name_uid: nil,
      partition_id: 100
    )
  end

  let(:migration_args) do
    {
      start_id: ci_pending_builds.minimum(:id),
      end_id: ci_pending_builds.maximum(:id),
      batch_table: :ci_pending_builds,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**migration_args).perform }

  describe '#perform' do
    it 'backfills plan_name_uid using cross-database plan mapping' do
      expect { perform_migration }
        .to change { build_to_backfill.reload.plan_name_uid }.from(nil).to(5)
        .and not_change { build_already_set.reload.plan_name_uid }
        .and not_change { build_null_plan_id.reload.plan_name_uid }.from(nil)
    end

    context 'when the plan mapping is empty' do
      before do
        plans.delete_all
      end

      it 'does not update any records' do
        expect { perform_migration }
          .to not_change { build_to_backfill.reload.plan_name_uid }.from(nil)
          .and not_change { build_null_plan_id.reload.plan_name_uid }.from(nil)
      end
    end

    context 'when records exist outside the batch range' do
      let!(:build4) { ci_builds.create!(partition_id: 100, project_id: 1) }

      let(:migration_args) do
        super().merge(
          start_id: build_to_backfill.id,
          end_id: build_to_backfill.id
        )
      end

      let!(:outside_batch) do
        ci_pending_builds.create!(
          build_id: build4.id,
          project_id: 1,
          plan_id: ultimate_plan.id,
          plan_name_uid: nil,
          partition_id: 100
        )
      end

      it 'only updates records within the batch range' do
        expect { perform_migration }
          .to change { build_to_backfill.reload.plan_name_uid }.from(nil).to(5)
          .and not_change { outside_batch.reload.plan_name_uid }.from(nil)
      end
    end
  end
end
