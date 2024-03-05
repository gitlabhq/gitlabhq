# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TriggerDownstreamPipelineService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }

  let(:bridge) do
    create(:ci_bridge, status: :created, options: bridge_options, pipeline: pipeline, user: user)
  end

  let(:bridge_options) { { trigger: { project: 'my/project' } } }
  let(:service) { described_class.new(bridge) }

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'when the bridge does not trigger a downstream pipeline' do
      let(:bridge_options) { { trigger: {} } }

      it 'returns a success response' do
        expect(execute).to be_success
        expect(execute.message).to eq('Does not trigger a downstream pipeline')
      end
    end

    # In these tests, we execute the service twice in succession
    describe 'rate limiting', :freeze_time, :clean_gitlab_redis_rate_limiting do
      shared_examples 'creates a log entry' do |downstream_type = 'multi-project'|
        it do
          service.execute

          expect(Gitlab::AppJsonLogger).to receive(:info).with(
            a_hash_including(
              class: described_class.name,
              project_id: project.id,
              current_user_id: user.id,
              pipeline_sha: pipeline.sha,
              subscription_plan: project.actual_plan_name,
              downstream_type: downstream_type,
              message: 'Activated downstream pipeline trigger rate limit'
            )
          )

          execute
        end
      end

      context 'when the limit is exceeded' do
        before do
          stub_application_setting(downstream_pipeline_trigger_limit_per_project_user_sha: 1)
        end

        it 'drops the bridge and does not schedule the downstream pipeline worker', :aggregate_failures do
          service.execute

          expect { execute }.not_to change { ::Ci::CreateDownstreamPipelineWorker.jobs.size }
          expect(bridge).to be_failed
          expect(bridge.failure_reason).to eq('reached_downstream_pipeline_trigger_rate_limit')
          expect(execute).to be_error
          expect(execute.message).to eq('Reached downstream pipeline trigger rate limit')
        end

        it_behaves_like 'creates a log entry'

        context 'with a child pipeline' do
          let(:bridge_options) { { trigger: { include: 'my_child_config.yml' } } }

          it 'drops the bridge and does not schedule the downstream pipeline worker', :aggregate_failures do
            service.execute

            expect { execute }.not_to change { ::Ci::CreateDownstreamPipelineWorker.jobs.size }
            expect(bridge).to be_failed
            expect(bridge.failure_reason).to eq('reached_downstream_pipeline_trigger_rate_limit')
            expect(execute).to be_error
            expect(execute.message).to eq('Reached downstream pipeline trigger rate limit')
          end

          it_behaves_like 'creates a log entry', 'child'
        end
      end

      context 'when the limit is not exceeded' do
        it 'schedules the downstream pipeline worker' do
          service.execute

          expect { execute }.to change { ::Ci::CreateDownstreamPipelineWorker.jobs.size }.by(1)
          expect(bridge).not_to be_failed
          expect(execute).to be_success
          expect(execute.message).to eq('Downstream pipeline enqueued')
        end

        it 'does not create a log entry' do
          service.execute

          expect(Gitlab::AppJsonLogger).not_to receive(:info)

          execute
        end
      end
    end
  end
end
