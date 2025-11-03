# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetryStuckWaitingJobWorker, :clean_gitlab_redis_shared_state, feature_category: :continuous_integration do
  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:project, freeze: true) { create(:project, maintainers: [user]) }
  let_it_be(:runner, freeze: true) { create(:ci_runner, :with_runner_manager) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }

  let(:redis_klass) { Gitlab::Redis::SharedState }
  let(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker' do
    let_it_be(:build, freeze: true) do
      create(:ci_build, :waiting_for_runner_ack, project: project, pipeline: pipeline, runner: runner, user: user)
    end

    let(:job_args) { [build.id] }

    before do
      allow_next_instances_of(Ci::RetryWaitingJobService, build) do |service|
        allow(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      allow(Ci::Build).to receive(:find_by_id).with(build.id).and_return(build)
    end
  end

  describe '#perform' do
    let_it_be(:build, freeze: true) do
      create(:ci_build, :waiting_for_runner_ack, project: project, pipeline: pipeline, runner: runner, user: user)
    end

    subject(:perform) { worker.perform(build_id) }

    context 'when build exists' do
      let(:build_id) { build.id }

      before do
        allow(Ci::Build).to receive(:find_by_id).with(build_id).and_return(build)
      end

      context 'and is waiting for runner ack' do
        before do
          allow(build).to receive(:waiting_for_runner_ack?).and_return(true)
        end

        context 'when runner is still actively heartbeating' do
          before do
            allow_next_instances_of(Ci::RetryWaitingJobService, build) do |service|
              allow(service).to receive(:execute) do
                ServiceResponse.error(
                  message: 'Job is not finished waiting', payload: { job: build, reason: :not_finished_waiting })
              end
            end
          end

          it 'calls RetryWaitingJobService but does not drop build' do
            expect_next_instance_of(Ci::RetryWaitingJobService, build) do |service|
              expect(service).to receive(:execute) do
                ServiceResponse.error(
                  message: 'Job is not finished waiting', payload: { job: build, reason: :not_finished_waiting })
              end
            end

            perform
          end

          it 'reschedules itself for RETRY_TIMEOUT seconds' do
            expect(described_class).to receive(:perform_in).with(described_class::RETRY_TIMEOUT, build_id)

            perform
          end

          it 'logs extra metadata with the result message' do
            expect(worker).to receive(:log_extra_metadata_on_done).with(:message, 'Job is not finished waiting')

            perform
          end

          it 'consistently reschedules with the same TTL value' do
            expect(described_class).to receive(:perform_in).with(described_class::RETRY_TIMEOUT, build_id).twice

            # First execution
            worker.perform(build_id)

            # Second execution (simulating the rescheduled job running)
            worker.perform(build_id)
          end
        end

        context 'when runner is not actively heartbeating' do
          before do
            allow_next_instance_of(Ci::RetryWaitingJobService, build) do |service|
              allow(service).to(receive(:execute)).and_return(ServiceResponse.success)
            end
          end

          it 'does not reschedule itself' do
            expect(described_class).not_to receive(:perform_in)

            perform
          end

          it 'does not log extra metadata when result has no message' do
            expect(worker).not_to receive(:log_extra_metadata_on_done)

            perform
          end

          context 'when service returns success with a message' do
            before do
              allow_next_instance_of(Ci::RetryWaitingJobService, build) do |service|
                allow(service).to(receive(:execute))
                  .and_return(ServiceResponse.success(message: 'Job successfully retried'))
              end
            end

            it 'logs extra metadata with the result message' do
              expect(worker).to receive(:log_extra_metadata_on_done).with(:message, 'Job successfully retried')

              perform
            end
          end
        end
      end

      context 'and is not waiting for runner ack' do
        before do
          allow(build).to receive(:waiting_for_runner_ack?).and_return(false)

          allow_next_instance_of(Ci::RetryWaitingJobService, build) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.success)
          end
        end

        it 'does not reschedule itself' do
          expect(described_class).not_to receive(:perform_in)

          perform
        end

        it 'calls RetryWaitingJobService nonetheless' do
          expect_next_instance_of(Ci::RetryWaitingJobService, build) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.success)
          end

          perform
        end

        it 'does not log extra metadata when result has no message' do
          expect(worker).not_to receive(:log_extra_metadata_on_done)

          perform
        end
      end
    end

    context 'when build does not exist' do
      let(:build_id) { non_existing_record_id }

      before do
        allow_next_instances_of(Ci::RetryWaitingJobService, nil) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Job is not in waiting state'))
        end
      end

      it 'does not reschedule itself' do
        expect(described_class).not_to receive(:perform_in)

        perform
      end

      it 'calls RetryWaitingJobService with nil build' do
        expect_next_instances_of(Ci::RetryWaitingJobService, nil) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Job is not in waiting state'))
        end

        expect { perform }.not_to raise_error
      end

      it 'logs extra metadata with the result message' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:message, 'Job is not in waiting state')

        perform
      end
    end
  end

  describe 'integration with RetryWaitingJobService' do
    let_it_be_with_refind(:build) do
      create(:ci_build, :waiting_for_runner_ack, project: project, pipeline: pipeline, runner: runner, user: user)
    end

    let(:build_id) { build.id }

    before do
      allow(Ci::Build).to receive(:find_by_id).with(build_id).and_return(build)
    end

    context 'when runner is still actively heartbeating' do
      before do
        allow(build).to receive(:waiting_for_runner_ack?).and_return(true)
      end

      it 'drops build and does not retry it' do
        result = nil
        expect { result = worker.perform(build_id) }
          .to not_change { Ci::Build.all.count }.from(1)
          .and not_change { build.retries_count }

        expect(build.reload).to be_pending
        expect(result).to be_error
      end
    end

    context 'when runner is not actively heartbeating' do
      before do
        allow(build).to receive(:waiting_for_runner_ack?).and_return(false)
      end

      it 'drops and retries build' do
        result = nil
        expect { result = worker.perform(build_id) }
          .to change { Ci::Build.all.count }.by(1)
          .and change { build.retries_count }.by(1)

        expect(build.reload).to be_failed
        expect(build.failure_reason).to eq('runner_provisioning_timeout')
        expect(result).to be_success
      end

      context 'when retry count exceeds limit' do
        before do
          allow(build).to receive(:retries_count)
            .and_return(Gitlab::Ci::Build::AutoRetry::DEFAULT_RETRIES[:runner_provisioning_timeout])
        end

        it 'drops build and does not retry it' do
          result = nil
          expect { result = worker.perform(build_id) }
            .to not_change { Ci::Build.all.count }.from(1)
            .and not_change { build.retries_count }

          expect(build.reload).to be_failed
          expect(result).to be_error
        end
      end
    end
  end
end
