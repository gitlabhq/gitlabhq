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

    context 'when build_data has string keys' do
      let(:string_build_data) do
        {
          'object_kind' => 'build',
          'ref' => 'main',
          'build_id' => build.id,
          'build_name' => build.name,
          'build_stage' => build.stage_name,
          'build_status' => build.status,
          'project_id' => project.id,
          'project_name' => project.full_name
        }
      end

      it 'converts data to indifferent access' do
        allow_next_instance_of(Project) do |project|
          expect(project).to receive(:execute_hooks).with(
            kind_of(ActiveSupport::HashWithIndifferentAccess),
            :job_hooks
          )
        end

        described_class.new.perform(project.id, string_build_data)
      end

      it 'allows both string and symbol access to build data' do
        allow_next_instance_of(Project) do |project|
          allow(project).to receive(:has_active_hooks?).and_return(true)
          expect(project).to receive(:execute_hooks) do |data, _hook_type|
            expect(data[:object_kind]).to eq('build')
            expect(data['object_kind']).to eq('build')
            expect(data[:build_name]).to eq(build.name)
            expect(data['build_name']).to eq(build.name)
          end
        end

        described_class.new.perform(project.id, string_build_data)
      end
    end

    context 'with Datadog integration' do
      let!(:datadog) do
        integration = create(:datadog_integration,
          project: project,
          active: true,
          datadog_site: 'datadoghq.com',
          api_key: 'test_api_key',
          datadog_ci_visibility: true)

        integration.update!(job_events: true)
        integration
      end

      it 'executes the Datadog integration with build data' do
        expect(Integrations::ExecuteWorker).to receive(:perform_async)
          .with(datadog.id, hash_including(object_kind: 'build'))

        perform
      end
    end

    context 'when build_data has symbol keys' do
      it 'converts data to indifferent access' do
        allow_next_instance_of(Project) do |project|
          expect(project).to receive(:execute_hooks).with(
            kind_of(ActiveSupport::HashWithIndifferentAccess),
            :job_hooks
          )
        end

        perform
      end

      it 'allows both string and symbol access to build data' do
        allow_next_instance_of(Project) do |project|
          allow(project).to receive(:has_active_hooks?).and_return(true)
          expect(project).to receive(:execute_hooks) do |data, _hook_type|
            expect(data[:object_kind]).to eq('build')
            expect(data['object_kind']).to eq('build')
            expect(data[:build_name]).to eq(build.name)
            expect(data['build_name']).to eq(build.name)
          end
        end

        perform
      end
    end

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

    describe 'logs build status' do
      let(:worker) { described_class.new }

      it 'logs build status when present in build_data' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:build_status, build.status)

        worker.perform(project.id, build_data)
      end

      it 'logs nil build status when not present in build_data' do
        build_data_without_status = build_data.except(:build_status)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:build_status, nil)

        worker.perform(project.id, build_data_without_status)
      end

      it 'logs build status with string keys' do
        string_build_data = build_data.stringify_keys
        expect(worker).to receive(:log_extra_metadata_on_done).with(:build_status, build.status)

        worker.perform(project.id, string_build_data)
      end
    end
  end
end
