# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPlanLimitsPlanNameUid, feature_category: :consumables_cost_management do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }

  let!(:default_plan) { plans.create!(name: 'default', title: 'Default', plan_name_uid: 1) }
  let!(:premium_plan) { plans.create!(name: 'premium', title: 'Premium', plan_name_uid: 5) }

  let!(:limit_to_backfill) { plan_limits.create!(plan_id: default_plan.id, plan_name_uid: nil) }
  let!(:limit_already_set) { plan_limits.create!(plan_id: premium_plan.id, plan_name_uid: 5) }

  let(:migration_args) do
    {
      start_id: plan_limits.minimum(:id),
      end_id: plan_limits.maximum(:id),
      batch_table: :plan_limits,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**migration_args).perform }

  describe '#perform' do
    it 'backfills plan_name_uid from the plans table' do
      expect { perform_migration }
        .to change { limit_to_backfill.reload.plan_name_uid }.from(nil).to(1)
        .and not_change { limit_already_set.reload.plan_name_uid }
    end

    context 'when records exist outside the batch range' do
      let!(:free_plan) { plans.create!(name: 'free', title: 'Free', plan_name_uid: 2) }

      let(:migration_args) do
        super().merge(
          start_id: limit_to_backfill.id,
          end_id: limit_to_backfill.id
        )
      end

      let!(:outside_batch) { plan_limits.create!(plan_id: free_plan.id, plan_name_uid: nil) }

      it 'only updates records within the batch range' do
        expect { perform_migration }
          .to change { limit_to_backfill.reload.plan_name_uid }.from(nil).to(1)
          .and not_change { outside_batch.reload.plan_name_uid }.from(nil)
      end
    end
  end
end
