# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreatePipelineWorker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request) }

    context 'when the objects exist' do
      it 'calls the merge request create pipeline service and calls update head pipeline' do
        aggregate_failures do
          expect_next_instance_of(MergeRequests::CreatePipelineService, project: project, current_user: user) do |service|
            expect(service).to receive(:execute).with(merge_request)
          end

          expect(MergeRequest).to receive(:find_by_id).with(merge_request.id).and_return(merge_request)
          expect(merge_request).to receive(:update_head_pipeline)

          subject.perform(project.id, user.id, merge_request.id)
        end
      end
    end

    shared_examples 'when object does not exist' do
      it 'does not call the create pipeline service' do
        expect(MergeRequests::CreatePipelineService).not_to receive(:new)

        expect { subject.perform(project.id, user.id, merge_request.id) }
          .not_to raise_exception
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
end
