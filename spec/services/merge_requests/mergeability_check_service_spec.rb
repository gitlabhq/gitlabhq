# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeabilityCheckService, :clean_gitlab_redis_shared_state do
  shared_examples_for 'unmergeable merge request' do
    it 'updates or keeps merge status as cannot_be_merged' do
      subject

      expect(merge_request.merge_status).to eq('cannot_be_merged')
    end

    it 'does not change the merge ref HEAD' do
      merge_ref_head = merge_request.merge_ref_head

      subject

      expect(merge_request.reload.merge_ref_head).to eq merge_ref_head
    end

    it 'returns ServiceResponse.error' do
      result = subject

      expect(result).to be_a(ServiceResponse)
      expect(result).to be_error
    end
  end

  shared_examples_for 'mergeable merge request' do
    it 'updates or keeps merge status as can_be_merged' do
      subject

      expect(merge_request.merge_status).to eq('can_be_merged')
    end

    it 'reloads merge head diff' do
      expect_next_instance_of(MergeRequests::ReloadMergeHeadDiffService) do |service|
        expect(service).to receive(:execute)
      end

      subject
    end

    it 'update diff discussion positions' do
      expect_next_instance_of(Discussions::CaptureDiffNotePositionsService) do |service|
        expect(service).to receive(:execute)
      end

      subject
    end

    it 'updates the merge ref' do
      expect { subject }.to change(merge_request, :merge_ref_head).from(nil)
    end

    it 'returns ServiceResponse.success' do
      result = subject

      expect(result).to be_a(ServiceResponse)
      expect(result).to be_success
    end

    it 'ServiceResponse has merge_ref_head payload' do
      result = subject

      expect(result.payload.keys).to contain_exactly(:merge_ref_head)
      expect(result.payload[:merge_ref_head].keys)
        .to contain_exactly(:commit_id, :target_id, :source_id)
    end
  end

  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, merge_status: :unchecked, source_project: project, target_project: project) }

  describe '#async_execute' do
    shared_examples_for 'no job is enqueued' do
      it 'does not enqueue MergeRequestMergeabilityCheckWorker' do
        expect(MergeRequestMergeabilityCheckWorker).not_to receive(:perform_async)

        described_class.new(merge_request).async_execute
      end
    end

    it 'enqueues MergeRequestMergeabilityCheckWorker' do
      expect(MergeRequestMergeabilityCheckWorker).to receive(:perform_async)

      described_class.new(merge_request).async_execute
    end

    context 'when read-only DB' do
      before do
        allow(Gitlab::Database.main).to receive(:read_only?) { true }
      end

      it_behaves_like 'no job is enqueued'
    end

    context 'when merge_status is already checking' do
      before do
        merge_request.mark_as_checking
      end

      it_behaves_like 'no job is enqueued'
    end
  end

  describe '#execute' do
    let(:repo) { project.repository }

    subject { described_class.new(merge_request).execute }

    def execute_within_threads(amount:, retry_lease: true)
      threads = []

      amount.times do
        # Let's use a different object for each thread to get closer
        # to a real world scenario.
        mr = MergeRequest.find(merge_request.id)

        threads << Thread.new do
          described_class.new(mr).execute(retry_lease: retry_lease)
        end
      end

      threads.each(&:join)
      threads
    end

    before do
      project.add_developer(merge_request.author)
    end

    it_behaves_like 'mergeable merge request'

    context 'when concurrent calls' do
      it 'waits first lock and returns "cached" result in subsequent calls' do
        threads = execute_within_threads(amount: 3)
        results = threads.map { |t| t.value.status }

        expect(results).to contain_exactly(:success, :success, :success)
      end

      it 'writes the merge-ref once' do
        service = instance_double(MergeRequests::MergeToRefService)

        expect(MergeRequests::MergeToRefService).to receive(:new).once { service }
        expect(service).to receive(:execute).once.and_return(success: true)

        execute_within_threads(amount: 3)
      end

      it 'resets one merge request upon execution' do
        expect_next_instance_of(MergeRequests::ReloadMergeHeadDiffService) do |svc|
          expect(svc).to receive(:execute).and_return(status: :success)
        end

        expect_any_instance_of(MergeRequest).to receive(:reset).once.and_call_original

        execute_within_threads(amount: 2)
      end

      context 'when retry_lease flag is false' do
        it 'the first call succeeds, subsequent concurrent calls get a lock error response' do
          threads = execute_within_threads(amount: 3, retry_lease: false)
          results = threads.map { |t| [t.value.status, t.value.message] }

          expect(results).to contain_exactly([:error, 'Failed to obtain a lock'],
                                             [:error, 'Failed to obtain a lock'],
                                             [:success, nil])
        end
      end
    end

    context 'when broken' do
      before do
        expect(merge_request).to receive(:broken?) { true }
      end

      it_behaves_like 'unmergeable merge request'

      it 'returns ServiceResponse.error' do
        result = subject

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq('Merge request is not mergeable')
      end
    end

    context 'when it cannot be merged on git' do
      let(:merge_request) do
        create(:merge_request,
               merge_status: :unchecked,
               source_branch: 'conflict-resolvable',
               source_project: project,
               target_branch: 'conflict-start')
      end

      it 'does not change the merge ref HEAD' do
        expect(merge_request.merge_ref_head).to be_nil

        subject

        expect(merge_request.reload.merge_ref_head).not_to be_nil
      end

      it 'returns ServiceResponse.error and keeps merge status as cannot_be_merged' do
        result = subject

        expect(merge_request.merge_status).to eq('cannot_be_merged')
        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq('Merge request is not mergeable')
      end
    end

    context 'when MR cannot be merged and has no merge ref' do
      before do
        merge_request.mark_as_unmergeable!
      end

      it_behaves_like 'unmergeable merge request'

      it 'returns ServiceResponse.error' do
        result = subject

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq('Merge request is not mergeable')
      end
    end

    context 'when MR cannot be merged and has outdated merge ref' do
      before do
        MergeRequests::MergeToRefService.new(project: project, current_user: merge_request.author).execute(merge_request)
        merge_request.mark_as_unmergeable!
      end

      it_behaves_like 'unmergeable merge request'

      it 'returns ServiceResponse.error' do
        result = subject

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq('Merge request is not mergeable')
      end
    end

    context 'when merge request is not given' do
      subject { described_class.new(nil).execute }

      it 'returns ServiceResponse.error' do
        result = subject

        expect(result).to be_a(ServiceResponse)
        expect(result.message).to eq('Invalid argument')
      end
    end

    context 'when read-only DB' do
      it 'returns ServiceResponse.error' do
        allow(Gitlab::Database.main).to receive(:read_only?) { true }

        result = subject

        expect(result).to be_a(ServiceResponse)
        expect(result.message).to eq('Unsupported operation')
      end
    end

    context 'when fails to update the merge-ref' do
      before do
        expect_next_instance_of(MergeRequests::MergeToRefService) do |merge_to_ref|
          expect(merge_to_ref).to receive(:execute).and_return(status: :failed)
        end
      end

      it_behaves_like 'unmergeable merge request'

      it 'reloads merge head diff' do
        expect_next_instance_of(MergeRequests::ReloadMergeHeadDiffService) do |service|
          expect(service).to receive(:execute)
        end

        subject
      end

      it 'returns ServiceResponse.error' do
        result = subject

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq('Merge request is not mergeable')
      end
    end

    context 'recheck enforced' do
      subject { described_class.new(merge_request).execute(recheck: true) }

      context 'when MR is marked as mergeable, but repo is not mergeable and MR is not opened' do
        before do
          # Making sure that we don't touch the merge-status after
          # the MR is not opened any longer. Source branch might
          # have been removed, etc.
          allow(merge_request).to receive(:broken?) { true }
          merge_request.mark_as_mergeable!
          merge_request.close!
        end

        it 'returns ServiceResponse.error' do
          result = subject

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to eq('Merge ref cannot be updated')
          expect(result.payload).to be_empty
        end

        it 'does not change the merge status' do
          expect { subject }.not_to change(merge_request, :merge_status).from('can_be_merged')
        end
      end

      context 'when MR is mergeable but merge-ref does not exists' do
        before do
          merge_request.mark_as_mergeable!
        end

        it_behaves_like 'mergeable merge request'
      end

      context 'when MR is mergeable but merge-ref is already updated' do
        before do
          MergeRequests::MergeToRefService.new(project: project, current_user: merge_request.author).execute(merge_request)
          merge_request.mark_as_mergeable!
        end

        it 'returns ServiceResponse.success' do
          result = subject

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_success
          expect(result.payload[:merge_ref_head]).to be_present
        end

        it 'does not recreate the merge-ref' do
          expect(MergeRequests::MergeToRefService).not_to receive(:new)

          subject
        end

        it 'does not reload merge head diff' do
          expect(MergeRequests::ReloadMergeHeadDiffService).not_to receive(:new)

          subject
        end
      end
    end

    context 'merge with conflicts' do
      it 'calls MergeToRefService with true allow_conflicts param' do
        expect(MergeRequests::MergeToRefService).to receive(:new)
          .with(project: project, current_user: merge_request.author, params: { allow_conflicts: true }).and_call_original

        subject
      end

      context 'when display_merge_conflicts_in_diff is disabled' do
        before do
          stub_feature_flags(display_merge_conflicts_in_diff: false)
        end

        it 'calls MergeToRefService with false allow_conflicts param' do
          expect(MergeRequests::MergeToRefService).to receive(:new)
            .with(project: project, current_user: merge_request.author, params: { allow_conflicts: false }).and_call_original

          subject
        end
      end
    end
  end
end
