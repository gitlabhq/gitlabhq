# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipelines::AddJobService, feature_category: :continuous_integration do
  include ExclusiveLeaseHelpers

  let_it_be_with_refind(:pipeline) { create(:ci_pipeline, partition_id: ci_testing_partition_id) }
  let(:stage) { create(:ci_stage, pipeline: pipeline, partition_id: pipeline.partition_id) }
  let(:job) { build(:ci_build, :without_job_definition, ci_stage: stage) }

  subject(:service) { described_class.new(pipeline) }

  context 'when the pipeline is not persisted' do
    let(:pipeline) { build(:ci_pipeline) }

    it 'raises error' do
      expect { service }.to raise_error('Pipeline must be persisted for this service to be used')
    end
  end

  describe '#execute!' do
    subject(:execute) do
      service.execute!(job) do |job|
        job.save!
      end
    end

    it 'assigns pipeline attributes to the job' do
      expect { execute }
        .to change { job.slice(:pipeline, :project, :ref) }
        .to(pipeline: pipeline, project: pipeline.project, ref: pipeline.ref)
    end

    it 'assigns partition_id to job' do
      expect { execute }.to change(job, :partition_id).to(pipeline.partition_id)
    end

    it 'returns a service response with the job as payload' do
      expect(execute).to be_success
      expect(execute.payload[:job]).to eq(job)
    end

    it 'calls update_older_statuses_retried!' do
      expect(job).to receive(:update_older_statuses_retried!)

      execute
    end

    context 'when the block raises a state transition error' do
      subject(:execute) do
        service.execute!(job) do |job|
          raise StateMachines::InvalidTransition.new(job, job.class.state_machine, :enqueue)
        end
      end

      it 'returns a service response with the error and the job as payload' do
        expect(execute).to be_error
        expect(execute.payload[:job]).to eq(job)
        expect(execute.message).to eq(
          "Cannot transition status via :enqueue from :pending (Reason(s): Transition halted)"
        )
      end
    end

    context 'when the block raises an error' do
      subject(:execute) do
        service.execute!(job) do |job|
          raise "this is an error"
        end
      end

      it 'returns a service response with the error and the job as payload' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).at_least(:once)
        expect(execute).to be_error
        expect(execute.payload[:job]).to eq(job)
        expect(execute.message).to eq('this is an error')
      end
    end

    context 'exclusive lock' do
      let(:lock_uuid) { 'test' }
      let(:lock_key) { "ci:pipelines:#{pipeline.id}:add-job" }
      let(:lock_timeout) { 1.minute }

      before do
        # "Please stub a default value first if message might be received with other args as well."
        allow(Gitlab::ExclusiveLease).to receive(:new).and_call_original
      end

      it 'uses exclusive lock' do
        lease = stub_exclusive_lease(lock_key, lock_uuid, timeout: lock_timeout)
        expect(lease).to receive(:try_obtain)
        expect(lease).to receive(:cancel)

        expect(execute).to be_success
        expect(execute.payload[:job]).to eq(job)
      end
    end
  end
end
