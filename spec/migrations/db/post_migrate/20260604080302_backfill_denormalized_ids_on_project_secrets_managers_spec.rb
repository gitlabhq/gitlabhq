# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillDenormalizedIdsOnProjectSecretsManagers, feature_category: :secrets_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_secrets_managers) { table(:project_secrets_managers) }

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

  let!(:project_namespace) do
    namespaces.create!(
      name: 'proj', path: 'proj', type: 'Project',
      parent_id: subgroup.id, organization_id: organization.id, traversal_ids: [root_group.id, subgroup.id]
    )
  end

  let!(:project) do
    projects.create!(
      name: 'proj', path: 'proj',
      namespace_id: subgroup.id, project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  describe '#up' do
    it 'backfills denormalized ids on a live SM from its project' do
      sm = project_secrets_managers.create!(
        project_id: project.id,
        namespace_path: "org_#{organization.id}/group_#{root_group.id}",
        project_path: "project_#{project.id}"
      )

      expect { migrate! }
        .to change { sm.reload.organization_id }.from(nil).to(organization.id)
        .and change { sm.root_namespace_id }.from(nil).to(root_group.id)
    end

    it 'backfills denormalized ids on an orphan SM by parsing the cached namespace_path' do
      orphan_sm = project_secrets_managers.create!(
        project_id: nil,
        namespace_path: "org_#{organization.id}/group_#{root_group.id}",
        project_path: "project_999"
      )

      expect { migrate! }
        .to change { orphan_sm.reload.organization_id }.from(nil).to(organization.id)
        .and change { orphan_sm.root_namespace_id }.from(nil).to(root_group.id)
    end

    it 'leaves already-populated SMs untouched' do
      already_set_sm = project_secrets_managers.create!(
        project_id: project.id,
        organization_id: 12_345,
        root_namespace_id: 67_890,
        namespace_path: "org_#{organization.id}/group_#{root_group.id}",
        project_path: "project_#{project.id}"
      )

      expect { migrate! }
        .to not_change { already_set_sm.reload.organization_id }
        .and not_change { already_set_sm.root_namespace_id }
    end
  end
end
