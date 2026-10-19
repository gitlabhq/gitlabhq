# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ProcessScheduledMergeWorker, :sidekiq_inline, feature_category: :code_review_workflow do
  include ExclusiveLeaseHelpers

  subject(:perform) { described_class.new.perform }

  let_it_be(:user) { create(:user) }

  let!(:scheduled_mr) do
    create(:merge_request, :unique_branches, author: user, merge_user: user, auto_merge_enabled: true).tap do |mr|
      create(:merge_request_merge_schedule, merge_request: mr, merge_after: 1.minute.ago)
    end
  end

  context 'when max retry attempts reach' do
    let!(:lease) { stub_exclusive_lease_taken(described_class.name.underscore) }

    it 'raises an error' do
      expect(lease).to receive(:try_obtain).exactly(described_class::LOCK_RETRY + 1).times
      expect { perform }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
    end
  end

  context 'with merge_before filter' do
    let!(:mr_with_elapsed_merge_before) do
      create(:merge_request, :unique_branches, author: user, merge_user: user, auto_merge_enabled: true).tap do |mr|
        create(:merge_request_merge_schedule, merge_request: mr, merge_after: 2.minutes.ago, merge_before: 1.minute.ago)
      end
    end

    let!(:mr_with_nil_merge_before) do
      create(:merge_request, :unique_branches, author: user, merge_user: user, auto_merge_enabled: true).tap do |mr|
        create(:merge_request_merge_schedule, merge_request: mr, merge_after: 1.minute.ago, merge_before: nil)
      end
    end

    let!(:mr_within_merge_window) do
      create(:merge_request, :unique_branches, author: user, merge_user: user, auto_merge_enabled: true).tap do |mr|
        create(
          :merge_request_merge_schedule,
          merge_request: mr,
          merge_after: 2.minutes.ago,
          merge_before: 1.minute.from_now
        )
      end
    end

    it 'does not enqueue a merge request whose merge_before has elapsed' do
      expect(AutoMergeProcessWorker).not_to receive(:bulk_perform_in).with(
        anything, include([{ 'merge_request_id' => mr_with_elapsed_merge_before.id }])
      )

      perform
    end

    it 'enqueues a merge request with a nil merge_before' do
      expect(AutoMergeProcessWorker).to receive(:bulk_perform_in).with(
        anything, include([{ 'merge_request_id' => mr_with_nil_merge_before.id }])
      )

      perform
    end

    it 'enqueues a merge request within the merge window' do
      expect(AutoMergeProcessWorker).to receive(:bulk_perform_in).with(
        anything, include([{ 'merge_request_id' => mr_within_merge_window.id }])
      )

      perform
    end
  end

  context 'with scheduling delay' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    let!(:other_scheduled_mr) do
      create(:merge_request, :unique_branches, author: user, merge_user: user, auto_merge_enabled: true).tap do |mr|
        create(:merge_request_merge_schedule, merge_request: mr, merge_after: 1.minute.ago)
      end
    end

    it 'schedules AutoMergeProcessWorker for each batch with increasing delay', :aggregate_failures do
      expect(AutoMergeProcessWorker)
        .to receive(:bulk_perform_in)
        .with(1.second, [[{ 'merge_request_id' => scheduled_mr.id }]])
        .and_call_original

      expect(AutoMergeProcessWorker)
        .to receive(:bulk_perform_in)
        .with(7.seconds, [[{ 'merge_request_id' => other_scheduled_mr.id }]])
        .and_call_original

      perform
    end
  end
end
