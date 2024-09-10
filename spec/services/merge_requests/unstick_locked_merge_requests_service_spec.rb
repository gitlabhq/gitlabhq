# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UnstickLockedMergeRequestsService, :clean_gitlab_redis_shared_state, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let(:service) { described_class.new }

  describe '#execute' do
    context 'when merge job identified as completed' do
      it 'updates merge request to merged when locked but has merge_commit_sha' do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return(%w[123 456])
        mr_with_sha = create(
          :merge_request,
          :locked,
          source_project: project,
          merge_jid: '123',
          state: :locked,
          merge_commit_sha: 'foo-bar-baz'
        )

        mr_without_sha = create(
          :merge_request,
          :locked,
          source_project: project,
          merge_jid: '123',
          state: :locked,
          merge_commit_sha: nil
        )

        mr_with_sha.add_to_locked_set
        mr_without_sha.add_to_locked_set

        service.execute

        mr_with_sha.reload
        mr_without_sha.reload
        expect(mr_with_sha).to be_merged
        expect(mr_without_sha).to be_opened
        expect(mr_with_sha.merge_jid).to be_present
        expect(mr_without_sha.merge_jid).to be_nil
        expect(Gitlab::MergeRequests::LockedSet.all).to be_empty
      end

      it 'updates merge request to opened when locked but has not been merged', :sidekiq_might_not_need_inline do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return(%w[123])

        merge_request = create(
          :merge_request,
          :locked,
          source_project: project,
          merge_jid: '123',
          state: :locked
        )

        pipeline = create(
          :ci_empty_pipeline,
          project: merge_request.project,
          ref: merge_request.source_branch,
          sha: merge_request.source_branch_sha
        )

        merge_request.add_to_locked_set

        service.execute

        merge_request.reload
        expect(merge_request).to be_opened
        expect(merge_request.head_pipeline).to eq(pipeline)
      end

      it 'logs updated stuck merge job ids and errored MRs' do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return(%w[123 456 789])

        mr_1 = create(
          :merge_request,
          :locked,
          source_project: project,
          merge_jid: '123',
          source_branch: 'add_images_and_changes'
        )

        mr_2 = create(
          :merge_request,
          :locked,
          source_project: project,
          merge_jid: '456',
          source_branch: 'feature_conflict'
        )

        broken_mr = create(:merge_request, :locked, source_project: project, merge_jid: '789')
        broken_mr.update_attribute(:title, '')

        mr_1.add_to_locked_set
        mr_2.add_to_locked_set
        broken_mr.add_to_locked_set

        expect(Gitlab::AppLogger).to receive(:info)
          .with('Updated state of locked merge jobs. JIDs: 123, 456, 789')

        expect(Gitlab::AppLogger).to receive(:info)
          .with("Errors:\nTitle can't be blank - IDS: 789|#{broken_mr.id}\n")

        service.execute

        expect(Gitlab::MergeRequests::LockedSet.all).to eq([broken_mr.id.to_s])
      end
    end

    context 'when merge job not identified as completed' do
      it 'does not change merge request state when job is not completed yet' do
        allow(Gitlab::SidekiqStatus).to receive(:completed_jids).and_return([])

        merge_request = create(:merge_request, :locked, source_project: project, merge_jid: '123')
        merge_request.add_to_locked_set

        expect { service.execute }.not_to change { merge_request.reload.state }.from('locked')
        expect(Gitlab::MergeRequests::LockedSet.all).not_to be_empty
      end
    end

    context 'when MR is not locked but in locked set' do
      let(:merge_request) { create(:merge_request, source_project: project) }

      it 'gets removed from locked set' do
        merge_request.add_to_locked_set

        service.execute

        expect(Gitlab::MergeRequests::LockedSet.all).to be_empty
      end
    end

    context 'when MR has no merge_jid' do
      let(:merge_request) do
        create(
          :merge_request,
          :locked,
          source_project: project,
          state: :locked,
          merge_jid: nil
        )
      end

      it 'unlocks the MR' do
        merge_request.add_to_locked_set

        expect { service.execute }
          .to change { merge_request.reload.state }
          .from('locked')
          .to('opened')
        expect(Gitlab::MergeRequests::LockedSet.all).to be_empty
      end

      it 'logs updated stuck merge job ids and errored MRs',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/477967' do
        mr_1 = create(
          :merge_request,
          :locked,
          source_project: project,
          merge_jid: nil,
          source_branch: 'add_images_and_changes'
        )

        mr_2 = create(
          :merge_request,
          :locked,
          source_project: project,
          merge_jid: nil,
          source_branch: 'feature_conflict'
        )

        broken_mr = create(:merge_request, :locked, source_project: project, merge_jid: nil)
        broken_mr.update_attribute(:title, '')

        mr_1.add_to_locked_set
        mr_2.add_to_locked_set
        broken_mr.add_to_locked_set

        expect(Gitlab::AppLogger).to receive(:info)
          .with("Updated state of locked MRs without JIDs. IDs: #{mr_1.id}, #{mr_2.id}, #{broken_mr.id}")

        expect(Gitlab::AppLogger).to receive(:info)
          .with("Errors:\nTitle can't be blank - IDS: #{broken_mr.id}\n")

        service.execute

        expect(Gitlab::MergeRequests::LockedSet.all).to eq([broken_mr.id.to_s])
      end

      context 'when unstick_locked_mrs_without_merge_jid feature flag is disabled' do
        before do
          stub_feature_flags(unstick_locked_mrs_without_merge_jid: false)
        end

        it 'does not do anything' do
          merge_request.add_to_locked_set

          expect { service.execute }
            .not_to change { merge_request.reload.state }
            .from('locked')
          expect(Gitlab::MergeRequests::LockedSet.all).not_to be_empty
        end
      end

      context 'when there is merge exclusive lease' do
        before do
          merge_request.merge_exclusive_lease.try_obtain
          merge_request.add_to_locked_set
        end

        it 'does not do anything' do
          expect { service.execute }
            .not_to change { merge_request.reload.state }
            .from('locked')
          expect(Gitlab::MergeRequests::LockedSet.all).not_to be_empty
        end
      end

      context 'when MR changes were merged' do
        shared_examples_for 'unsticks merged MR' do
          it 'marks the MR as merged' do
            expect { service.execute }
              .to change { merge_request.reload.state }
              .from('locked')
              .to('merged')
          end

          context 'when there is merge exclusive lease' do
            before do
              merge_request.merge_exclusive_lease.try_obtain
            end

            it 'does not do anything' do
              expect { service.execute }
                .not_to change { merge_request.reload.state }
                .from('locked')
              expect(Gitlab::MergeRequests::LockedSet.all).not_to be_empty
            end
          end
        end

        context 'when merged_commit_sha is set' do
          before do
            merge_request.update!(merged_commit_sha: 'abc123')
            merge_request.add_to_locked_set
          end

          it_behaves_like 'unsticks merged MR'
        end

        context 'when only merge_commit_sha is set' do
          before do
            merge_request.update!(merge_commit_sha: 'abc123')
            merge_request.add_to_locked_set
          end

          it_behaves_like 'unsticks merged MR'
        end

        context 'when merged_commit_sha and merge_commit_sha is not set' do
          before do
            merge_request.add_to_locked_set
          end

          context 'and source_branch_sha is nil' do
            before do
              allow_next_found_instance_of(MergeRequest) do |mr|
                allow(mr).to receive(:source_branch_sha).and_return(nil)
              end
            end

            it 'unlocks the MR' do
              expect { service.execute }
                .to change { merge_request.reload.state }
                .from('locked')
                .to('opened')
              expect(Gitlab::MergeRequests::LockedSet.all).to be_empty
            end
          end

          context 'and target_branch_sha is nil' do
            before do
              allow_next_found_instance_of(MergeRequest) do |mr|
                allow(mr).to receive(:target_branch_sha).and_return(nil)
              end
            end

            it 'unlocks the MR' do
              expect { service.execute }
                .to change { merge_request.reload.state }
                .from('locked')
                .to('opened')
              expect(Gitlab::MergeRequests::LockedSet.all).to be_empty
            end
          end

          context 'and MR has no diffs anymore' do
            before do
              allow_next_found_instance_of(MergeRequest) do |mr|
                allow(mr).to receive(:has_diffs?).and_return(false)
              end
            end

            it_behaves_like 'unsticks merged MR'
          end
        end
      end
    end
  end
end
