# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillGitlabSubscriptionHistoriesHostedPlanNameUid,
  feature_category: :subscription_management do
  let(:plans) { table(:plans) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:gitlab_subscriptions) { table(:gitlab_subscriptions) }
  let(:gitlab_subscription_histories) { table(:gitlab_subscription_histories) }

  let!(:premium_plan) { plans.create!(name: 'premium', title: 'Premium', plan_name_uid: 5) }
  let!(:ultimate_plan) { plans.create!(name: 'ultimate', title: 'Ultimate', plan_name_uid: 7) }

  let!(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }
  let!(:namespace) do
    namespaces.create!(name: 'ns1', path: 'ns1', type: 'Group', organization_id: organization.id)
  end

  let!(:subscription) do
    gitlab_subscriptions.create!(namespace_id: namespace.id, hosted_plan_id: premium_plan.id)
  end

  let!(:history_to_backfill) do
    gitlab_subscription_histories.create!(
      gitlab_subscription_id: subscription.id,
      namespace_id: namespace.id,
      hosted_plan_id: premium_plan.id,
      hosted_plan_name_uid: nil
    )
  end

  let!(:history_already_set) do
    gitlab_subscription_histories.create!(
      gitlab_subscription_id: subscription.id,
      namespace_id: namespace.id,
      hosted_plan_id: ultimate_plan.id,
      hosted_plan_name_uid: 7
    )
  end

  let(:migration_args) do
    {
      start_id: gitlab_subscription_histories.minimum(:id),
      end_id: gitlab_subscription_histories.maximum(:id),
      batch_table: :gitlab_subscription_histories,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**migration_args).perform }

  describe '#perform' do
    it 'backfills hosted_plan_name_uid from the plans table' do
      expect { perform_migration }
        .to change { history_to_backfill.reload.hosted_plan_name_uid }.from(nil).to(5)
        .and not_change { history_already_set.reload.hosted_plan_name_uid }
    end

    context 'when records exist outside the batch range' do
      let(:migration_args) do
        super().merge(
          start_id: history_to_backfill.id,
          end_id: history_to_backfill.id
        )
      end

      let!(:outside_batch) do
        gitlab_subscription_histories.create!(
          gitlab_subscription_id: subscription.id,
          namespace_id: namespace.id,
          hosted_plan_id: ultimate_plan.id,
          hosted_plan_name_uid: nil
        )
      end

      it 'only updates records within the batch range' do
        expect { perform_migration }
          .to change { history_to_backfill.reload.hosted_plan_name_uid }.from(nil).to(5)
          .and not_change { outside_batch.reload.hosted_plan_name_uid }.from(nil)
      end
    end
  end
end
