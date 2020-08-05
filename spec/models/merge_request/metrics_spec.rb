# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::Metrics do
  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:latest_closed_by).class_name('User') }
    it { is_expected.to belong_to(:merged_by).class_name('User') }
  end

  it 'sets `target_project_id` before save' do
    merge_request = create(:merge_request)
    metrics = merge_request.metrics

    metrics.update_column(:target_project_id, nil)

    metrics.save!

    expect(metrics.target_project_id).to eq(merge_request.target_project_id)
  end
end
