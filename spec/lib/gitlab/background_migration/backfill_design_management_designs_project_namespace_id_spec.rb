# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesignManagementDesignsProjectNamespaceId, feature_category: :team_planning do
  let(:connection) { ApplicationRecord.connection }

  let(:migration) do
    described_class.new(
      pause_ms: 0,
      connection: connection,
      batch_table: :design_management_designs,
      batch_column: :id,
      sub_batch_size: 50
    )
  end

  shared_context 'with design_management_designs records' do
    let(:projects) { table(:projects) }
    let(:namespaces) { table(:namespaces) }
    let(:design_user_mentions) { table(:design_user_mentions) }
    let(:design_management_designs) { table(:design_management_designs) }
    let(:design_management_designs_versions) { table(:design_management_designs_versions) }

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
    let!(:design_management_design1) do
      design_management_designs.create!(project_id: project1.id,
        namespace_id: project1.namespace_id,
        filename: 'abc.txt',
        iid: 1)
    end

    let!(:design_management_design2) do
      design_management_designs.create!(project_id: project1.id,
        namespace_id: project1.namespace_id,
        filename: 'abc.txt',
        iid: 2)
    end

    let!(:design_management_design3) do
      design_management_designs.create!(project_id: project2.id,
        namespace_id: project2.namespace_id,
        filename: 'abc.txt',
        iid: 3)
    end
  end

  shared_context 'with design_management_designs_versions records' do
    let(:design_management_versions) { table(:design_management_versions) }

    let!(:design_management_version1) do
      design_management_versions.create!(namespace_id: group_namespace1.id, sha: '57b6')
    end

    let!(:design_management_version2) do
      design_management_versions.create!(namespace_id: group_namespace1.id, sha: '5cab')
    end

    let!(:design_management_version3) do
      design_management_versions.create!(namespace_id: group_namespace1.id, sha: '7bf6')
    end

    # Mimic's the existing incorrectly set namespace_id
    let!(:design_management_designs_version1) do
      design_management_designs_versions.create!(design_id: design_management_design1.id,
        namespace_id: project1.namespace_id,
        version_id: design_management_version1.id)
    end

    let!(:design_management_designs_version2) do
      design_management_designs_versions.create!(design_id: design_management_design1.id,
        namespace_id: project1.namespace_id,
        version_id: design_management_version2.id)
    end

    let!(:design_management_designs_version3) do
      design_management_designs_versions.create!(design_id: design_management_design3.id,
        namespace_id: project2.namespace_id,
        version_id: design_management_version3.id)
    end
  end

  shared_context 'with design_user_mentions records' do
    let(:notes) { table(:notes) }

    let(:note1) { table(:notes).create!(noteable_type: 'Issue', project_id: project1.id) }
    let(:note2) { table(:notes).create!(noteable_type: 'Issue', project_id: project1.id) }
    let(:note3) { table(:notes).create!(noteable_type: 'Issue', project_id: project1.id) }

    # Mimic's the existing incorrectly set namespace_id
    let!(:design_user_mention1) do
      design_user_mentions.create!(design_id: design_management_design1.id,
        namespace_id: project1.namespace_id,
        note_id: note1.id)
    end

    let!(:design_user_mention2) do
      design_user_mentions.create!(design_id: design_management_design1.id,
        namespace_id: project1.namespace_id,
        note_id: note2.id)
    end

    let!(:design_user_mention3) do
      design_user_mentions.create!(design_id: design_management_design3.id,
        namespace_id: project2.namespace_id,
        note_id: note3.id)
    end
  end

  describe '#perform' do
    context 'for design_management_designs' do
      include_context 'with design_management_designs records'

      it 'backfills namespace_id on the design_management_designs table with the project_namespace_id' do
        expect do
          migration.perform
        end.to change { design_management_design1.reload.namespace_id }
             .from(project1.namespace_id).to(project1.project_namespace_id)
           .and change { design_management_design2.reload.namespace_id }
             .from(project1.namespace_id).to(project1.project_namespace_id)
           .and change { design_management_design3.reload.namespace_id }
             .from(project2.namespace_id).to(project2.project_namespace_id)
      end
    end

    context 'for design_management_designs_versions' do
      include_context 'with design_management_designs records'
      include_context 'with design_management_designs_versions records'

      it 'backfills namespace_id on the design_management_designs_versions table with the project_namespace_id' do
        expect do
          migration.perform
        end.to change { design_management_designs_version1.reload.namespace_id }
             .from(project1.namespace_id).to(project1.project_namespace_id)
           .and change { design_management_designs_version2.reload.namespace_id }
             .from(project1.namespace_id).to(project1.project_namespace_id)
           .and change { design_management_designs_version3.reload.namespace_id }
             .from(project2.namespace_id).to(project2.project_namespace_id)
      end
    end

    context 'for design_user_mentions' do
      include_context 'with design_management_designs records'
      include_context 'with design_user_mentions records'

      it 'backfills namespace_id on the design_user_mentions table with the project_namespace_id' do
        expect do
          migration.perform
        end.to change { design_user_mention1.reload.namespace_id }
             .from(project1.namespace_id).to(project1.project_namespace_id)
           .and change { design_user_mention2.reload.namespace_id }
             .from(project1.namespace_id).to(project1.project_namespace_id)
           .and change { design_user_mention3.reload.namespace_id }
             .from(project2.namespace_id).to(project2.project_namespace_id)
      end
    end
  end
end
