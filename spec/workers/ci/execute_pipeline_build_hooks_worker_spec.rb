# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExecutePipelineBuildHooksWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let_it_be(:stage) { create(:ci_stage, pipeline: pipeline, project: project) }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline.id) }

    def stub_job_hooks(hooks:, integrations:)
      allow(Ci::Pipeline).to receive(:find_by_id).with(pipeline.id).and_return(pipeline)
      allow(project).to receive(:has_active_hooks?).with(:job_hooks).and_return(hooks)
      allow(project).to receive(:has_active_integrations?).with(:job_hooks).and_return(integrations)

      yield project
    end

    context 'when pipeline exists' do
      let_it_be(:build1) do
        create(:ci_build, name: 'rspec', pipeline: pipeline, ci_stage: stage, project: project, user: user)
      end

      let_it_be(:build2) do
        create(:ci_build, :running, name: 'rubocop', pipeline: pipeline, ci_stage: stage, project: project, user: user)
      end

      it 'executes hooks for all builds with created state' do
        stub_job_hooks(hooks: true, integrations: false) do |proj|
          expect(proj).to receive(:execute_hooks).twice do |data, hook_type|
            expect(hook_type).to eq(:job_hooks)
            expect(data['build_status']).to eq('created')
            expect(data['build_started_at']).to be_nil
            expect(data['build_finished_at']).to be_nil
            expect(data['build_duration']).to be_nil
            expect(data['runner']).to be_nil
          end
          expect(proj).not_to receive(:execute_integrations)
        end

        perform
      end

      it 'executes integrations for all builds with created state' do
        stub_job_hooks(hooks: false, integrations: true) do |proj|
          expect(proj).to receive(:execute_integrations).twice do |data, hook_type|
            expect(hook_type).to eq(:job_hooks)
            expect(data['build_status']).to eq('created')
            expect(data['build_started_at']).to be_nil
            expect(data['build_finished_at']).to be_nil
            expect(data['build_duration']).to be_nil
            expect(data['runner']).to be_nil
          end
          expect(proj).not_to receive(:execute_hooks)
        end

        perform
      end

      it 'executes both hooks and integrations when both are active' do
        stub_job_hooks(hooks: true, integrations: true) do |proj|
          expect(proj).to receive(:execute_hooks).with(anything, :job_hooks).twice
          expect(proj).to receive(:execute_integrations).with(anything, :job_hooks).twice
        end

        perform
      end

      context 'when a build has been retried' do
        let_it_be(:retried_build1) do
          create(:ci_build, :retried, name: build1.name, pipeline: pipeline, ci_stage: stage, project: project,
            user: user)
        end

        it 'sends the retries count of each build' do
          retries_counts = {}

          stub_job_hooks(hooks: true, integrations: false) do |proj|
            allow(proj).to receive(:execute_hooks) do |data, _hook_type|
              retries_counts[data[:build_id]] = data[:retries_count]
            end
          end

          perform

          expect(retries_counts[build1.id]).to eq(build1.retries_count)
          expect(retries_counts[build1.id]).to eq(1)
          expect(retries_counts[build2.id]).to eq(0)
        end
      end

      context 'when user is nil' do
        it 'executes hooks for builds without a user' do
          allow_next_found_instances_of(Ci::Build, 2) do |build|
            allow(build).to receive(:user).and_return(nil)
          end

          stub_job_hooks(hooks: true, integrations: true) do |proj|
            expect(proj).to receive(:execute_hooks).twice
            expect(proj).to receive(:execute_integrations).twice
          end

          perform
        end
      end

      context 'when user is blocked' do
        let_it_be(:blocked_user) { create(:user, :blocked) }
        let_it_be(:build_with_blocked_user) do
          create(:ci_build, pipeline: pipeline, ci_stage: stage, project: project, user: blocked_user)
        end

        it 'does not execute hooks for builds with blocked users' do
          stub_job_hooks(hooks: true, integrations: false) do |proj|
            expect(proj).to receive(:execute_hooks).twice
          end

          perform
        end
      end

      context 'when project has no active hooks or integrations' do
        it 'does not build the payload or execute hooks' do
          expect(Gitlab::DataBuilder::Build).not_to receive(:build)

          stub_job_hooks(hooks: false, integrations: false) do |proj|
            expect(proj).not_to receive(:execute_hooks)
            expect(proj).not_to receive(:execute_integrations)
          end

          perform
        end
      end

      it 'does not create N+1 queries' do
        create(:project_hook, project: project, job_events: true)

        perform_without_delivery = -> do
          allow(Ci::Pipeline).to receive(:find_by_id).with(pipeline.id).and_return(pipeline)
          allow(project).to receive(:execute_hooks)

          described_class.new.perform(pipeline.id)
        end

        perform_without_delivery.call

        control = ActiveRecord::QueryRecorder.new { perform_without_delivery.call }

        create(:ci_build, pipeline: pipeline, ci_stage: stage, project: project, user: user)
        create(:ci_build, :retried, name: build2.name, pipeline: pipeline, ci_stage: stage, project: project,
          user: user)

        expect { perform_without_delivery.call }.not_to exceed_query_limit(control)
      end
    end

    context 'when pipeline does not exist' do
      it 'does not raise error' do
        expect { described_class.new.perform(-1) }.not_to raise_error
      end
    end
  end
end
