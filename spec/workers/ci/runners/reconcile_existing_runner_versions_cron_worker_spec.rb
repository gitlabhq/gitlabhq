# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::ReconcileExistingRunnerVersionsCronWorker, feature_category: :fleet_visibility do
  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'when scheduled by cronjob' do
      it 'reschedules itself' do
        expect(described_class).to(receive(:perform_in).with(a_value_between(0, 12.hours.in_seconds), false))
        expect(::Ci::Runners::ReconcileExistingRunnerVersionsService).not_to receive(:new)

        worker.perform
      end
    end

    context 'when self-scheduled' do
      include_examples 'an idempotent worker' do
        subject(:perform) { perform_multiple(false, worker: worker) }

        it 'executes the service' do
          expect_next_instance_of(Ci::Runners::ReconcileExistingRunnerVersionsService) do |service|
            expect(service).to receive(:execute).and_return(ServiceResponse.success)
          end.exactly(worker_exec_times)

          perform
        end
      end

      it 'logs the service result' do
        expect_next_instance_of(Ci::Runners::ReconcileExistingRunnerVersionsService) do |service|
          expect(service).to receive(:execute)
            .and_return(ServiceResponse.success(payload: { some_job_result_key: 'some_value' }))
        end

        worker.perform(false)

        expect(worker.logging_extras).to eq({
          'extra.ci_runners_reconcile_existing_runner_versions_cron_worker.some_job_result_key' => 'some_value'
        })
      end
    end
  end
end
