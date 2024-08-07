# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StuckMergeJobsWorker, feature_category: :code_review_workflow do
  describe 'perform' do
    let(:worker) { described_class.new }

    it 'calls MergeRequests::UnstickLockedMergeRequestsService#execute' do
      expect_next_instance_of(MergeRequests::UnstickLockedMergeRequestsService) do |svc|
        expect(svc).to receive(:execute)
      end

      worker.perform
    end

    context 'when unstick_locked_merge_requests_redis is disabled' do
      before do
        stub_feature_flags(unstick_locked_merge_requests_redis: false)
      end

      context 'merge job identified as completed' do
        it 'updates merge request to merged when locked but has merge_commit_sha' do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return(%w[123 456])
          mr_with_sha = create(:merge_request, :locked, merge_jid: '123', state: :locked, merge_commit_sha: 'foo-bar-baz')
          mr_without_sha = create(:merge_request, :locked, merge_jid: '123', state: :locked, merge_commit_sha: nil)

          worker.perform

          mr_with_sha.reload
          mr_without_sha.reload
          expect(mr_with_sha).to be_merged
          expect(mr_without_sha).to be_opened
          expect(mr_with_sha.merge_jid).to be_present
          expect(mr_without_sha.merge_jid).to be_nil
        end

        it 'updates merge request to opened when locked but has not been merged', :sidekiq_might_not_need_inline do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return(%w[123])
          merge_request = create(:merge_request, :locked, merge_jid: '123', state: :locked)
          pipeline = create(:ci_empty_pipeline, project: merge_request.project, ref: merge_request.source_branch, sha: merge_request.source_branch_sha)

          worker.perform

          merge_request.reload
          expect(merge_request).to be_opened
          expect(merge_request.head_pipeline).to eq(pipeline)
        end

        it 'logs updated stuck merge job ids and errored MRs' do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return(%w[123 456 789])

          create(:merge_request, :locked, merge_jid: '123')
          create(:merge_request, :locked, merge_jid: '456')

          broken_mr = create(:merge_request, :locked, merge_jid: '789')
          broken_mr.update_attribute(:title, '')

          expect(Gitlab::AppLogger).to receive(:info)
            .with('Updated state of locked merge jobs. JIDs: 123, 456, 789')

          expect(Gitlab::AppLogger).to receive(:info)
            .with("Errors:\nTitle can't be blank - IDS: 789|#{broken_mr.id}\n")

          worker.perform
        end
      end

      context 'merge job not identified as completed' do
        it 'does not change merge request state when job is not completed yet' do
          allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([])

          merge_request = create(:merge_request, :locked, merge_jid: '123')

          expect { worker.perform }.not_to change { merge_request.reload.state }.from('locked')
        end
      end
    end
  end
end
