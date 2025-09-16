# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesignManagementRepositoriesProjectNamespaceId, feature_category: :team_planning do
  let(:connection) { ApplicationRecord.connection }

  let(:migration) do
    described_class.new(
      pause_ms: 0,
      connection: connection,
      batch_table: :design_management_repositories,
      batch_column: :id,
      sub_batch_size: 50
    )
  end

  shared_context 'with design_management_repositories records' do
    let(:projects) { table(:projects) }
    let(:namespaces) { table(:namespaces) }

    let(:design_management_repositories) { table(:design_management_repositories) }

    let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

    let!(:group_namespace1) do
      namespaces.create!(name: 'gn1', organization_id: organization.id, path: 'gn1', type: 'Group')
    end

    let!(:group_namespace2) do
      namespaces.create!(name: 'gn2', organization_id: organization.id, path: 'gn2', type: 'Group')
    end

    let!(:project_namespace1) do
      namespaces.create!(name: 'pn1', organization_id: organization.id, path: 'pn1', type: 'Project')
    end

    let!(:project_namespace2) do
      namespaces.create!(name: 'pn2', organization_id: organization.id, path: 'pn2', type: 'Project')
    end

    let!(:project1) do
      projects.create!(namespace_id: group_namespace1.id,
        project_namespace_id: project_namespace1.id,
        organization_id: organization.id)
    end

    let!(:project2) do
      projects.create!(namespace_id: group_namespace2.id,
        project_namespace_id: project_namespace2.id,
        organization_id: organization.id)
    end

    # Mimic's the existing incorrectly set namespace_id
    let!(:design_management_repository1) do
      design_management_repositories.create!(project_id: project1.id, namespace_id: project1.namespace_id)
    end

    let!(:design_management_repository2) do
      design_management_repositories.create!(project_id: project2.id, namespace_id: project2.namespace_id)
    end
  end

  shared_context 'with design_management_repository_states records' do
    let(:design_management_repository_states) { table(:design_management_repository_states) }

    # Mimic's the existing incorrectly set namespace_id
    let!(:design_management_repository_state1) do
      design_management_repository_states.create!(design_management_repository_id: design_management_repository1.id,
        namespace_id: project1.namespace_id)
    end

    let!(:design_management_repository_state2) do
      design_management_repository_states.create!(design_management_repository_id: design_management_repository2.id,
        namespace_id: project2.namespace_id)
    end
  end

  describe '#perform' do
    context 'for design_management_repositories' do
      include_context 'with design_management_repositories records'

      it 'backfills namespace_id on the design_management_repositories table with the project_namespace_id' do
        expect do
          migration.perform
        end.to change { design_management_repository1.reload.namespace_id }
             .from(project1.namespace_id).to(project1.project_namespace_id)
           .and change { design_management_repository2.reload.namespace_id }
             .from(project2.namespace_id).to(project2.project_namespace_id)
      end
    end

    context 'for design_management_repository_states' do
      include_context 'with design_management_repositories records'
      include_context 'with design_management_repository_states records'

      it 'backfills namespace_id on the design_management_repository_states table with the project_namespace_id' do
        expect do
          migration.perform
        end.to change { design_management_repository_state1.reload.namespace_id }
             .from(project1.namespace_id).to(project1.project_namespace_id)
           .and change { design_management_repository_state2.reload.namespace_id }
             .from(project2.namespace_id).to(project2.project_namespace_id)
      end
    end
  end
end
