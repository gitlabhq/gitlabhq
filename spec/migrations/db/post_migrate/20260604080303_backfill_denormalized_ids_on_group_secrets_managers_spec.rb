# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillDenormalizedIdsOnGroupSecretsManagers, feature_category: :secrets_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:group_secrets_managers) { table(:group_secrets_managers) }

  let!(:organization) { organizations.create!(name: 'test', path: 'test') }

  let!(:root_group) do
    namespaces.create!(name: 'root', path: 'root', type: 'Group', organization_id: organization.id, traversal_ids: [])
      .tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  let!(:subgroup) do
    namespaces.create!(
      name: 'sub', path: 'sub', type: 'Group',
      parent_id: root_group.id, organization_id: organization.id, traversal_ids: []
    ).tap { |ns| ns.update!(traversal_ids: [root_group.id, ns.id]) }
  end

  describe '#up' do
    it 'backfills denormalized ids on a live root group SM from its namespace' do
      sm = group_secrets_managers.create!(
        group_id: root_group.id,
        group_path: "group_#{root_group.id}",
        root_namespace_path: "org_#{organization.id}/group_#{root_group.id}"
      )

      expect { migrate! }
        .to change { sm.reload.organization_id }.from(nil).to(organization.id)
        .and change { sm.root_namespace_id }.from(nil).to(root_group.id)
    end

    it 'backfills denormalized ids on a live subgroup SM using the root ancestor' do
      sm = group_secrets_managers.create!(
        group_id: subgroup.id,
        group_path: "group_#{subgroup.id}",
        root_namespace_path: "org_#{organization.id}/group_#{root_group.id}"
      )

      expect { migrate! }
        .to change { sm.reload.organization_id }.from(nil).to(organization.id)
        .and change { sm.root_namespace_id }.from(nil).to(root_group.id)
    end

    it 'backfills denormalized ids on an orphan SM by parsing the cached root_namespace_path' do
      orphan_sm = group_secrets_managers.create!(
        group_id: nil,
        group_path: 'group_999',
        root_namespace_path: "org_#{organization.id}/group_#{root_group.id}"
      )

      expect { migrate! }
        .to change { orphan_sm.reload.organization_id }.from(nil).to(organization.id)
        .and change { orphan_sm.root_namespace_id }.from(nil).to(root_group.id)
    end

    it 'leaves already-populated SMs untouched' do
      already_set_sm = group_secrets_managers.create!(
        group_id: root_group.id,
        organization_id: 12_345,
        root_namespace_id: 67_890,
        group_path: "group_#{root_group.id}",
        root_namespace_path: "org_#{organization.id}/group_#{root_group.id}"
      )

      expect { migrate! }
        .to not_change { already_set_sm.reload.organization_id }
        .and not_change { already_set_sm.root_namespace_id }
    end
  end
end
