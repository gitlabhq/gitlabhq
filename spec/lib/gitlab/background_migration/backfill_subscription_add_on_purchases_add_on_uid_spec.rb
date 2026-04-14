# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSubscriptionAddOnPurchasesAddOnUid,
  feature_category: :plan_provisioning do
  let(:add_ons) { table(:subscription_add_ons) }
  let(:add_on_purchases) { table(:subscription_add_on_purchases) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }

  let!(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }
  let!(:code_suggestions_add_on) { add_ons.create!(name: 1, description: 'Duo Pro') }
  let!(:duo_enterprise_add_on) { add_ons.create!(name: 3, description: 'Duo Enterprise') }

  let(:migration_args) do
    {
      start_id: add_on_purchases.minimum(:id),
      end_id: add_on_purchases.maximum(:id),
      batch_table: :subscription_add_on_purchases,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**migration_args).perform }

  def create_namespace(name)
    namespaces.create!(name: name, path: name, type: 'Group', organization_id: organization.id)
  end

  def create_purchase(add_on:, namespace:, uid: nil)
    add_on_purchases.create!(
      subscription_add_on_id: add_on.id,
      namespace_id: namespace.id,
      organization_id: organization.id,
      quantity: 1,
      expires_on: 1.year.from_now,
      started_at: 1.day.ago,
      purchase_xid: "purchase-#{SecureRandom.hex(4)}",
      subscription_add_on_uid: uid
    )
  end

  describe '#perform' do
    let!(:namespace) { create_namespace('ns1') }
    let!(:purchase_to_backfill) { create_purchase(add_on: code_suggestions_add_on, namespace: namespace) }

    it 'backfills subscription_add_on_uid from the associated add-on name' do
      expect { perform_migration }
        .to change { purchase_to_backfill.reload.subscription_add_on_uid }.from(nil).to(1)
    end

    it 'is idempotent' do
      described_class.new(**migration_args).perform

      expect { perform_migration }
        .not_to change { purchase_to_backfill.reload.subscription_add_on_uid }
    end

    context 'when purchase already has subscription_add_on_uid set' do
      let!(:purchase_already_set) do
        create_purchase(add_on: duo_enterprise_add_on, namespace: create_namespace('ns2'), uid: 3)
      end

      it 'does not update the record' do
        expect { perform_migration }
          .to not_change { purchase_already_set.reload.subscription_add_on_uid }
      end
    end

    context 'when multiple purchases need backfilling with different add-on types' do
      let!(:another_purchase) { create_purchase(add_on: duo_enterprise_add_on, namespace: create_namespace('ns3')) }

      it 'backfills each purchase with the correct add-on name enum value' do
        perform_migration

        expect(purchase_to_backfill.reload.subscription_add_on_uid).to eq(1)
        expect(another_purchase.reload.subscription_add_on_uid).to eq(3)
      end
    end

    context 'when records exist outside the batch range' do
      let!(:outside_batch) { create_purchase(add_on: duo_enterprise_add_on, namespace: create_namespace('ns4')) }

      let(:migration_args) do
        super().merge(
          start_id: purchase_to_backfill.id,
          end_id: purchase_to_backfill.id
        )
      end

      it 'only updates records within the batch range' do
        expect { perform_migration }
          .to change { purchase_to_backfill.reload.subscription_add_on_uid }.from(nil).to(1)
          .and not_change { outside_batch.reload.subscription_add_on_uid }.from(nil)
      end
    end
  end
end
