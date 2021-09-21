# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents::PlanStageStart do
  let(:subject) { described_class.new({}) }
  let(:project) { create(:project) }

  it_behaves_like 'value stream analytics event'

  it 'filters issues where first_associated_with_milestone_at or first_added_to_board_at is filled' do
    issue1 = create(:issue, project: project)
    issue1.metrics.update!(first_added_to_board_at: 1.month.ago, first_mentioned_in_commit_at: 2.months.ago)

    issue2 = create(:issue, project: project)
    issue2.metrics.update!(first_associated_with_milestone_at: 1.month.ago, first_mentioned_in_commit_at: 2.months.ago)

    issue_without_metrics = create(:issue, project: project)

    records = subject.apply_query_customization(Issue.all)
    expect(records).to match_array([issue1, issue2])
    expect(records).not_to include(issue_without_metrics)
  end

  it_behaves_like 'LEFT JOIN-able value stream analytics event' do
    let_it_be(:record_with_data) { create(:issue).tap { |i| i.metrics.update!(first_added_to_board_at: Time.current) } }
    let_it_be(:record_without_data) { create(:issue) }
  end
end
