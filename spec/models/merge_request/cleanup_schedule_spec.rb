# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::CleanupSchedule do
  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:scheduled_at) }
  end

  describe '.scheduled_merge_request_ids' do
    let_it_be(:mr_cleanup_schedule_1) { create(:merge_request_cleanup_schedule, scheduled_at: 2.days.ago) }
    let_it_be(:mr_cleanup_schedule_2) { create(:merge_request_cleanup_schedule, scheduled_at: 1.day.ago) }
    let_it_be(:mr_cleanup_schedule_3) { create(:merge_request_cleanup_schedule, scheduled_at: 1.day.ago, completed_at: Time.current) }
    let_it_be(:mr_cleanup_schedule_4) { create(:merge_request_cleanup_schedule, scheduled_at: 4.days.ago) }
    let_it_be(:mr_cleanup_schedule_5) { create(:merge_request_cleanup_schedule, scheduled_at: 3.days.ago) }
    let_it_be(:mr_cleanup_schedule_6) { create(:merge_request_cleanup_schedule, scheduled_at: 1.day.from_now) }
    let_it_be(:mr_cleanup_schedule_7) { create(:merge_request_cleanup_schedule, scheduled_at: 5.days.ago) }

    it 'only includes incomplete schedule within the specified limit' do
      expect(described_class.scheduled_merge_request_ids(4)).to eq([
        mr_cleanup_schedule_2.merge_request_id,
        mr_cleanup_schedule_1.merge_request_id,
        mr_cleanup_schedule_5.merge_request_id,
        mr_cleanup_schedule_4.merge_request_id
      ])
    end
  end
end
