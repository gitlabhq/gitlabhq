# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePlacementWorker do
  describe '#perform' do
    let_it_be(:time) { Time.now.utc }
    let_it_be(:project) { create(:project) }
    let_it_be(:author) { create(:user) }
    let_it_be(:common_attrs) { { author: author, project: project } }
    let_it_be(:unplaced) { common_attrs.merge(relative_position: nil) }
    let_it_be(:issue) { create(:issue, **unplaced, created_at: time) }
    let_it_be(:issue_a) { create(:issue, **unplaced, created_at: time - 1.minute) }
    let_it_be(:issue_b) { create(:issue, **unplaced, created_at: time - 2.minutes) }
    let_it_be(:issue_c) { create(:issue, **unplaced, created_at: time + 1.minute) }
    let_it_be(:issue_d) { create(:issue, **unplaced, created_at: time + 2.minutes) }
    let_it_be(:issue_e) { create(:issue, **common_attrs, relative_position: 10, created_at: time + 1.minute) }
    let_it_be(:issue_f) { create(:issue, **unplaced, created_at: time + 1.minute) }

    let_it_be(:irrelevant) { create(:issue, relative_position: nil, created_at: time) }

    it 'places all issues created at most 5 minutes before this one at the end, most recent last' do
      expect do
        described_class.new.perform(issue.id)
      end.not_to change { irrelevant.reset.relative_position }

      expect(project.issues.order_relative_position_asc)
        .to eq([issue_e, issue_b, issue_a, issue, issue_c, issue_f, issue_d])
      expect(project.issues.where(relative_position: nil)).not_to exist
    end

    it 'schedules rebalancing if needed' do
      issue_a.update!(relative_position: RelativePositioning::MAX_POSITION)

      expect(IssueRebalancingWorker).to receive(:perform_async).with(nil, project.id)

      described_class.new.perform(issue.id)
    end

    it 'limits the sweep to QUERY_LIMIT records' do
      # Ensure there are more than N issues in this set
      n = described_class::QUERY_LIMIT
      create_list(:issue, n - 5, **unplaced)

      expect(Issue).to receive(:move_nulls_to_end).with(have_attributes(count: n)).and_call_original

      described_class.new.perform(issue.id)

      expect(project.issues.where(relative_position: nil)).to exist
    end

    it 'anticipates the failure to find the issue' do
      id = non_existing_record_id

      expect { described_class.new.perform(id) }.not_to raise_error
    end

    it 'anticipates the failure to place the issues, and schedules rebalancing' do
      allow(Issue).to receive(:move_nulls_to_end) { raise RelativePositioning::NoSpaceLeft }

      expect(IssueRebalancingWorker).to receive(:perform_async).with(nil, project.id)
      expect(Gitlab::ErrorTracking)
        .to receive(:log_exception)
        .with(RelativePositioning::NoSpaceLeft, issue_id: issue.id)

      described_class.new.perform(issue.id)
    end
  end
end
