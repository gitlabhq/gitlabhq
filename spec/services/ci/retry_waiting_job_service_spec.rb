# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetryWaitingJobService, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:project, freeze: true) { create(:project, maintainers: [user]) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project, user: user) }
  let_it_be(:runner, freeze: true) { create(:ci_runner, :with_runner_manager) }

  let(:runner_manager_id) { runner.runner_managers.sole.id }
  let(:redis_klass) { Gitlab::Redis::SharedState }
  let(:metrics) { instance_double(Gitlab::Ci::Queue::Metrics) }
  let(:service) { described_class.new(build, metrics) }

  describe '#execute' do
    subject(:execute) { service.execute }

    before do
      allow(metrics).to receive(:increment_queue_operation)
    end

    shared_examples 'job is not in waiting state' do
      it 'returns error response' do
        expect(execute).to be_error
        expect(execute.message).to eq('Job is not in waiting state')
        expect(execute.payload[:reason]).to eq(:not_in_waiting_state)
      end

      it 'increments runner_queue_timeout metric' do
        expect(metrics).to receive(:increment_queue_operation).with(:runner_queue_timeout)

        execute
      end

      it 'does not call RetryJobService' do
        expect(Ci::RetryJobService).not_to receive(:new)

        execute
      end
    end

    context 'when build is nil' do
      let(:build) { nil }

      it_behaves_like 'job is not in waiting state'
    end

    context 'when build is not pending' do
      let_it_be(:build, freeze: true) { create(:ci_build, :running, pipeline: pipeline, user: user) }

      it_behaves_like 'job is not in waiting state'
    end

    context 'when build is retryable' do
      let_it_be(:build, freeze: true) { create(:ci_build, :retryable, pipeline: pipeline, user: user) }

      it_behaves_like 'job is not in waiting state'
    end

    context 'when build is waiting for runner ack' do
      let_it_be_with_refind(:build) do
        create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline, runner: runner, user: user)
      end

      it 'increments runner_queue_timeout metric' do
        expect(metrics).to receive(:increment_queue_operation).with(:runner_queue_timeout)

        execute
      end

      it 'drops the build with runner_provisioning_timeout reason' do
        expect { execute }.to change { build.reload.status }.from('pending').to('failed')
        expect(build.failure_reason).to eq('runner_provisioning_timeout')
      end

      context 'when build is not retryable' do
        context 'with build already failed' do
          before do
            build.drop!
          end

          it_behaves_like 'job is not in waiting state'
        end

        context 'with build redis ttl not yet elapsed' do
          before do
            build.set_waiting_for_runner_ack(runner_manager_id)
          end

          it 'returns error response' do
            expect(execute).to be_error
            expect(execute.message).to eq('Job is not finished waiting')
            expect(execute.payload[:reason]).to eq(:not_finished_waiting)
          end

          it 'does not call RetryJobService' do
            expect(Ci::RetryJobService).not_to receive(:new)

            execute
          end

          it 'does not drop the build' do
            expect { execute }.not_to change { build.reload.status }.from('pending')
          end
        end
      end

      context 'when RetryJobService fails' do
        before do
          allow(build).to receive_messages(retryable?: true, retried?: false)

          allow_next_instance_of(Ci::RetryJobService) do |retry_service|
            allow(retry_service).to receive(:execute).and_return(ServiceResponse.error(message: 'Retry failed'))
          end
        end

        it 'returns :not_auto_retryable error' do
          result = execute

          expect(result).to be_error
          expect(result.message).to eq('Job is not auto-retryable')
          expect(execute.payload[:reason]).to eq(:not_auto_retryable)
        end

        it 'still drops the build' do
          expect { execute }.to change { build.reload.status }.from('pending').to('failed')
          expect(build.failure_reason).to eq('runner_provisioning_timeout')
        end
      end
    end

    describe 'integration with real RetryJobService', :aggregate_failures do
      let!(:build) { create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline, user: user, runner: runner) }

      before do
        expire_redis_ttl(runner_build_ack_queue_key)
      end

      specify { expect(build).not_to be_retryable }

      shared_examples 'job is retried with provisioning timeout' do
        it 'increments runner_queue_timeout metric' do
          expect(metrics).to receive(:increment_queue_operation).with(:runner_queue_timeout)

          execute
        end

        it 'drops the job with runner_provisioning_timeout reason and retries it' do
          expect { execute }
            .to change { build.reload.status }.from('pending').to('failed')
            .and change { Ci::Build.count }.by(1)

          expect(build.reload).to be_failed
          expect(build).to be_retried
          expect(build.failure_reason).to eq('runner_provisioning_timeout')

          new_build = Ci::Build.id_not_in(build.id).last
          expect(new_build).to be_pending
          expect(new_build.name).to eq(build.name)
          expect(new_build.pipeline).to eq(pipeline)
        end
      end

      it_behaves_like 'job is retried with provisioning timeout'

      it 'retries the job using RetryJobService' do
        expect(Ci::RetryJobService).to receive(:new).and_call_original

        execute
      end

      context 'when auto_retry_allowed? is false' do
        before do
          allow(build).to receive(:auto_retry_allowed?).and_return(false)
        end

        it 'returns error response' do
          expect(execute).to be_error
          expect(execute.message).to eq('Job is not auto-retryable')
          expect(execute.payload[:reason]).to eq(:not_auto_retryable)
        end
      end

      context 'when retry count exceeds limit' do
        before do
          allow(build).to receive(:retries_count)
            .and_return(Gitlab::Ci::Build::AutoRetry::DEFAULT_RETRIES[:runner_provisioning_timeout])
        end

        it 'returns error response' do
          expect(execute).to be_error
          expect(execute.message).to eq('Job is not auto-retryable')
          expect(execute.payload[:reason]).to eq(:not_auto_retryable)
        end
      end
    end
  end

  private

  def runner_build_ack_queue_key
    build.send(:runner_build_ack_queue_key)
  end

  def expire_redis_ttl(cache_key)
    redis_klass.with do |redis|
      redis.del(cache_key)
    end
  end
end
