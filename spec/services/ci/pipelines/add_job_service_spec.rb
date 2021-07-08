# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipelines::AddJobService do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  let(:job) { build(:ci_build) }

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
      expect do
        execute
      end.to change { job.slice(:pipeline, :project, :ref) }.to(
        pipeline: pipeline, project: pipeline.project, ref: pipeline.ref
      )
    end

    it 'returns a service response with the job as payload' do
      expect(execute).to be_success
      expect(execute.payload[:job]).to eq(job)
    end

    it 'calls update_older_statuses_retried!' do
      expect(job).to receive(:update_older_statuses_retried!)

      execute
    end

    context 'when the block raises an error' do
      subject(:execute) do
        service.execute!(job) do |job|
          raise "this is an error"
        end
      end

      it 'returns a service response with the error and the job as payload' do
        expect(execute).to be_error
        expect(execute.payload[:job]).to eq(job)
        expect(execute.message).to eq('this is an error')
      end
    end

    context 'when the FF ci_fix_commit_status_retried is disabled' do
      before do
        stub_feature_flags(ci_fix_commit_status_retried: false)
      end

      it 'does not call update_older_statuses_retried!' do
        expect(job).not_to receive(:update_older_statuses_retried!)

        execute
      end
    end
  end
end
