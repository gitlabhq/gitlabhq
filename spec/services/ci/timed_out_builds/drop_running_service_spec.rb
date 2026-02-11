# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TimedOutBuilds::DropRunningService, feature_category: :continuous_integration do
  let_it_be(:ci_partition) { create(:ci_partition) }
  let!(:runner) { create :ci_runner }
  let!(:running_build) { create(:ci_running_build, runner: runner, build: job, created_at: created_at) }
  let!(:job) { create(:ci_build, :running, runner: runner, timeout: 600) }

  subject(:service) { described_class.new }

  before_all do
    FactoryBot::Internal.sequences[:ci_partition_id].rewind
  end

  context 'when job timeout has been exceeded' do
    let(:created_at) { job.timeout.seconds.ago - described_class::MINUTE_BUFFER }

    it_behaves_like 'job is dropped with failure reason', 'job_execution_timeout'
    it_behaves_like 'when invalid dooms the job bypassing validations'

    context 'when job becomes complete before processing the timeout' do
      it 'does not doom the job' do
        allow(service).to receive(:drop_incomplete_build).and_wrap_original do |method, *args|
          job.success
          method.call(*args)
        end

        service.execute
        expect(job.reload.status).to eq("success")
      end
    end

    context 'when the job is not complete' do
      context 'when the status changes to completed on a retry in retry_lock' do
        before do
          allow_next_found_instance_of(Ci::Build) do |build|
            allow(build).to receive(:drop!) do
              raise ActiveRecord::StaleObjectError, "mocked stale"
            end

            allow(build).to receive(:reset) do
              build.success!
            end
          end
        end

        it 'does not doom the job' do
          service.execute
          expect(job.reload).to be_success
        end
      end

      context 'when the status transition fails' do
        before do
          allow_next_found_instance_of(Ci::Build) do |build|
            allow(build).to receive(:drop!).and_raise(StateMachines::InvalidTransition)
          end
        end

        it 'dooms the job' do
          service.execute
          expect(job.reload.status).to eq("failed")
          expect(job.failure_reason).to eq("data_integrity_failure")
        end
      end
    end
  end

  context 'when job timeout has not been exceeded' do
    let(:created_at) { rand(job.timeout.seconds.ago..Time.current) }

    it_behaves_like 'job is unchanged'
  end
end
