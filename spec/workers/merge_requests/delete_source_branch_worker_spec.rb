# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::DeleteSourceBranchWorker, :clean_gitlab_redis_shared_state, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, author: user) }

  let(:sha) { merge_request.source_branch_sha }
  let(:worker) { described_class.new }
  let(:lease_key) do
    "#{described_class::LEASE_KEY_PREFIX}:#{merge_request.source_project_id}:#{merge_request.source_branch}"
  end

  let(:branch_deletion_lease) { Gitlab::ExclusiveLease.new(lease_key, timeout: described_class::LEASE_TIMEOUT) }

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
        expect(::MergeRequests::RetargetChainService).not_to receive(:new)
        expect(::Projects::DeleteBranchWorker).not_to receive(:new)

        worker.perform(non_existing_record_id, sha, user.id)
      end
    end

    context 'with a non-existing user' do
      it 'does nothing' do
        expect(::MergeRequests::RetargetChainService).not_to receive(:new)
        expect(::Projects::DeleteBranchWorker).not_to receive(:new)

        worker.perform(merge_request.id, sha, non_existing_record_id)
      end
    end

    it 'retargets and deletes the branch' do
      expect_next_instance_of(::MergeRequests::RetargetChainService) do |instance|
        expect(instance).to receive(:execute).with(merge_request)
      end

      expect_next_instance_of(::Projects::DeleteBranchWorker) do |instance|
        expect(instance).to receive(:perform).with(
          merge_request.source_project.id,
          user.id,
          merge_request.source_branch
        )
      end

      worker.perform(merge_request.id, sha, user.id)
    end

    it 'releases the branch deletion lease after successful deletion' do
      branch_deletion_lease.try_obtain

      worker.perform(merge_request.id, sha, user.id)

      expect(branch_deletion_lease.exists?).to be false
    end

    context 'when source branch sha does not match' do
      it 'does not retarget or delete the branch' do
        expect(::MergeRequests::RetargetChainService).not_to receive(:new)
        expect(::Projects::DeleteBranchWorker).not_to receive(:new)

        worker.perform(merge_request.id, 'new-source-branch-sha', user.id)
      end

      it 'lets the branch deletion lease expire via TTL' do
        branch_deletion_lease.try_obtain

        worker.perform(merge_request.id, 'new-source-branch-sha', user.id)

        expect(branch_deletion_lease.exists?).to be true
      end
    end

    context 'when delete worker raises an error' do
      it 'preserves the branch deletion lease so retries are protected' do
        branch_deletion_lease.try_obtain

        expect(::Projects::DeleteBranchWorker).to receive(:new).and_raise(StandardError)

        expect_next_instance_of(::MergeRequests::RetargetChainService) do |instance|
          expect(instance).to receive(:execute).with(merge_request)
        end

        expect { worker.perform(merge_request.id, sha, user.id) }.to raise_error(StandardError)

        expect(branch_deletion_lease.exists?).to be true
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [merge_request.id, sha, user.id] }
    end
  end
end
