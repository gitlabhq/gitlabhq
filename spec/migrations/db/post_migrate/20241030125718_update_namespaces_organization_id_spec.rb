# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateNamespacesOrganizationId, migration: :gitlab_main, feature_category: :cell do
  let(:namespaces) { table(:namespaces) }

  let!(:group_with_organization) { namespaces.create!(name: 'my_org', path: 'my-org-1', organization_id: 10) }
  let!(:group_with_default_organization) { namespaces.create!(name: 'my_org', path: 'my-org-2') }
  let!(:group_without_organization) { namespaces.create!(name: 'my_org', path: 'my-org-3', organization_id: nil) }

  describe '#up' do
    it 'updates organization_id' do
      migrate!

      expect(group_with_organization.reload.organization_id).to eq(10)
      expect(group_with_default_organization.reload.organization_id).to eq(1)
      expect(group_without_organization.reload.organization_id).to eq(1)
    end
  end
end
