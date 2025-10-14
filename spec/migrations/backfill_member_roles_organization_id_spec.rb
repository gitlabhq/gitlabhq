# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillMemberRolesOrganizationId, feature_category: :permissions do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:member_roles) { table(:member_roles) }

  let(:organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let(:other_organization) { organizations.create!(id: 2, name: 'Other', path: 'other') }
  let(:namespace) { namespaces.create!(name: 'Group', path: 'group', organization_id: organization.id) }

  let(:role_without_organization) do
    member_roles.create!(
      id: 1,
      name: 'Member Role 1'
    )
  end

  let(:another_role_without_organization) do
    member_roles.create!(
      id: 2,
      name: 'Member Role 2'
    )
  end

  let(:role_with_organization) do
    member_roles.create!(
      id: 3,
      name: 'Member Role 3',
      organization_id: other_organization.id
    )
  end

  let(:role_with_namespace) do
    member_roles.create!(
      id: 4,
      name: 'Member Role 4',
      namespace_id: namespace.id
    )
  end

  describe "#up" do
    it 'sets organization_id sharding key for records that do not have it' do
      expect(role_without_organization.organization_id).to be_nil
      expect(another_role_without_organization.organization_id).to be_nil
      expect(role_with_organization.organization_id).to eq(other_organization.id)
      expect(role_with_namespace.organization_id).to be_nil
      expect(role_with_namespace.namespace_id).to eq(namespace.id)

      migrate!

      expect(role_without_organization.reload.organization_id).to eq(organization.id)
      expect(another_role_without_organization.reload.organization_id).to eq(organization.id)
      expect(role_with_organization.reload.organization_id).to eq(other_organization.id)
      expect(role_with_namespace.reload.organization_id).to be_nil
      expect(role_with_namespace.reload.namespace_id).to eq(namespace.id)
    end
  end
end
