# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixAddOnNameInconsistencyUnderSubscriptionUserAddOnAssignmentVersions, feature_category: :seat_cost_management do
  let!(:versions) { table(:subscription_user_add_on_assignment_versions) }
  let!(:namespaces) { table(:namespaces) }
  let!(:users) { table(:users) }
  let!(:add_on_purchases) { table(:subscription_add_on_purchases) }
  let!(:add_ons) { table(:subscription_add_ons) }
  let!(:organizations) { table(:organizations) }

  let!(:organization) { organizations.create!(name: 'test-org', path: 'test-org') }
  let!(:namespace) { namespaces.create!(name: 'test', path: 'test', type: 'Group', organization_id: organization.id) }
  let!(:user) { users.create!(email: 'test@example.com', projects_limit: 10, organization_id: organization.id) }
  let!(:add_on) { add_ons.create!(name: 1, description: 'code suggestions') }
  let!(:add_on_purchase) do
    add_on_purchases.create!(
      subscription_add_on_id: add_on.id,
      namespace_id: namespace.id,
      organization_id: organization.id,
      quantity: 10,
      expires_on: 1.year.from_now,
      purchase_xid: 'A-123',
      started_at: Time.current
    )
  end

  let(:numeric_to_string_mapping) do
    {
      '1' => 'code_suggestions',
      '2' => 'product_analytics',
      '3' => 'duo_enterprise',
      '4' => 'duo_amazon_q',
      '5' => 'duo_core',
      '6' => 'duo_self_hosted'
    }
  end

  def create_version(add_on_name:)
    versions.create!(
      purchase_id: add_on_purchase.id,
      namespace_path: "#{organization.id}/",
      user_id: user.id,
      organization_id: organization.id,
      item_type: 'GitlabSubscriptions::UserAddOnAssignment',
      event: 'create',
      add_on_name: add_on_name
    )
  end

  describe '#up' do
    it 'converts numeric add_on_name values to their string equivalents' do
      created_versions = numeric_to_string_mapping.keys.map do |numeric_name|
        create_version(add_on_name: numeric_name)
      end

      string_version = create_version(add_on_name: 'code_suggestions')

      migrate!

      numeric_to_string_mapping.each_with_index do |(_numeric_name, expected_string), index|
        expect(created_versions[index].reload.add_on_name).to eq(expected_string)
      end

      expect(string_version.reload.add_on_name).to eq('code_suggestions')
    end

    it 'does not modify records with non-numeric add_on_name values' do
      version = create_version(add_on_name: 'custom_value')

      migrate!

      expect(version.reload.add_on_name).to eq('custom_value')
    end

    it 'handles empty table gracefully' do
      expect { migrate! }.not_to raise_error
    end
  end

  describe '#down' do
    it 'is a no-op' do
      version = create_version(add_on_name: 'code_suggestions')

      migrate!
      schema_migrate_down!

      expect(version.reload.add_on_name).to eq('code_suggestions')
    end
  end
end
