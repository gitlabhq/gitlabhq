# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipelines::HookService, feature_category: :continuous_integration do
  describe '#execute_hooks' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project, :repository, namespace: namespace) }
    let_it_be(:pipeline, reload: true) { create(:ci_empty_pipeline, :created, project: project) }

    let(:hook_enabled) { true }
    let!(:hook) { create(:project_hook, project: project, pipeline_events: hook_enabled) }
    let(:hook_data) { double }

    subject(:service) { described_class.new(pipeline) }

    describe 'HOOK_NAME' do
      specify { expect(described_class::HOOK_NAME).to eq(:pipeline_hooks) }
    end

    context 'with pipeline hooks enabled' do
      before do
        allow(Gitlab::DataBuilder::Pipeline).to receive(:build).with(pipeline).once.and_return(hook_data)
      end

      it 'calls pipeline.project.execute_hooks and pipeline.project.execute_integrations' do
        create(:pipelines_email_integration, project: project)

        expect(pipeline.project).to receive(:execute_hooks).with(hook_data, described_class::HOOK_NAME)
        expect(pipeline.project).to receive(:execute_integrations).with(hook_data, described_class::HOOK_NAME)

        service.execute
      end
    end

    context 'with pipeline hooks and integrations disabled' do
      let(:hook_enabled) { false }

      it 'does not call pipeline.project.execute_hooks and pipeline.project.execute_integrations' do
        expect(pipeline.project).not_to receive(:execute_hooks)
        expect(pipeline.project).not_to receive(:execute_integrations)

        service.execute
      end
    end
  end
end
