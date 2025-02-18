# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExecuteBuildHooksWorker, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, pipeline: pipeline) }

  let(:build_data) do
    {
      object_kind: 'build',
      ref: 'main',
      tag: false,
      build_id: build.id,
      build_name: build.name,
      build_stage: build.stage_name,
      build_status: build.status,
      project_id: project.id,
      project_name: project.full_name
    }
  end

  describe '#perform' do
    subject(:perform) { described_class.new.perform(project.id, build_data) }

    context 'when project exists' do
      context 'with project services' do
        let!(:integration) { create(:integration, active: true, job_events: true, project: project) }

        it 'executes services' do
          allow_next_instance_of(Project) do |project|
            expect(project).to receive(:execute_integrations).with(build_data, :job_hooks)
          end

          perform
        end
      end

      context 'with project hooks' do
        let!(:hook) { create(:project_hook, project: project, job_events: true) }

        it 'executes hooks' do
          allow_next_instance_of(Project) do |project|
            expect(project).to receive(:execute_hooks).with(build_data, :job_hooks)
          end

          perform
        end
      end

      context 'without hooks or services' do
        it 'does not execute hooks or services' do
          allow_next_instance_of(Project) do |project|
            expect(project).not_to receive(:execute_hooks)
            expect(project).not_to receive(:execute_integrations)
          end

          perform
        end
      end
    end

    context 'when project does not exist' do
      subject(:perform) { described_class.new.perform(non_existing_record_id, build_data) }

      it 'does nothing' do
        allow_next_instance_of(Project) do |project|
          expect(project).not_to receive(:execute_hooks)
          expect(project).not_to receive(:execute_integrations)
        end

        perform
      end
    end
  end
end
