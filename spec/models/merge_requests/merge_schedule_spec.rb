# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeSchedule, feature_category: :code_review_workflow do
  subject { create(:merge_request_merge_schedule) }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request).required }
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
