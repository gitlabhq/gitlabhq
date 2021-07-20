# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestCleanupRefsWorker do
  let(:worker) { described_class.new }

  describe '#perform_work' do
    context 'when next cleanup schedule is found' do
      let(:failed_count) { 0 }
      let!(:cleanup_schedule) { create(:merge_request_cleanup_schedule, failed_count: failed_count) }

      it 'marks the cleanup schedule as completed on success' do
        stub_cleanup_service(status: :success)
        worker.perform_work

        expect(cleanup_schedule.reload).to be_completed
        expect(cleanup_schedule.completed_at).to be_present
      end

      context 'when service fails' do
        before do
          stub_cleanup_service(status: :error)
          worker.perform_work
        end

        it 'marks the cleanup schedule as unstarted and track the failure' do
          expect(cleanup_schedule.reload).to be_unstarted
          expect(cleanup_schedule.failed_count).to eq(1)
          expect(cleanup_schedule.completed_at).to be_nil
        end

        context "and cleanup schedule has already failed #{described_class::FAILURE_THRESHOLD} times" do
          let(:failed_count) { described_class::FAILURE_THRESHOLD }

          it 'marks the cleanup schedule as failed and track the failure' do
            expect(cleanup_schedule.reload).to be_failed
            expect(cleanup_schedule.failed_count).to eq(described_class::FAILURE_THRESHOLD + 1)
            expect(cleanup_schedule.completed_at).to be_nil
          end
        end
      end

      context 'when merge_request_refs_cleanup flag is disabled' do
        before do
          stub_feature_flags(merge_request_refs_cleanup: false)
        end

        it 'does nothing' do
          expect(MergeRequests::CleanupRefsService).not_to receive(:new)

          worker.perform_work
        end
      end
    end

    context 'when there is no next cleanup schedule found' do
      it 'does nothing' do
        expect(MergeRequests::CleanupRefsService).not_to receive(:new)

        worker.perform_work
      end
    end
  end

  describe '#remaining_work_count' do
    let_it_be(:unstarted) { create_list(:merge_request_cleanup_schedule, 2) }
    let_it_be(:running) { create_list(:merge_request_cleanup_schedule, 2, :running) }
    let_it_be(:completed) { create_list(:merge_request_cleanup_schedule, 2, :completed) }

    it 'returns number of scheduled and unstarted cleanup schedule records' do
      expect(worker.remaining_work_count).to eq(unstarted.count)
    end

    context 'when count exceeds max_running_jobs' do
      before do
        create_list(:merge_request_cleanup_schedule, worker.max_running_jobs)
      end

      it 'gets capped at max_running_jobs' do
        expect(worker.remaining_work_count).to eq(worker.max_running_jobs)
      end
    end
  end

  describe '#max_running_jobs' do
    it 'returns the value of MAX_RUNNING_JOBS' do
      expect(worker.max_running_jobs).to eq(described_class::MAX_RUNNING_JOBS)
    end
  end

  def stub_cleanup_service(result)
    expect_next_instance_of(MergeRequests::CleanupRefsService, cleanup_schedule.merge_request) do |svc|
      expect(svc).to receive(:execute).and_return(result)
    end
  end
end
