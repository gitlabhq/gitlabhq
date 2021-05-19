# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::MergeRequests::AddTodoWhenBuildFailsWorker do
  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, :detached_merge_request_pipeline) }
    let_it_be(:job) { create(:ci_build, project: project, pipeline: pipeline, status: :failed) }

    let(:job_args) { job.id }

    subject(:perform_twice) { perform_multiple(job_args, exec_times: 2) }

    include_examples 'an idempotent worker' do
      it 'executes todo service' do
        service = double
        expect(::MergeRequests::AddTodoWhenBuildFailsService).to receive(:new).with(project: project).and_return(service).twice
        expect(service).to receive(:execute).with(job).twice

        perform_twice
      end
    end

    context 'when job does not exist' do
      let(:job_args) { 0 }

      it 'returns nil' do
        expect(described_class.new.perform(job_args)).to eq(nil)
      end
    end

    context 'when project does not exist' do
      before do
        job.update!(project_id: nil)
      end

      it 'returns nil' do
        expect(described_class.new.perform(job_args)).to eq(nil)
      end
    end

    context 'when pipeline does not exist' do
      before do
        job.update_attribute('pipeline_id', nil)
      end

      it 'returns nil' do
        expect(described_class.new.perform(job_args)).to eq(nil)
      end
    end
  end
end
