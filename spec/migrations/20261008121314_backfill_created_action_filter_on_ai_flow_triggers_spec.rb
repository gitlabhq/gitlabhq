# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillCreatedActionFilterOnAiFlowTriggers,
  migration: :gitlab_main_org,
  feature_category: :duo_agent_platform do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_consumers) { table(:ai_catalog_item_consumers) }
  let(:ai_flow_triggers) { table(:ai_flow_triggers) }

  let(:mention) { 0 }
  let(:merge_request) { 6 }
  let(:flow_type) { 2 }

  let(:created_rule) { { 'field' => 'action', 'operator' => 'in', 'value' => ['created'] } }
  let(:approved_rule) { { 'field' => 'action', 'operator' => 'eq', 'value' => 'approved' } }
  let(:created_filter) { { 'merge_request' => { 'rules' => [created_rule] } } }

  let!(:organization) { organizations.create!(name: 'Organization 1', path: 'organization-1') }
  let!(:namespace) do
    namespaces.create!(name: 'namespace', path: 'namespace', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(name: 'project', path: 'project', namespace_id: namespace.id,
      project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let!(:risk_classification_consumer) { create_consumer('risk_classification/v1') }
  let!(:recommend_reviewers_consumer) { create_consumer('recommend_reviewers/v1') }
  let!(:code_review_consumer) { create_consumer('code_review/v2') }

  def create_consumer(reference)
    item = ai_catalog_items.create!(
      name: reference,
      description: 'A foundational flow',
      visibility: 2,
      organization_id: organization.id,
      item_type: flow_type,
      foundational_flow_reference: reference
    )

    ai_catalog_item_consumers.create!(ai_catalog_item_id: item.id, project_id: project.id)
  end

  def create_trigger(consumer, event_types: [merge_request], filter: {})
    ai_flow_triggers.create!(
      project_id: project.id,
      description: 'A trigger',
      ai_catalog_item_consumer_id: consumer.id,
      event_types: event_types,
      filter: filter
    )
  end

  describe '#up' do
    it 'adds the created filter to triggers of both flows with an empty filter', :aggregate_failures do
      risk_classification_trigger = create_trigger(risk_classification_consumer)
      recommend_reviewers_trigger = create_trigger(recommend_reviewers_consumer)

      migrate!

      expect(risk_classification_trigger.reload.filter).to eq(created_filter)
      expect(recommend_reviewers_trigger.reload.filter).to eq(created_filter)
    end

    it 'updates triggers in every batch, for any consumer of the flows' do
      stub_const("#{described_class}::BATCH_SIZE", 1)

      triggers = [
        create_trigger(risk_classification_consumer),
        create_trigger(code_review_consumer),
        create_trigger(recommend_reviewers_consumer),
        create_trigger(create_consumer('risk_classification/v1'))
      ]

      migrate!

      expect(triggers.map { |trigger| trigger.reload.filter })
        .to eq([created_filter, {}, created_filter, created_filter])
    end

    it 'adds the created filter next to filters for other event types' do
      mention_filter = { 'rules' => [{ 'field' => 'note', 'operator' => 'contains', 'value' => 'hi' }] }
      trigger = create_trigger(risk_classification_consumer,
        event_types: [mention, merge_request], filter: { 'mention' => mention_filter })

      migrate!

      expect(trigger.reload.filter).to eq(created_filter.merge('mention' => mention_filter))
    end

    it 'leaves a merge_request filter that the customer set unchanged' do
      filter = { 'merge_request' => { 'rules' => [approved_rule] } }
      trigger = create_trigger(risk_classification_consumer, filter: filter)

      expect { migrate! }.not_to change { trigger.reload.filter }.from(filter)
    end

    it 'leaves triggers without the merge_request event unchanged' do
      trigger = create_trigger(risk_classification_consumer, event_types: [mention])

      expect { migrate! }.not_to change { trigger.reload.filter }.from({})
    end

    it 'leaves triggers of other flows unchanged' do
      trigger = create_trigger(code_review_consumer)

      expect { migrate! }.not_to change { trigger.reload.filter }.from({})
    end

    it 'is idempotent' do
      trigger = create_trigger(risk_classification_consumer)

      migrate!
      schema_migrate_down!
      migrate!

      expect(trigger.reload.filter).to eq(created_filter)
    end
  end
end
