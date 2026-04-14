# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillRootNamespacePathOnGroupSecretsManagers, feature_category: :secrets_management do
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
    it 'backfills root_namespace_path correctly' do
      root_group_sm = group_secrets_managers.create!(
        group_id: root_group.id, group_path: "group_#{root_group.id}", root_namespace_path: nil
      )
      subgroup_sm = group_secrets_managers.create!(
        group_id: subgroup.id, group_path: "group_#{subgroup.id}", root_namespace_path: nil
      )
      already_set_sm = group_secrets_managers.create!(
        group_id: root_group.id, group_path: "group_#{root_group.id}",
        root_namespace_path: "group_#{root_group.id}"
      )
      orphaned_sm = group_secrets_managers.create!(
        group_id: nil, group_path: "group_999", root_namespace_path: nil
      )

      expect { migrate! }
        .to change { root_group_sm.reload.root_namespace_path }.from(nil).to("group_#{root_group.id}")
        .and change { subgroup_sm.reload.root_namespace_path }.from(nil).to("group_#{root_group.id}")
        .and not_change { already_set_sm.reload.root_namespace_path }
        .and not_change { orphaned_sm.reload.root_namespace_path }
    end
  end
end
