# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveMergeRequestEventFromDeveloperAiFlowTriggers,
  migration: :gitlab_main_org,
  feature_category: :duo_agent_platform do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_consumers) { table(:ai_catalog_item_consumers) }
  let(:ai_flow_triggers) { table(:ai_flow_triggers) }

  let(:mention) { 0 }
  let(:assign) { 1 }
  let(:merge_request) { 6 }
  let(:flow_type) { 2 }

  let!(:organization) { organizations.create!(name: 'Organization 1', path: 'organization-1') }
  let!(:namespace) do
    namespaces.create!(name: 'namespace', path: 'namespace', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(name: 'project', path: 'project', namespace_id: namespace.id,
      project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let!(:user) do
    users.create!(email: 'test@gitlab.com', username: 'test', projects_limit: 10,
      organization_id: organization.id, user_type: 3)
  end

  let!(:developer_item) do
    ai_catalog_items.create!(
      name: 'Developer',
      description: 'Turn feedback into actionable merge requests or issues.',
      visibility: 2,
      organization_id: organization.id,
      item_type: flow_type,
      foundational_flow_reference: 'developer/v1'
    )
  end

  let!(:other_item) do
    ai_catalog_items.create!(
      name: 'Code Review',
      description: 'Reviews code.',
      visibility: 2,
      organization_id: organization.id,
      item_type: flow_type,
      foundational_flow_reference: 'code_review/v2'
    )
  end

  let!(:developer_consumer) do
    ai_catalog_item_consumers.create!(ai_catalog_item_id: developer_item.id, project_id: project.id)
  end

  let!(:other_consumer) do
    ai_catalog_item_consumers.create!(ai_catalog_item_id: other_item.id, project_id: project.id)
  end

  def create_trigger(**attributes)
    ai_flow_triggers.create!({ project_id: project.id, description: 'A trigger' }.merge(attributes))
  end

  describe '#up' do
    context 'when the auto-created Developer trigger holds assign, mention and merge_request events' do
      let!(:trigger) do
        create_trigger(
          ai_catalog_item_consumer_id: developer_consumer.id,
          description: 'Foundational flow trigger for Developer',
          event_types: [assign, mention, merge_request]
        )
      end

      it 'removes only the merge_request event' do
        migrate!

        expect(trigger.reload.event_types).to contain_exactly(assign, mention)
      end
    end

    context 'when the auto-created Developer trigger only holds the merge_request event' do
      let!(:trigger) do
        create_trigger(
          ai_catalog_item_consumer_id: developer_consumer.id,
          description: 'Foundational flow trigger for Developer',
          event_types: [merge_request]
        )
      end

      it 'deletes the trigger' do
        expect { migrate! }.to change { ai_flow_triggers.where(id: trigger.id).count }.from(1).to(0)
      end
    end

    context 'when the ItemConsumers::CreateService trigger holds assign, mention and merge_request events' do
      let!(:trigger) do
        create_trigger(
          ai_catalog_item_consumer_id: developer_consumer.id,
          description: 'Auto-created triggers for Developer',
          event_types: [assign, mention, merge_request]
        )
      end

      it 'removes only the merge_request event' do
        migrate!

        expect(trigger.reload.event_types).to contain_exactly(assign, mention)
      end
    end

    context 'when the ItemConsumers::CreateService trigger only holds the merge_request event' do
      let!(:trigger) do
        create_trigger(
          ai_catalog_item_consumer_id: developer_consumer.id,
          description: 'Auto-created triggers for Developer',
          event_types: [merge_request]
        )
      end

      it 'deletes the trigger' do
        expect { migrate! }.to change { ai_flow_triggers.where(id: trigger.id).count }.from(1).to(0)
      end
    end

    context 'when the auto-created Developer trigger has no merge_request event' do
      let!(:trigger) do
        create_trigger(
          ai_catalog_item_consumer_id: developer_consumer.id,
          description: 'Foundational flow trigger for Developer',
          event_types: [assign, mention]
        )
      end

      it 'leaves it unchanged' do
        migrate!

        expect(trigger.reload.event_types).to contain_exactly(assign, mention)
      end
    end

    context 'when the Developer trigger has a user-provided description' do
      let!(:trigger) do
        create_trigger(
          ai_catalog_item_consumer_id: developer_consumer.id,
          description: 'Run my flow on every MR event',
          event_types: [merge_request]
        )
      end

      it 'leaves it unchanged' do
        migrate!

        expect(trigger.reload.event_types).to contain_exactly(merge_request)
      end
    end

    context 'when the auto-created Developer trigger was customized with a filter' do
      let(:merged_filter) do
        { 'merge_request' => { 'rules' => [{ 'field' => 'action', 'operator' => 'in', 'value' => ['merged'] }] } }
      end

      let!(:trigger) do
        create_trigger(
          ai_catalog_item_consumer_id: developer_consumer.id,
          description: 'Foundational flow trigger for Developer',
          event_types: [merge_request],
          filter: merged_filter
        )
      end

      it 'leaves it unchanged' do
        migrate!

        expect(trigger.reload.event_types).to contain_exactly(merge_request)
      end
    end

    context 'when another flow auto-created trigger holds a merge_request event' do
      let!(:trigger) do
        create_trigger(
          ai_catalog_item_consumer_id: other_consumer.id,
          description: 'Foundational flow trigger for Code Review',
          event_types: [merge_request]
        )
      end

      it 'leaves it unchanged' do
        migrate!

        expect(trigger.reload.event_types).to contain_exactly(merge_request)
      end
    end

    context 'when a standalone trigger without a consumer holds a merge_request event' do
      let!(:trigger) do
        create_trigger(
          user_id: user.id,
          config_path: '.gitlab/ai/test.yml',
          event_types: [merge_request]
        )
      end

      it 'leaves it unchanged' do
        migrate!

        expect(trigger.reload.event_types).to contain_exactly(merge_request)
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { described_class.new.down }.not_to raise_error
    end
  end
end
