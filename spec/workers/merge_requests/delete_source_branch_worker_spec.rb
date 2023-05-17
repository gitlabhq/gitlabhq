# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::DeleteSourceBranchWorker, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, author: user) }

  let(:sha) { merge_request.source_branch_sha }
  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      allow_next_instance_of(::Projects::DeleteBranchWorker) do |instance|
        allow(instance).to receive(:perform).with(
          merge_request.source_project.id,
          user.id,
          merge_request.source_branch
        )
      end
    end

    context 'with a non-existing merge request' do
      it 'does nothing' do
        expect(::Projects::DeleteBranchWorker).not_to receive(:new)

        worker.perform(non_existing_record_id, sha, user.id)
      end
    end

    context 'with a non-existing user' do
      it 'does nothing' do
        expect(::Projects::DeleteBranchWorker).not_to receive(:new)

        worker.perform(merge_request.id, sha, non_existing_record_id)
      end
    end

    context 'with existing user and merge request' do
      it 'calls delete branch worker' do
        expect_next_instance_of(::Projects::DeleteBranchWorker) do |instance|
          expect(instance).to receive(:perform).with(
            merge_request.source_project.id,
            user.id,
            merge_request.source_branch
          )
        end

        worker.perform(merge_request.id, sha, user.id)
      end

      context 'source branch sha does not match' do
        it 'does nothing' do
          expect(::Projects::DeleteBranchWorker).not_to receive(:new)

          worker.perform(merge_request.id, 'new-source-branch-sha', user.id)
        end
      end

      context 'when delete worker raises an error' do
        it 'still retargets the merge request' do
          expect(::Projects::DeleteBranchWorker).to receive(:new).and_raise(StandardError)

          expect_next_instance_of(::MergeRequests::RetargetChainService) do |instance|
            expect(instance).to receive(:execute).with(merge_request)
          end

          expect { worker.perform(merge_request.id, sha, user.id) }.to raise_error(StandardError)
        end
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [merge_request.id, sha, user.id] }
      end
    end
  end
end
