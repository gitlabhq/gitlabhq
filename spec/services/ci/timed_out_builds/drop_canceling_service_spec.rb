# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TimedOutBuilds::DropCancelingService, feature_category: :continuous_integration do
  let_it_be(:ci_partition) { create(:ci_partition) }
  let!(:runner) { create :ci_runner }
  let(:timeout) { 600 }
  let!(:job) { create(:ci_build, :canceling, started_at: started_at, runner: runner, timeout: timeout) }

  subject(:service) { described_class.new }

  before_all do
    FactoryBot::Internal.sequences[:ci_partition_id].rewind
  end

  before do
    stub_feature_flags(enforce_job_timeouts_on_canceling_jobs: true)
  end

  context 'when job timeout has been exceeded' do
    let(:started_at) { timeout.seconds.ago - described_class::MINUTE_BUFFER }

    it_behaves_like 'job is canceled with failure reason', 'job_execution_server_timeout'
    it_behaves_like 'when invalid dooms the job bypassing validations'

    context 'when enforce_job_timeouts_on_canceling_jobs is disabled' do
      before do
        stub_feature_flags(enforce_job_timeouts_on_canceling_jobs: false)
      end

      it_behaves_like 'job is unchanged'
    end

    context 'when job becomes complete before processing the timeout' do
      it 'does not doom the job' do
        allow(service).to receive(:drop_incomplete_build).and_wrap_original do |method, *args|
          job.drop!
          method.call(*args)
        end

        service.execute
        expect(job.reload.status).to eq("canceled")
      end
    end

    context 'when the job is not complete' do
      context 'when the status transition fails' do
        it 'dooms the job' do
          allow_next_found_instance_of(Ci::Build) do |build|
            allow(build).to receive(:drop!).and_raise(StandardError)
          end

          service.execute
          expect(job.reload.status).to eq("failed")
          expect(job.failure_reason).to eq("data_integrity_failure")
        end
      end
    end
  end

  context 'when job timeout has not been exceeded' do
    let(:started_at) { rand(timeout.seconds.ago..Time.current) }

    it_behaves_like 'job is unchanged'
  end
end
