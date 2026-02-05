# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiRunnersAllowedPlanNameUids,
  feature_category: :runner_core do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:plans) { table(:plans, database: :main, primary_key: :id) }
  let(:ci_runners) { table(:ci_runners, database: :ci, primary_key: :id) }

  let!(:premium_plan) { plans.create!(name: 'premium', title: 'Premium', plan_name_uid: 5) }
  let!(:ultimate_plan) { plans.create!(name: 'ultimate', title: 'Ultimate', plan_name_uid: 7) }

  let!(:runner_to_backfill) do
    ci_runners.create!(
      runner_type: 1,
      allowed_plan_ids: [premium_plan.id, ultimate_plan.id]
    )
  end

  let!(:runner_empty_plan_ids) do
    ci_runners.create!(
      runner_type: 1,
      allowed_plan_ids: []
    )
  end

  let(:migration_args) do
    {
      start_id: ci_runners.minimum(:id),
      end_id: ci_runners.maximum(:id),
      batch_table: :ci_runners,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**migration_args).perform }

  describe '#perform' do
    it 'backfills allowed_plan_name_uids from plan mapping' do
      perform_migration

      expect(runner_to_backfill.reload.allowed_plan_name_uids).to match_array([5, 7])
      expect(runner_empty_plan_ids.reload.allowed_plan_name_uids).to eq([])
    end

    it 're-derives values when run again (idempotent)' do
      perform_migration

      expect(runner_to_backfill.reload.allowed_plan_name_uids).to match_array([5, 7])

      perform_migration

      expect(runner_to_backfill.reload.allowed_plan_name_uids).to match_array([5, 7])
    end

    context 'when the plan mapping is empty' do
      before do
        plans.delete_all
      end

      it 'does not update any records' do
        expect { perform_migration }
          .to not_change { runner_to_backfill.reload.allowed_plan_name_uids }
          .and not_change { runner_empty_plan_ids.reload.allowed_plan_name_uids }
      end
    end

    context 'when records exist outside the batch range' do
      let(:migration_args) do
        super().merge(
          start_id: runner_to_backfill.id,
          end_id: runner_to_backfill.id
        )
      end

      let!(:outside_batch) do
        ci_runners.create!(
          runner_type: 1,
          allowed_plan_ids: [ultimate_plan.id]
        )
      end

      it 'only updates records within the batch range' do
        perform_migration

        expect(runner_to_backfill.reload.allowed_plan_name_uids).to match_array([5, 7])
        expect(outside_batch.reload.allowed_plan_name_uids).to eq([])
      end
    end
  end
end
