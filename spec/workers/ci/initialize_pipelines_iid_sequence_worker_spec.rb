# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::InitializePipelinesIidSequenceWorker, feature_category: :continuous_integration do
  let_it_be_with_refind(:project) { create(:project) }

  let(:project_created_event) do
    Projects::ProjectCreatedEvent.new(
      data: {
        project_id: project.id,
        namespace_id: project.namespace_id,
        root_namespace_id: project.root_namespace.id
      })
  end

  it_behaves_like 'subscribes to event' do
    let(:event) { project_created_event }
  end

  it 'creates an internal_ids sequence for ci_pipelines' do
    consume_event(subscriber: described_class, event: project_created_event)

    expect(project.internal_ids.ci_pipelines).to be_any
    expect(project.internal_ids.ci_pipelines).to all be_persisted
  end

  context 'when the internal_ids sequence is already initialized' do
    before do
      create_list(:ci_pipeline, 2, project: project)
    end

    it 'does not reset the sequence' do
      expect { consume_event(subscriber: described_class, event: project_created_event) }
        .not_to change { project.internal_ids.ci_pipelines.pluck(:last_value) }
    end
  end
end
