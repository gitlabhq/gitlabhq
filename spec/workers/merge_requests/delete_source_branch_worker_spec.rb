# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::DeleteSourceBranchWorker do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, author: user) }

  let(:sha) { merge_request.source_branch_sha }
  let(:worker) { described_class.new }

  describe '#perform' do
    before do
      allow_next_instance_of(::Projects::DeleteBranchWorker) do |instance|
        allow(instance).to receive(:perform).with(merge_request.source_project.id, user.id,
                                                   merge_request.source_branch)
      end
    end

    context 'when the add_delete_branch_worker feature flag is enabled' do
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
        it 'creates a new delete branch worker async' do
          expect_next_instance_of(::Projects::DeleteBranchWorker) do |instance|
            expect(instance).to receive(:perform).with(merge_request.source_project.id, user.id,
                                                       merge_request.source_branch)
          end

          worker.perform(merge_request.id, sha, user.id)
        end

        context 'source branch sha does not match' do
          it 'does nothing' do
            expect(::Projects::DeleteBranchWorker).not_to receive(:new)

            worker.perform(merge_request.id, 'new-source-branch-sha', user.id)
          end
        end
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [merge_request.id, sha, user.id] }
      end
    end

    context 'when the add_delete_branch_worker feature flag is disabled' do
      before do
        stub_feature_flags(add_delete_branch_worker: false)
      end

      context 'with a non-existing merge request' do
        it 'does nothing' do
          expect(::Branches::DeleteService).not_to receive(:new)
          expect(::MergeRequests::RetargetChainService).not_to receive(:new)

          worker.perform(non_existing_record_id, sha, user.id)
        end
      end

      context 'with a non-existing user' do
        it 'does nothing' do
          expect(::Branches::DeleteService).not_to receive(:new)
          expect(::MergeRequests::RetargetChainService).not_to receive(:new)

          worker.perform(merge_request.id, sha, non_existing_record_id)
        end
      end

      context 'with existing user and merge request' do
        it 'calls service to delete source branch' do
          expect_next_instance_of(::Branches::DeleteService) do |instance|
            expect(instance).to receive(:execute).with(merge_request.source_branch)
          end

          worker.perform(merge_request.id, sha, user.id)
        end

        it 'calls service to try retarget merge requests' do
          expect_next_instance_of(::MergeRequests::RetargetChainService) do |instance|
            expect(instance).to receive(:execute).with(merge_request)
          end

          worker.perform(merge_request.id, sha, user.id)
        end

        context 'source branch sha does not match' do
          it 'does nothing' do
            expect(::Branches::DeleteService).not_to receive(:new)
            expect(::MergeRequests::RetargetChainService).not_to receive(:new)

            worker.perform(merge_request.id, 'new-source-branch-sha', user.id)
          end
        end

        context 'when delete service returns an error' do
          let(:service_result) { ServiceResponse.error(message: 'placeholder') }

          it 'still retargets the merge request' do
            expect_next_instance_of(::Branches::DeleteService) do |instance|
              expect(instance).to receive(:execute).with(merge_request.source_branch).and_return(service_result)
            end

            expect_next_instance_of(::MergeRequests::RetargetChainService) do |instance|
              expect(instance).to receive(:execute).with(merge_request)
            end

            worker.perform(merge_request.id, sha, user.id)
          end
        end
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { [merge_request.id, sha, user.id] }
      end
    end
  end
end
