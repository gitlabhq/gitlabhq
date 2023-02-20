# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::CleanupSchedule, feature_category: :code_review_workflow do
  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:scheduled_at) }
  end

  describe 'state machine transitions' do
    let(:cleanup_schedule) { create(:merge_request_cleanup_schedule) }

    it 'sets status to unstarted by default' do
      expect(cleanup_schedule).to be_unstarted
    end

    describe '#run' do
      it 'sets the status to running' do
        cleanup_schedule.run

        expect(cleanup_schedule.reload).to be_running
      end

      context 'when previous status is not unstarted' do
        let(:cleanup_schedule) { create(:merge_request_cleanup_schedule, :running) }

        it 'does not change status' do
          expect { cleanup_schedule.run }.not_to change(cleanup_schedule, :status)
        end
      end
    end

    describe '#retry' do
      let(:cleanup_schedule) { create(:merge_request_cleanup_schedule, :running) }

      it 'sets the status to unstarted' do
        cleanup_schedule.retry

        expect(cleanup_schedule.reload).to be_unstarted
      end

      it 'increments failed_count' do
        expect { cleanup_schedule.retry }.to change(cleanup_schedule, :failed_count).by(1)
      end

      context 'when previous status is not running' do
        let(:cleanup_schedule) { create(:merge_request_cleanup_schedule) }

        it 'does not change status' do
          expect { cleanup_schedule.retry }.not_to change(cleanup_schedule, :status)
        end
      end
    end

    describe '#complete' do
      let(:cleanup_schedule) { create(:merge_request_cleanup_schedule, :running) }

      it 'sets the status to completed' do
        cleanup_schedule.complete

        expect(cleanup_schedule.reload).to be_completed
      end

      it 'sets the completed_at' do
        expect { cleanup_schedule.complete }.to change(cleanup_schedule, :completed_at)
      end

      context 'when previous status is not running' do
        let(:cleanup_schedule) { create(:merge_request_cleanup_schedule, :completed) }

        it 'does not change status' do
          expect { cleanup_schedule.complete }.not_to change(cleanup_schedule, :status)
        end
      end
    end

    describe '#mark_as_failed' do
      let(:cleanup_schedule) { create(:merge_request_cleanup_schedule, :running) }

      it 'sets the status to failed' do
        cleanup_schedule.mark_as_failed

        expect(cleanup_schedule.reload).to be_failed
      end

      it 'increments failed_count' do
        expect { cleanup_schedule.mark_as_failed }.to change(cleanup_schedule, :failed_count).by(1)
      end

      context 'when previous status is not running' do
        let(:cleanup_schedule) { create(:merge_request_cleanup_schedule, :failed) }

        it 'does not change status' do
          expect { cleanup_schedule.mark_as_failed }.not_to change(cleanup_schedule, :status)
        end
      end
    end
  end

  describe '.scheduled_and_unstarted' do
    let!(:cleanup_schedule_1) { create(:merge_request_cleanup_schedule, scheduled_at: 2.days.ago) }
    let!(:cleanup_schedule_2) { create(:merge_request_cleanup_schedule, scheduled_at: 1.day.ago) }
    let!(:cleanup_schedule_3) { create(:merge_request_cleanup_schedule, :completed, scheduled_at: 1.day.ago) }
    let!(:cleanup_schedule_4) { create(:merge_request_cleanup_schedule, scheduled_at: 4.days.ago) }
    let!(:cleanup_schedule_5) { create(:merge_request_cleanup_schedule, scheduled_at: 3.days.ago) }
    let!(:cleanup_schedule_6) { create(:merge_request_cleanup_schedule, scheduled_at: 1.day.from_now) }
    let!(:cleanup_schedule_7) { create(:merge_request_cleanup_schedule, :failed, scheduled_at: 5.days.ago) }

    it 'returns records that are scheduled before or on current time and unstarted (ordered by scheduled first)' do
      expect(described_class.scheduled_and_unstarted).to eq(
        [
          cleanup_schedule_2,
          cleanup_schedule_1,
          cleanup_schedule_5,
          cleanup_schedule_4
        ])
    end
  end

  describe '.stuck' do
    let!(:cleanup_schedule_1) { create(:merge_request_cleanup_schedule, updated_at: 1.day.ago) }
    let!(:cleanup_schedule_2) { create(:merge_request_cleanup_schedule, :running, updated_at: 5.hours.ago) }
    let!(:cleanup_schedule_3) { create(:merge_request_cleanup_schedule, :running, updated_at: 7.hours.ago) }
    let!(:cleanup_schedule_4) { create(:merge_request_cleanup_schedule, :completed, updated_at: 1.day.ago) }
    let!(:cleanup_schedule_5) { create(:merge_request_cleanup_schedule, :failed, updated_at: 1.day.ago) }

    it 'returns records that has been in running state for more than 6 hours' do
      expect(described_class.stuck).to match_array([cleanup_schedule_3])
    end
  end

  describe '.stuck_retry!' do
    let!(:cleanup_schedule_1) { create(:merge_request_cleanup_schedule, :running, updated_at: 5.hours.ago) }
    let!(:cleanup_schedule_2) { create(:merge_request_cleanup_schedule, :running, updated_at: 7.hours.ago) }

    it 'sets stuck records to unstarted' do
      expect { described_class.stuck_retry! }.to change { cleanup_schedule_2.reload.unstarted? }.from(false).to(true)
    end

    context 'when there are more than 5 stuck schedules' do
      before do
        create_list(:merge_request_cleanup_schedule, 5, :running, updated_at: 1.day.ago)
      end

      it 'only retries 5 stuck schedules at once' do
        expect(described_class.stuck.count).to eq 6

        described_class.stuck_retry!

        expect(described_class.stuck.count).to eq 1
      end
    end
  end

  describe '.start_next' do
    let!(:cleanup_schedule_1) { create(:merge_request_cleanup_schedule, :completed, scheduled_at: 1.day.ago) }
    let!(:cleanup_schedule_2) { create(:merge_request_cleanup_schedule, scheduled_at: 2.days.ago) }
    let!(:cleanup_schedule_3) { create(:merge_request_cleanup_schedule, :running, scheduled_at: 1.day.ago) }
    let!(:cleanup_schedule_4) { create(:merge_request_cleanup_schedule, scheduled_at: 3.days.ago) }
    let!(:cleanup_schedule_5) { create(:merge_request_cleanup_schedule, :failed, scheduled_at: 3.days.ago) }

    it 'finds the next scheduled and unstarted then marked it as running' do
      expect(described_class.start_next).to eq(cleanup_schedule_2)
      expect(cleanup_schedule_2.reload).to be_running
    end
  end
end
