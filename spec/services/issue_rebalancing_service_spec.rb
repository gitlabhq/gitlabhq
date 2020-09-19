# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueRebalancingService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.creator }
  let_it_be(:start) { RelativePositioning::START_POSITION }
  let_it_be(:max_pos) { RelativePositioning::MAX_POSITION }
  let_it_be(:min_pos) { RelativePositioning::MIN_POSITION }
  let_it_be(:clump_size) { 300 }

  let_it_be(:unclumped) do
    (0..clump_size).to_a.map do |i|
      create(:issue, project: project, author: user, relative_position: start + (1024 * i))
    end
  end

  let_it_be(:end_clump) do
    (0..clump_size).to_a.map do |i|
      create(:issue, project: project, author: user, relative_position: max_pos - i)
    end
  end

  let_it_be(:start_clump) do
    (0..clump_size).to_a.map do |i|
      create(:issue, project: project, author: user, relative_position: min_pos + i)
    end
  end

  def issues_in_position_order
    project.reload.issues.reorder(relative_position: :asc).to_a
  end

  it 'rebalances a set of issues with clumps at the end and start' do
    all_issues = start_clump + unclumped + end_clump.reverse
    service = described_class.new(project.issues.first)

    expect { service.execute }.not_to change { issues_in_position_order.map(&:id) }

    all_issues.each(&:reset)

    gaps = all_issues.take(all_issues.count - 1).zip(all_issues.drop(1)).map do |a, b|
      b.relative_position - a.relative_position
    end

    expect(gaps).to all(be > RelativePositioning::MIN_GAP)
    expect(all_issues.first.relative_position).to be > (RelativePositioning::MIN_POSITION * 0.9999)
    expect(all_issues.last.relative_position).to be < (RelativePositioning::MAX_POSITION * 0.9999)
  end

  it 'is idempotent' do
    service = described_class.new(project.issues.first)

    expect do
      service.execute
      service.execute
    end.not_to change { issues_in_position_order.map(&:id) }
  end

  it 'does nothing if the feature flag is disabled' do
    stub_feature_flags(rebalance_issues: false)
    issue = project.issues.first
    issue.project
    issue.project.group
    old_pos = issue.relative_position

    service = described_class.new(issue)

    expect { service.execute }.not_to exceed_query_limit(0)
    expect(old_pos).to eq(issue.reload.relative_position)
  end

  it 'acts if the flag is enabled for the project' do
    issue = create(:issue, project: project, author: user, relative_position: max_pos)
    stub_feature_flags(rebalance_issues: issue.project)

    service = described_class.new(issue)

    expect { service.execute }.to change { issue.reload.relative_position }
  end

  it 'acts if the flag is enabled for the group' do
    issue = create(:issue, project: project, author: user, relative_position: max_pos)
    project.update!(group: create(:group))
    stub_feature_flags(rebalance_issues: issue.project.group)

    service = described_class.new(issue)

    expect { service.execute }.to change { issue.reload.relative_position }
  end

  it 'aborts if there are too many issues' do
    issue = project.issues.first
    base = double(count: 10_001)

    allow(Issue).to receive(:relative_positioning_query_base).with(issue).and_return(base)

    expect { described_class.new(issue).execute }.to raise_error(described_class::TooManyIssues)
  end
end
