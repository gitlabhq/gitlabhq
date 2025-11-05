# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveAiCatalogFlowRecords, migration: :gitlab_main, feature_category: :workflow_catalog do
  let(:organizations) { table(:organizations) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_versions) { table(:ai_catalog_item_versions) }
  let(:ai_catalog_item_consumers) { table(:ai_catalog_item_consumers) }
  let(:ai_catalog_item_version_dependencies) { table(:ai_catalog_item_version_dependencies) }
  let(:ai_flow_triggers) { table(:ai_flow_triggers) }
  let(:duo_workflows_workflows) { table(:duo_workflows_workflows) }

  let(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }
  let(:namespace) do
    namespaces.create!(name: 'Test Namespace', path: 'test-namespace', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:user) do
    users.create!(email: 'test@example.com', projects_limit: 10, username: 'testuser', organization_id: organization.id)
  end

  describe '#up' do
    let(:flow_type) { 2 } # FLOW_TYPE
    let(:agent_type) { 1 } # AGENT_TYPE
    let(:third_party_type) { 3 } # THIRD_PARTY_FLOW_TYPE

    let!(:test_data) do
      agent_item = ai_catalog_items.create!(
        name: 'Test Agent',
        description: 'A test agent item',
        public: true,
        project_id: project.id,
        organization_id: organization.id,
        item_type: agent_type
      )

      agent_version = ai_catalog_item_versions.create!(
        ai_catalog_item_id: agent_item.id,
        version: '1.0.0',
        organization_id: organization.id,
        schema_version: 1,
        release_date: Time.current,
        definition: { test: 'agent_data' }.to_json
      )

      agent_item.update!(
        latest_version_id: agent_version.id,
        latest_released_version_id: agent_version.id
      )

      agent_consumer = ai_catalog_item_consumers.create!(
        ai_catalog_item_id: agent_item.id,
        organization_id: organization.id,
        enabled: true,
        locked: false
      )

      agent_dependency = ai_catalog_item_version_dependencies.create!(
        ai_catalog_item_version_id: agent_version.id,
        dependency_id: agent_item.id,
        organization_id: organization.id
      )

      agent_workflow = duo_workflows_workflows.create!(
        ai_catalog_item_version_id: agent_version.id,
        project_id: project.id,
        user_id: user.id,
        goal: 'Test agent workflow'
      )

      # Third party flow with all data
      third_party_item = ai_catalog_items.create!(
        name: 'Third Party Item',
        description: 'A third party item',
        public: true,
        project_id: project.id,
        organization_id: organization.id,
        item_type: third_party_type
      )

      third_party_version = ai_catalog_item_versions.create!(
        ai_catalog_item_id: third_party_item.id,
        version: '1.0.0',
        organization_id: organization.id,
        schema_version: 1,
        release_date: Time.current,
        definition: { test: 'third_party_data' }.to_json
      )

      third_party_item.update!(
        latest_version_id: third_party_version.id,
        latest_released_version_id: third_party_version.id
      )

      third_party_consumer = ai_catalog_item_consumers.create!(
        ai_catalog_item_id: third_party_item.id,
        organization_id: organization.id,
        enabled: true,
        locked: false
      )

      third_party_dependency = ai_catalog_item_version_dependencies.create!(
        ai_catalog_item_version_id: third_party_version.id,
        dependency_id: third_party_item.id,
        organization_id: organization.id
      )

      third_party_workflow = duo_workflows_workflows.create!(
        ai_catalog_item_version_id: third_party_version.id,
        project_id: project.id,
        user_id: user.id,
        goal: 'Test third party workflow'
      )

      third_party_flow_trigger = ai_flow_triggers.create!(
        project_id: project.id,
        user_id: user.id,
        ai_catalog_item_consumer_id: third_party_consumer.id,
        description: 'Test trigger',
        event_types: [0]
      )

      # Flow with all data
      flow_item = ai_catalog_items.create!(
        name: 'Test Flow',
        description: 'A test flow item',
        public: true,
        project_id: project.id,
        organization_id: organization.id,
        item_type: flow_type
      )

      flow_version = ai_catalog_item_versions.create!(
        ai_catalog_item_id: flow_item.id,
        version: '1.0.0',
        organization_id: organization.id,
        schema_version: 1,
        release_date: Time.current,
        definition: { test: 'flow_data' }.to_json
      )

      flow_item.update!(
        latest_version_id: flow_version.id,
        latest_released_version_id: flow_version.id
      )

      flow_consumer = ai_catalog_item_consumers.create!(
        ai_catalog_item_id: flow_item.id,
        organization_id: organization.id,
        enabled: true,
        locked: false
      )

      flow_trigger = ai_flow_triggers.create!(
        project_id: project.id,
        user_id: user.id,
        ai_catalog_item_consumer_id: flow_consumer.id,
        description: 'Test trigger',
        event_types: [0]
      )

      flow_dependency = ai_catalog_item_version_dependencies.create!(
        ai_catalog_item_version_id: flow_version.id,
        dependency_id: flow_item.id,
        organization_id: organization.id
      )

      flow_workflow = duo_workflows_workflows.create!(
        ai_catalog_item_version_id: flow_version.id,
        project_id: project.id,
        user_id: user.id,
        goal: 'Test flow workflow'
      )

      {
        agent: {
          item: agent_item,
          version: agent_version,
          consumer: agent_consumer,
          dependency: agent_dependency,
          workflow: agent_workflow
        },
        third_party: {
          item: third_party_item,
          version: third_party_version,
          consumer: third_party_consumer,
          trigger: third_party_flow_trigger,
          dependency: third_party_dependency,
          workflow: third_party_workflow
        },
        flow: {
          item: flow_item,
          version: flow_version,
          consumer: flow_consumer,
          trigger: flow_trigger,
          dependency: flow_dependency,
          workflow: flow_workflow
        }
      }
    end

    it 'deletes only flow data and preserves agent and third party data', :aggregate_failures do
      migrate!

      # Flow records should be deleted
      expect(ai_catalog_items.exists?(test_data[:flow][:item].id)).to be false
      expect(ai_catalog_item_versions.exists?(test_data[:flow][:version].id)).to be false
      expect(ai_catalog_item_consumers.exists?(test_data[:flow][:consumer].id)).to be false
      expect(ai_flow_triggers.exists?(test_data[:flow][:trigger].id)).to be false
      expect(ai_catalog_item_version_dependencies.exists?(test_data[:flow][:dependency].id)).to be false
      expect(duo_workflows_workflows.exists?(test_data[:flow][:workflow].id)).to be false

      # Agent records should remain untouched
      expect(ai_catalog_items.exists?(test_data[:agent][:item].id)).to be true
      expect(ai_catalog_item_versions.exists?(test_data[:agent][:version].id)).to be true
      expect(ai_catalog_item_consumers.exists?(test_data[:agent][:consumer].id)).to be true
      expect(ai_catalog_item_version_dependencies.exists?(test_data[:agent][:dependency].id)).to be true
      expect(duo_workflows_workflows.exists?(test_data[:agent][:workflow].id)).to be true

      # Third party records should remain untouched
      expect(ai_catalog_items.exists?(test_data[:third_party][:item].id)).to be true
      expect(ai_catalog_item_versions.exists?(test_data[:third_party][:version].id)).to be true
      expect(ai_catalog_item_consumers.exists?(test_data[:third_party][:consumer].id)).to be true
      expect(ai_flow_triggers.exists?(test_data[:third_party][:trigger].id)).to be true
      expect(ai_catalog_item_version_dependencies.exists?(test_data[:third_party][:dependency].id)).to be true
      expect(duo_workflows_workflows.exists?(test_data[:third_party][:workflow].id)).to be true
    end

    context 'when migration is run multiple times' do
      it 'is idempotent and does not fail on subsequent runs' do
        migrate!

        first_run_state = {
          items: ai_catalog_items.pluck(:id).sort,
          versions: ai_catalog_item_versions.pluck(:id).sort,
          consumers: ai_catalog_item_consumers.pluck(:id).sort,
          triggers: ai_flow_triggers.pluck(:id).sort,
          dependencies: ai_catalog_item_version_dependencies.pluck(:id).sort,
          workflows: duo_workflows_workflows.pluck(:id).sort
        }

        migrate!

        second_run_state = {
          items: ai_catalog_items.pluck(:id).sort,
          versions: ai_catalog_item_versions.pluck(:id).sort,
          consumers: ai_catalog_item_consumers.pluck(:id).sort,
          triggers: ai_flow_triggers.pluck(:id).sort,
          dependencies: ai_catalog_item_version_dependencies.pluck(:id).sort,
          workflows: duo_workflows_workflows.pluck(:id).sort
        }

        expect(second_run_state).to eq(first_run_state)
      end
    end

    context 'when there are no records' do
      before do
        ai_flow_triggers.delete_all
        ai_catalog_item_version_dependencies.delete_all
        ai_catalog_item_consumers.delete_all
        ai_catalog_items.update_all(latest_version_id: nil, latest_released_version_id: nil)
        ai_catalog_item_versions.delete_all
        ai_catalog_items.delete_all
      end

      it 'does not fail' do
        expect { migrate! }.not_to raise_error
      end
    end

    context 'when deletion fails' do
      it 'rolls back all deletions in the transaction' do
        flows_relation = instance_double(ActiveRecord::Relation)
        allow(described_class::AiCatalogItem).to receive(:where).and_return(flows_relation)
        allow(flows_relation).to receive(:pluck).and_return([test_data[:flow][:item].id])
        allow(flows_relation).to receive(:delete_all).and_raise(StandardError, 'Deletion failed')

        expect { migrate! }.to raise_error(StandardError, /Deletion failed/)

        expect(ai_catalog_items.exists?(test_data[:flow][:item].id)).to be true
        expect(ai_catalog_item_consumers.exists?(test_data[:flow][:consumer].id)).to be true
        expect(duo_workflows_workflows.exists?(test_data[:flow][:workflow].id)).to be true
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { described_class.new.down }.not_to raise_error
    end
  end
end
