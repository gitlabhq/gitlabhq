# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillServiceAccountIdOnDuoWorkflowsWorkflows, feature_category: :duo_agent_platform do
  let(:duo_workflows_workflows) { table(:duo_workflows_workflows) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_versions) { table(:ai_catalog_item_versions) }
  let(:ai_catalog_item_consumers) { table(:ai_catalog_item_consumers) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }

  let!(:organization) { organizations.create!(name: 'Organization', path: 'organization') }

  let!(:user) do
    users.create!(
      email: 'user@example.com',
      username: 'test_user',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:service_account1) do
    users.create!(
      email: 'sa1@example.com',
      username: 'service_account_1',
      projects_limit: 0,
      user_type: 6,
      organization_id: organization.id
    )
  end

  let!(:service_account2) do
    users.create!(
      email: 'sa2@example.com',
      username: 'service_account_2',
      projects_limit: 0,
      user_type: 6,
      organization_id: organization.id
    )
  end

  let!(:root_namespace) do
    ns = namespaces.create!(
      name: 'root-group',
      path: 'root-group',
      type: 'Group',
      organization_id: organization.id
    )
    ns.update!(traversal_ids: [ns.id])
    ns
  end

  let!(:project_namespace) do
    ns = namespaces.create!(
      name: 'test-project',
      path: 'test-project',
      type: 'Project',
      parent_id: root_namespace.id,
      organization_id: organization.id
    )
    ns.update!(traversal_ids: [root_namespace.id, ns.id])
    ns
  end

  let!(:project) do
    projects.create!(
      namespace_id: root_namespace.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:catalog_item) do
    ai_catalog_items.create!(
      name: 'Test Flow',
      description: 'Builds test features',
      organization_id: organization.id,
      item_type: 2,
      public: true,
      foundational_flow_reference: 'software_development'
    )
  end

  let!(:item_version) do
    version = ai_catalog_item_versions.create!(
      ai_catalog_item_id: catalog_item.id,
      version: '1.0.0',
      organization_id: organization.id,
      schema_version: 1,
      definition: '{"steps": [{"agent_id": 1}]}'
    )
    catalog_item.update!(latest_version_id: version.id)
    version
  end

  let!(:root_group_consumer) do
    ai_catalog_item_consumers.create!(
      ai_catalog_item_id: catalog_item.id,
      group_id: root_namespace.id,
      service_account_id: service_account1.id,
      enabled: true,
      locked: false
    )
  end

  let(:start_id) { duo_workflows_workflows.minimum(:id) }
  let(:end_id) { duo_workflows_workflows.maximum(:id) }

  subject(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :duo_workflows_workflows,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  describe '#perform' do
    context 'when workflow has no ai_catalog_item_version_id but foundational_flow_reference matches' do
      let!(:workflow_without_version) do
        duo_workflows_workflows.create!(
          namespace_id: root_namespace.id,
          user_id: user.id,
          workflow_definition: 'software_development',
          service_account_id: nil
        )
      end

      it 'backfills service_account_id via foundational_flow_reference fallback' do
        migration.perform

        expect(workflow_without_version.reload.service_account_id).to eq(service_account1.id)
      end
    end

    context 'when workflow has no ai_catalog_item_version_id and no foundational_flow_reference match' do
      let!(:workflow_without_version) do
        duo_workflows_workflows.create!(
          namespace_id: root_namespace.id,
          user_id: user.id,
          workflow_definition: 'unknown_definition',
          service_account_id: nil
        )
      end

      it 'does not backfill service_account_id' do
        migration.perform

        expect(workflow_without_version.reload.service_account_id).to be_nil
      end
    end

    context 'when workflow already has a service_account_id' do
      let!(:workflow_with_sa) do
        duo_workflows_workflows.create!(
          namespace_id: root_namespace.id,
          user_id: user.id,
          workflow_definition: 'software_development',
          ai_catalog_item_version_id: item_version.id,
          service_account_id: service_account2.id
        )
      end

      it 'does not overwrite the existing service_account_id' do
        migration.perform

        expect(workflow_with_sa.reload.service_account_id).to eq(service_account2.id)
      end
    end

    context 'when workflow is namespace-level (no project_id)' do
      let!(:namespace_workflow) do
        duo_workflows_workflows.create!(
          namespace_id: root_namespace.id,
          user_id: user.id,
          workflow_definition: 'software_development',
          ai_catalog_item_version_id: item_version.id,
          service_account_id: nil
        )
      end

      it 'backfills service_account_id from the root group consumer' do
        migration.perform

        expect(namespace_workflow.reload.service_account_id).to eq(service_account1.id)
      end
    end

    context 'when workflow is namespace-level in a subgroup' do
      let!(:subgroup_namespace) do
        ns = namespaces.create!(
          name: 'subgroup',
          path: 'subgroup',
          type: 'Group',
          parent_id: root_namespace.id,
          organization_id: organization.id
        )
        ns.update!(traversal_ids: [root_namespace.id, ns.id])
        ns
      end

      let!(:subgroup_workflow) do
        duo_workflows_workflows.create!(
          namespace_id: subgroup_namespace.id,
          user_id: user.id,
          workflow_definition: 'software_development',
          ai_catalog_item_version_id: item_version.id,
          service_account_id: nil
        )
      end

      it 'resolves to the root group consumer via traversal_ids' do
        migration.perform

        expect(subgroup_workflow.reload.service_account_id).to eq(service_account1.id)
      end
    end

    context 'when workflow is project-level' do
      let!(:project_workflow) do
        duo_workflows_workflows.create!(
          project_id: project.id,
          user_id: user.id,
          workflow_definition: 'software_development',
          ai_catalog_item_version_id: item_version.id,
          service_account_id: nil
        )
      end

      it 'backfills service_account_id from the root group consumer' do
        migration.perform

        expect(project_workflow.reload.service_account_id).to eq(service_account1.id)
      end
    end

    context 'when root group consumer has no service_account_id' do
      before do
        root_group_consumer.update!(service_account_id: nil)
      end

      let!(:namespace_workflow) do
        duo_workflows_workflows.create!(
          namespace_id: root_namespace.id,
          user_id: user.id,
          workflow_definition: 'software_development',
          ai_catalog_item_version_id: item_version.id,
          service_account_id: nil
        )
      end

      it 'leaves service_account_id as nil' do
        migration.perform

        expect(namespace_workflow.reload.service_account_id).to be_nil
      end
    end

    context 'when no matching consumer exists' do
      let!(:other_item) do
        ai_catalog_items.create!(
          name: 'Other Item',
          description: 'No consumers',
          organization_id: organization.id,
          item_type: 2,
          public: true
        )
      end

      let!(:other_version) do
        version = ai_catalog_item_versions.create!(
          ai_catalog_item_id: other_item.id,
          version: '1.0.0',
          organization_id: organization.id,
          schema_version: 1,
          definition: '{"steps": [{"agent_id": 1}]}'
        )
        other_item.update!(latest_version_id: version.id)
        version
      end

      let!(:orphan_workflow) do
        duo_workflows_workflows.create!(
          namespace_id: root_namespace.id,
          user_id: user.id,
          workflow_definition: 'software_development',
          ai_catalog_item_version_id: other_version.id,
          service_account_id: nil
        )
      end

      it 'leaves service_account_id as nil' do
        migration.perform

        expect(orphan_workflow.reload.service_account_id).to be_nil
      end
    end

    it 'does not modify other columns' do
      workflow = duo_workflows_workflows.create!(
        namespace_id: root_namespace.id,
        user_id: user.id,
        workflow_definition: 'software_development',
        ai_catalog_item_version_id: item_version.id,
        service_account_id: nil
      )

      original_workflow_definition = workflow.workflow_definition
      original_namespace_id = workflow.namespace_id

      migration.perform

      workflow.reload
      expect(workflow.workflow_definition).to eq(original_workflow_definition)
      expect(workflow.namespace_id).to eq(original_namespace_id)
    end
  end
end
