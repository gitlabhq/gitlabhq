# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeSchedule, feature_category: :code_review_workflow do
  subject { create(:merge_request_merge_schedule) }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:merge_after) }

    describe '#validate_time_range' do
      let(:now) { Time.current }

      it 'is valid when only merge_after is set' do
        schedule = build(:merge_request_merge_schedule, merge_after: now + 1.hour, merge_before: nil)
        expect(schedule).to be_valid
      end

      it 'is valid when merge_after is before merge_before' do
        schedule = build(:merge_request_merge_schedule, merge_after: now + 1.hour, merge_before: now + 2.hours)
        expect(schedule).to be_valid
      end

      it 'is invalid when merge_after is after merge_before' do
        schedule = build(:merge_request_merge_schedule, merge_after: now + 2.hours, merge_before: now + 1.hour)
        expect(schedule).to be_invalid
        expect(schedule.errors[:merge_before]).to include(_('must be after the start time'))
      end

      it 'is invalid when merge_after equals merge_before' do
        schedule = build(:merge_request_merge_schedule, merge_after: now + 1.hour, merge_before: now + 1.hour)
        expect(schedule).to be_invalid
        expect(schedule.errors[:merge_before]).to include(_('must be after the start time'))
      end
    end
  end

  describe 'callbacks' do
    let(:merge_request) { create(:merge_request) }
    let(:schedule) do
      create(:merge_request_merge_schedule, merge_request: merge_request,
        project_id: merge_request.target_project.id + 1)
    end

    it 'overrides project_id to the correct sharding key' do
      expect(schedule.project_id).to eq(merge_request.target_project.id)
    end
  end
end
