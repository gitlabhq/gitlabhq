# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixGitlabSubscriptionHistoriesHostedPlanNameUid,
  feature_category: :subscription_management do
  let(:plans) { table(:plans) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:histories) { table(:gitlab_subscription_histories) }

  let!(:premium_plan) { plans.create!(name: 'premium', title: 'Premium', plan_name_uid: 5) }
  let!(:ultimate_plan) { plans.create!(name: 'ultimate', title: 'Ultimate', plan_name_uid: 7) }

  let!(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }

  let!(:namespace) do
    namespaces.create!(name: 'ns1', path: 'ns1', type: 'Group', organization_id: organization.id)
  end

  # History rows snapshot the subscription's uid at write time and are immutable, so a row
  # can hold a stale (wrong) non-NULL uid, a NULL uid, or a correct one.
  let!(:history_mismatched) do
    histories.create!(
      gitlab_subscription_id: 1,
      namespace_id: namespace.id,
      hosted_plan_id: ultimate_plan.id,
      hosted_plan_name_uid: 5
    )
  end

  let!(:history_null_uid) do
    histories.create!(
      gitlab_subscription_id: 2,
      namespace_id: namespace.id,
      hosted_plan_id: premium_plan.id,
      hosted_plan_name_uid: nil
    )
  end

  let!(:history_correct) do
    histories.create!(
      gitlab_subscription_id: 3,
      namespace_id: namespace.id,
      hosted_plan_id: ultimate_plan.id,
      hosted_plan_name_uid: 7
    )
  end

  let!(:history_no_plan) do
    histories.create!(
      gitlab_subscription_id: 4,
      namespace_id: namespace.id,
      hosted_plan_id: nil,
      hosted_plan_name_uid: 7
    )
  end

  let(:migration_args) do
    {
      start_id: histories.minimum(:id),
      end_id: histories.maximum(:id),
      batch_table: :gitlab_subscription_histories,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**migration_args).perform }

  describe '#perform' do
    it 'fixes mismatched hosted_plan_name_uid values' do
      expect { perform_migration }
        .to change { history_mismatched.reload.hosted_plan_name_uid }.from(5).to(7)
    end

    it 'backfills NULL hosted_plan_name_uid from the plans table' do
      expect { perform_migration }
        .to change { history_null_uid.reload.hosted_plan_name_uid }.from(nil).to(5)
    end

    it 'does not change already correct history rows' do
      expect { perform_migration }
        .to not_change { history_correct.reload.hosted_plan_name_uid }
    end

    it 'does not change history rows without a hosted_plan_id' do
      expect { perform_migration }
        .to not_change { history_no_plan.reload.hosted_plan_name_uid }
    end

    context 'when records exist outside the batch range' do
      let!(:outside_batch) do
        histories.create!(
          gitlab_subscription_id: 5,
          namespace_id: namespace.id,
          hosted_plan_id: ultimate_plan.id,
          hosted_plan_name_uid: 5 # mismatched, but outside batch range
        )
      end

      let(:migration_args) do
        super().merge(
          start_id: history_mismatched.id,
          end_id: history_no_plan.id
        )
      end

      it 'only updates records within the batch range' do
        expect { perform_migration }
          .to change { history_mismatched.reload.hosted_plan_name_uid }.from(5).to(7)
          .and not_change { outside_batch.reload.hosted_plan_name_uid }
      end
    end
  end
end
