# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSubscriptionAddOnPurchasesStartedAt, feature_category: :subscription_management do
  subject(:migration) do
    described_class.new(
      batch_table: :subscription_add_on_purchases,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  let(:add_ons) { table(:subscription_add_ons) }
  let(:add_on_purchases) { table(:subscription_add_on_purchases) }
  let(:organizations) { table(:organizations) }

  let!(:today) { Date.current }
  let!(:duo_pro_addon) { add_ons.create!(name: 1, description: "code suggestions") }
  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let!(:add_on_purchase) do
    add_on_purchases.create!(
      created_at: today,
      subscription_add_on_id: duo_pro_addon.id,
      quantity: 1,
      expires_on: today + 1.month,
      purchase_xid: 'order-1',
      trial: false,
      organization_id: organization.id,
      started_at: started_at
    )
  end

  context 'when started_at is nil' do
    let(:started_at) { nil }

    it 'backfills the nil `started_at` add on purchase' do
      migration.perform

      expect(add_on_purchase.reload.started_at).to eq(add_on_purchase.created_at)
    end
  end

  context 'when started_at is not nil' do
    let(:started_at) { today + 1.day }

    it 'does not backfill the add on purchase' do
      migration.perform

      expect(add_on_purchase.reload.started_at).not_to eq(add_on_purchase.created_at)
    end
  end
end
