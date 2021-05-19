# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueRebalancingService do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user) { project.creator }
  let_it_be(:start) { RelativePositioning::START_POSITION }
  let_it_be(:max_pos) { RelativePositioning::MAX_POSITION }
  let_it_be(:min_pos) { RelativePositioning::MIN_POSITION }
  let_it_be(:clump_size) { 300 }

  let_it_be(:unclumped, reload: true) do
    (1..clump_size).to_a.map do |i|
      create(:issue, project: project, author: user, relative_position: start + (1024 * i))
    end
  end

  let_it_be(:end_clump, reload: true) do
    (1..clump_size).to_a.map do |i|
      create(:issue, project: project, author: user, relative_position: max_pos - i)
    end
  end

  let_it_be(:start_clump, reload: true) do
    (1..clump_size).to_a.map do |i|
      create(:issue, project: project, author: user, relative_position: min_pos + i)
    end
  end

  before do
    stub_feature_flags(issue_rebalancing_with_retry: false)
  end

  def issues_in_position_order
    project.reload.issues.reorder(relative_position: :asc).to_a
  end

  shared_examples 'IssueRebalancingService shared examples' do
    it 'rebalances a set of issues with clumps at the end and start' do
      all_issues = start_clump + unclumped + end_clump.reverse
      service = described_class.new(Project.id_in([project.id]))

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
      service = described_class.new(Project.id_in(project))

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

      service = described_class.new(Project.id_in(project))

      expect { service.execute }.not_to exceed_query_limit(0)
      expect(old_pos).to eq(issue.reload.relative_position)
    end

    it 'acts if the flag is enabled for the root namespace' do
      issue = create(:issue, project: project, author: user, relative_position: max_pos)
      stub_feature_flags(rebalance_issues: project.root_namespace)

      service = described_class.new(Project.id_in(project))

      expect { service.execute }.to change { issue.reload.relative_position }
    end

    it 'acts if the flag is enabled for the group' do
      issue = create(:issue, project: project, author: user, relative_position: max_pos)
      project.update!(group: create(:group))
      stub_feature_flags(rebalance_issues: issue.project.group)

      service = described_class.new(Project.id_in(project))

      expect { service.execute }.to change { issue.reload.relative_position }
    end

    it 'aborts if there are too many issues' do
      base = double(count: 10_001)

      allow(Issue).to receive(:in_projects).and_return(base)

      expect { described_class.new(Project.id_in(project)).execute }.to raise_error(described_class::TooManyIssues)
    end
  end

  shared_examples 'rebalancing is retried on statement timeout exceptions' do
    subject { described_class.new(Project.id_in(project)) }

    it 'retries update statement' do
      call_count = 0
      allow(subject).to receive(:run_update_query) do
        call_count += 1
        if call_count < 13
          raise(ActiveRecord::QueryCanceled)
        else
          call_count = 0 if call_count == 13 + 16 # 16 = 17 sub-batches - 1 call that succeeded as part of 5th batch
          true
        end
      end

      # call math:
      # batches start at 100 and are split in half after every 3 retries if ActiveRecord::StatementTimeout exception is raised.
      # We raise ActiveRecord::StatementTimeout exception for 13 calls:
      # 1. 100 => 3 calls
      # 2. 100/2=50 => 3 calls + 3 above = 6 calls, raise ActiveRecord::StatementTimeout
      # 3. 50/2=25 => 3 calls + 6 above = 9 calls, raise ActiveRecord::StatementTimeout
      # 4. 25/2=12 => 3 calls + 9 above = 12 calls, raise ActiveRecord::StatementTimeout
      # 5. 12/2=6 => 1 call + 12 above = 13 calls, run successfully
      #
      # so out of 100 elements we created batches of 6 items => 100/6 = 17 sub-batches of 6 or less elements
      #
      # project.issues.count: 900 issues, so 9 batches of 100 => 9 * (13+16) = 261
      expect(subject).to receive(:update_positions).exactly(261).times.and_call_original

      subject.execute
    end
  end

  context 'when issue_rebalancing_optimization feature flag is on' do
    before do
      stub_feature_flags(issue_rebalancing_optimization: true)
    end

    it_behaves_like 'IssueRebalancingService shared examples'

    context 'when issue_rebalancing_with_retry feature flag is on' do
      before do
        stub_feature_flags(issue_rebalancing_with_retry: true)
      end

      it_behaves_like 'IssueRebalancingService shared examples'
      it_behaves_like 'rebalancing is retried on statement timeout exceptions'
    end
  end

  context 'when issue_rebalancing_optimization feature flag is off' do
    before do
      stub_feature_flags(issue_rebalancing_optimization: false)
    end

    it_behaves_like 'IssueRebalancingService shared examples'

    context 'when issue_rebalancing_with_retry feature flag is on' do
      before do
        stub_feature_flags(issue_rebalancing_with_retry: true)
      end

      it_behaves_like 'IssueRebalancingService shared examples'
      it_behaves_like 'rebalancing is retried on statement timeout exceptions'
    end
  end
end
