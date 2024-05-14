# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ExtendGitlabcomDuoProTrials, feature_category: :code_suggestions do
  let(:addon_purchases) { table(:subscription_add_on_purchases) }
  let(:addons) { table(:subscription_add_ons) }
  let(:namespaces) { table(:namespaces) }

  let!(:today) { Date.current }
  # GitlabSubscriptions::AddOn is an EE model. GitlabSubscriptions::AddOn.names is not available in FOSS.
  # So we hard-code the value `1` for GitlabSubscriptions::AddOn.names[:code_suggestions].
  let!(:duo_pro_addon) { addons.create!(name: 1, description: "code suggestions") }
  # Similarly as above, hard-code the value `2` for GitlabSubscriptions::AddOn.names[:product_analytics]
  let!(:product_analytics_addon) { addons.create!(name: 2, description: "product analytics") }

  let!(:group1) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group') }
  let!(:group2) { namespaces.create!(name: 'group2', path: 'group2', type: 'Group') }
  let!(:group3) { namespaces.create!(name: 'group3', path: 'group3', type: 'Group') }
  let!(:group4) { namespaces.create!(name: 'group4', path: 'group4', type: 'Group') }
  let!(:group5) { namespaces.create!(name: 'group5', path: 'group5', type: 'Group') }
  let!(:group6) { namespaces.create!(name: 'group6', path: 'group5', type: 'Group') }

  let!(:duo_pro_trial_expired) do
    addon_purchases.create!(
      subscription_add_on_id: duo_pro_addon.id,
      namespace_id: group1.id,
      quantity: 50,
      expires_on: today - 1.day,
      purchase_xid: "trial-order-1",
      last_assigned_users_refreshed_at: nil,
      trial: true
    )
  end

  let!(:duo_pro_trial_active_1) do
    addon_purchases.create!(
      subscription_add_on_id: duo_pro_addon.id,
      namespace_id: group2.id,
      quantity: 50,
      expires_on: today,
      purchase_xid: "trial-order-2",
      last_assigned_users_refreshed_at: nil,
      trial: true
    )
  end

  let!(:duo_pro_trial_active_2) do
    addon_purchases.create!(
      subscription_add_on_id: duo_pro_addon.id,
      namespace_id: group3.id,
      quantity: 50,
      expires_on: today + 1.day,
      purchase_xid: "trial-order-3",
      last_assigned_users_refreshed_at: nil,
      trial: true
    )
  end

  let!(:duo_pro_trial_active_3) do
    addon_purchases.create!(
      subscription_add_on_id: duo_pro_addon.id,
      namespace_id: group4.id,
      quantity: 50,
      expires_on: today + 30.days,
      purchase_xid: "trial-order-4",
      last_assigned_users_refreshed_at: nil,
      trial: true
    )
  end

  let!(:duo_pro_paid_active) do
    addon_purchases.create!(
      subscription_add_on_id: duo_pro_addon.id,
      namespace_id: group5.id,
      quantity: 20,
      expires_on: today + 1.day,
      purchase_xid: "A-S123456",
      last_assigned_users_refreshed_at: nil,
      trial: false
    )
  end

  let!(:product_analytics_addon_active) do
    addon_purchases.create!(
      subscription_add_on_id: product_analytics_addon.id,
      namespace_id: group6.id,
      quantity: 20,
      expires_on: today + 1.day,
      purchase_xid: "A-S123457",
      last_assigned_users_refreshed_at: nil,
      trial: false
    )
  end

  describe '#up' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    it 'update only the active duo_pro trials expires_on to 60.days after created date' do
      expect do
        migrate!
      end.to change { duo_pro_trial_active_1.reload.expires_on }.from(today).to(today + 60.days).and(
        change { duo_pro_trial_active_2.reload.expires_on }.from(today + 1.day).to(today + 60.days)
      ).and(
        change { duo_pro_trial_active_3.reload.expires_on }.from(today + 30.days).to(today + 60.days)
      ).and(
        not_change { duo_pro_trial_expired.reload.expires_on }
      ).and(
        not_change { duo_pro_paid_active.reload.expires_on }
      ).and(
        not_change { product_analytics_addon_active.reload.expires_on }
      )
    end
  end
end
