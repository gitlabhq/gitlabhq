# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillGitlabSubscriptionsHostedPlanNameUid,
  feature_category: :subscription_management do
  let(:plans) { table(:plans) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:gitlab_subscriptions) { table(:gitlab_subscriptions) }

  let!(:premium_plan) { plans.create!(name: 'premium', title: 'Premium', plan_name_uid: 5) }
  let!(:ultimate_plan) { plans.create!(name: 'ultimate', title: 'Ultimate', plan_name_uid: 7) }

  let!(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }
  let!(:namespace1) do
    namespaces.create!(name: 'ns1', path: 'ns1', type: 'Group', organization_id: organization.id)
  end

  let!(:namespace2) do
    namespaces.create!(name: 'ns2', path: 'ns2', type: 'Group', organization_id: organization.id)
  end

  let!(:sub_to_backfill) do
    gitlab_subscriptions.create!(
      namespace_id: namespace1.id,
      hosted_plan_id: premium_plan.id,
      hosted_plan_name_uid: nil
    )
  end

  let!(:sub_already_set) do
    gitlab_subscriptions.create!(
      namespace_id: namespace2.id,
      hosted_plan_id: ultimate_plan.id,
      hosted_plan_name_uid: 7
    )
  end

  let(:migration_args) do
    {
      start_id: gitlab_subscriptions.minimum(:id),
      end_id: gitlab_subscriptions.maximum(:id),
      batch_table: :gitlab_subscriptions,
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
        .to change { sub_to_backfill.reload.hosted_plan_name_uid }.from(nil).to(5)
        .and not_change { sub_already_set.reload.hosted_plan_name_uid }
    end

    context 'when records exist outside the batch range' do
      let!(:namespace3) do
        namespaces.create!(name: 'ns3', path: 'ns3', type: 'Group', organization_id: organization.id)
      end

      let(:migration_args) do
        super().merge(
          start_id: sub_to_backfill.id,
          end_id: sub_to_backfill.id
        )
      end

      let!(:outside_batch) do
        gitlab_subscriptions.create!(
          namespace_id: namespace3.id,
          hosted_plan_id: ultimate_plan.id,
          hosted_plan_name_uid: nil
        )
      end

      it 'only updates records within the batch range' do
        expect { perform_migration }
          .to change { sub_to_backfill.reload.hosted_plan_name_uid }.from(nil).to(5)
          .and not_change { outside_batch.reload.hosted_plan_name_uid }.from(nil)
      end
    end
  end
end
