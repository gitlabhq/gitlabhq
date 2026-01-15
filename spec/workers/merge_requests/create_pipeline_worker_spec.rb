# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreatePipelineWorker, feature_category: :pipeline_composition do
  describe '#perform' do
    let(:user) { create(:user) }
    let_it_be_with_reload(:project) { create(:project) }
    let(:merge_request) { create(:merge_request) }
    let(:worker) { described_class.new }

    subject do
      worker.perform(
        project.id, user.id, merge_request.id,
        'pipeline_creation_request' => { 'key' => '123', 'id' => '456' }, 'gitaly_context' => {}
      )
    end

    context 'when the objects exist' do
      it 'calls the merge request create pipeline service and calls update head pipeline' do
        aggregate_failures do
          expect_next_instance_of(MergeRequests::CreatePipelineService,
            project: project,
            current_user: user,
            params: {
              allow_duplicate: nil,
              push_options: nil,
              gitaly_context: {},
              pipeline_creation_request: { 'key' => '123', 'id' => '456' }
            }) do |service|
            expect(service).to receive(:execute).with(merge_request)
          end

          expect(MergeRequest).to receive(:find_by_id).with(merge_request.id).and_return(merge_request)
          expect(merge_request).to receive(:update_head_pipeline)

          subject
        end
      end

      context 'when push options are passed as Hash to the worker' do
        let(:extra_params) do
          {
            'pipeline_creation_request' => { 'key' => '123', 'id' => '456' },
            'push_options' => { 'ci' => { 'skip' => true } },
            'gitaly_context' => {}
          }
        end

        subject { worker.perform(project.id, user.id, merge_request.id, extra_params) }

        it 'calls the merge request create pipeline service and calls update head pipeline' do
          aggregate_failures do
            expect_next_instance_of(MergeRequests::CreatePipelineService,
              project: project,
              current_user: user,
              params: {
                allow_duplicate: nil,
                push_options: { ci: { skip: true } },
                gitaly_context: {},
                pipeline_creation_request: { 'key' => '123', 'id' => '456' }
              }) do |service|
              expect(service).to receive(:execute).with(merge_request)
            end

            expect(MergeRequest).to receive(:find_by_id).with(merge_request.id).and_return(merge_request)
            expect(merge_request).to receive(:update_head_pipeline)

            subject
          end
        end
      end
    end

    shared_examples 'when object does not exist' do
      it 'does not call the create pipeline service' do
        expect(MergeRequests::CreatePipelineService).not_to receive(:new)

        expect { subject }.not_to raise_exception
      end
    end

    context 'when the project does not exist' do
      before do
        project.destroy!
      end

      it_behaves_like 'when object does not exist'
    end

    context 'when the user does not exist' do
      before do
        user.destroy!
      end

      it_behaves_like 'when object does not exist'
    end

    context 'when the merge request does not exist' do
      before do
        merge_request.destroy!
      end

      it_behaves_like 'when object does not exist'
    end
  end

  describe 'retry behavior' do
    let(:user) { create(:user) }
    let_it_be_with_reload(:project) { create(:project) }
    let(:merge_request) { create(:merge_request) }
    let(:worker) { described_class.new }
    let(:pipeline_creation_request) { Ci::PipelineCreation::Requests.start_for_merge_request(merge_request) }
    let(:params) do
      {
        'pipeline_creation_request' => pipeline_creation_request,
        'gitaly_context' => {}
      }
    end

    subject { worker.perform(project.id, user.id, merge_request.id, params) }

    it 'returns 10 seconds for retry interval' do
      retry_in = described_class.sidekiq_retry_in_block.call(1)
      expect(retry_in).to eq(10)
    end

    context 'when service raises a retriable error' do
      before do
        allow_next_instance_of(MergeRequests::CreatePipelineService) do |service|
          allow(service).to receive(:execute).and_raise(StandardError, 'Temporary failure')
        end
      end

      it 'raises the error to trigger Sidekiq retry' do
        expect { subject }.to raise_error(StandardError, 'Temporary failure')
      end

      it 'keeps status as IN_PROGRESS during retries', :clean_gitlab_redis_shared_state do
        expect { subject }.to raise_error(StandardError)

        result = Ci::PipelineCreation::Requests.hget(pipeline_creation_request)
        expect(result['status']).to eq('in_progress')
      end
    end
  end

  describe 'sidekiq_retries_exhausted' do
    let(:merge_request) { create(:merge_request) }
    let(:pipeline_creation_request) do
      Ci::PipelineCreation::Requests.start_for_merge_request(merge_request)
    end

    let(:job) do
      {
        'args' => [
          1, 2, 3,
          { 'pipeline_creation_request' => pipeline_creation_request }
        ]
      }
    end

    context 'when pipeline_creation_request is present' do
      it 'marks the request as failed' do
        described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new)

        result = Ci::PipelineCreation::Requests.hget(pipeline_creation_request)
        expect(result['status']).to eq('failed')
        expect(result['error']).to include('after multiple retries')
      end

      it 'triggers GraphQL subscription' do
        expect(GraphqlTriggers).to receive(:ci_pipeline_creation_requests_updated)
          .with(merge_request)

        described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new)
      end
    end

    context 'when pipeline_creation_request is nil' do
      let(:job) { { 'args' => [1, 2, 3, nil] } }

      it 'does not raise an error' do
        expect { described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new) }
          .not_to raise_error
      end
    end

    context 'when merge request cannot be found from key' do
      let(:pipeline_creation_request) do
        { 'key' => 'pipeline_creation:projects:{1}:mrs:{999999999}', 'id' => 'test-id' }
      end

      it 'does not trigger GraphQL subscription' do
        expect(GraphqlTriggers).not_to receive(:ci_pipeline_creation_requests_updated)

        described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new)
      end
    end
  end
end
