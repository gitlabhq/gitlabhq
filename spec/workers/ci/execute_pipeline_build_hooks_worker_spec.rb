# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExecutePipelineBuildHooksWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let_it_be(:stage) { create(:ci_stage, pipeline: pipeline, project: project) }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline.id) }

    context 'when pipeline exists' do
      let_it_be(:build1) { create(:ci_build, pipeline: pipeline, ci_stage: stage, project: project, user: user) }
      let_it_be(:build2) do
        create(:ci_build, :running, pipeline: pipeline, ci_stage: stage, project: project, user: user)
      end

      it 'executes hooks for all builds with created state' do
        allow_next_instances_of(Project, 2) do |proj|
          allow(proj).to receive(:has_active_hooks?).with(:job_hooks).and_return(true)
          allow(proj).to receive(:has_active_integrations?).with(:job_hooks).and_return(false)

          expect(proj).to receive(:execute_hooks) do |data, hook_type|
            expect(hook_type).to eq(:job_hooks)
            expect(data['build_status']).to eq('created')
            expect(data['build_started_at']).to be_nil
            expect(data['build_finished_at']).to be_nil
            expect(data['build_duration']).to be_nil
            expect(data['runner']).to be_nil
          end
        end

        perform
      end

      it 'executes integrations for all builds with created state' do
        allow_next_instances_of(Project, 2) do |proj|
          allow(proj).to receive(:has_active_hooks?).with(:job_hooks).and_return(false)
          allow(proj).to receive(:has_active_integrations?).with(:job_hooks).and_return(true)

          expect(proj).to receive(:execute_integrations) do |data, hook_type|
            expect(hook_type).to eq(:job_hooks)
            expect(data['build_status']).to eq('created')
            expect(data['build_started_at']).to be_nil
            expect(data['build_finished_at']).to be_nil
            expect(data['build_duration']).to be_nil
            expect(data['runner']).to be_nil
          end
        end

        perform
      end

      it 'executes both hooks and integrations when both are active' do
        allow_next_instances_of(Project, 2) do |proj|
          allow(proj).to receive(:has_active_hooks?).with(:job_hooks).and_return(true)
          allow(proj).to receive(:has_active_integrations?).with(:job_hooks).and_return(true)

          expect(proj).to receive(:execute_hooks).with(anything, :job_hooks)
          expect(proj).to receive(:execute_integrations).with(anything, :job_hooks)
        end

        perform
      end

      context 'when project is nil' do
        it 'skips hooks' do
          allow_next_found_instances_of(Ci::Build, 2) do |build|
            allow(build).to receive(:project).and_return(nil)
          end

          expect(Project).not_to receive(:new)

          perform
        end
      end

      context 'when user is nil' do
        it 'does not execute hooks for builds with nil users' do
          allow_next_found_instances_of(Ci::Build, 2) do |build|
            allow(build).to receive(:user).and_return(nil)
          end

          allow_next_instances_of(Project, 2) do |proj|
            expect(proj).not_to receive(:execute_hooks)
            expect(proj).not_to receive(:execute_integrations)
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
          allow_next_instances_of(Project, 3) do |proj|
            allow(proj).to receive(:has_active_hooks?).with(:job_hooks).and_return(true)
            allow(proj).to receive(:has_active_integrations?).with(:job_hooks).and_return(false)

            expect(proj).to receive(:execute_hooks).twice
          end

          described_class.new.perform(pipeline.id)
        end
      end

      context 'when project has no active hooks or integrations' do
        it 'does not execute hooks' do
          allow_next_instances_of(Project, 2) do |proj|
            allow(proj).to receive(:has_active_hooks?).with(:job_hooks).and_return(false)
            allow(proj).to receive(:has_active_integrations?).with(:job_hooks).and_return(false)

            expect(proj).not_to receive(:execute_hooks)
            expect(proj).not_to receive(:execute_integrations)
          end

          perform
        end
      end

      it 'does not create N+1 queries' do
        control = ActiveRecord::QueryRecorder.new { described_class.new.perform(pipeline.id) }

        create(:ci_build, pipeline: pipeline, ci_stage: stage, project: project, user: user)

        expect { described_class.new.perform(pipeline.id) }.not_to exceed_query_limit(control).with_threshold(1)
      end
    end

    context 'when pipeline does not exist' do
      it 'does not raise error' do
        expect { described_class.new.perform(-1) }.not_to raise_error
      end
    end
  end
end
