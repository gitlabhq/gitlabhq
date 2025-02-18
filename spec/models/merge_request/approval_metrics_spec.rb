# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::ApprovalMetrics, feature_category: :code_review_workflow do
  describe 'associations' do
    it { is_expected.to belong_to(:merge_request).required }
    it { is_expected.to belong_to(:target_project).class_name('Project').inverse_of(:merge_requests).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:last_approved_at) }
  end

  describe '.refresh_last_approved_at' do
    let(:merge_request) { create(:merge_request) }

    it 'creates a new record if it does not exist' do
      expect do
        described_class.refresh_last_approved_at(
          merge_request: merge_request,
          last_approved_at: Time.current
        )
      end.to change { described_class.count }.by(1)
    end

    it 'updates an existing record if it exists' do
      existing_metrics = create(:merge_request_approval_metrics, merge_request: merge_request)
      new_timestamp = Time.current

      described_class.refresh_last_approved_at(
        merge_request: merge_request,
        last_approved_at: new_timestamp
      )

      existing_metrics.reload
      expect(existing_metrics.last_approved_at).to be_within(1.second).of(new_timestamp)
    end

    it 'sets the last_approved_at to the expected time', :freeze_time do
      described_class.refresh_last_approved_at(
        merge_request: merge_request,
        last_approved_at: Time.current
      )

      metrics = described_class.find_by!(merge_request_id: merge_request.id)
      expect(metrics.last_approved_at).to be_within(1.second).of(Time.current)
    end

    it 'does not update last_approved_at if the new timestamp is older' do
      newer_timestamp = 2.days.from_now
      older_timestamp = 1.day.from_now

      existing_metrics = create(
        :merge_request_approval_metrics,
        merge_request: merge_request,
        last_approved_at: newer_timestamp
      )

      described_class.refresh_last_approved_at(
        merge_request: merge_request,
        last_approved_at: older_timestamp
      )

      existing_metrics.reload
      expect(existing_metrics.last_approved_at).to be_within(1.second).of(newer_timestamp)
    end
  end
end
