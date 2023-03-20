# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::RelativePositionRebalancingService, :clean_gitlab_redis_shared_state, feature_category: :team_planning do
  let_it_be(:project, reload: true) { create(:project, :repository_disabled, skip_disk_validation: true) }
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

  let_it_be(:nil_clump, reload: true) do
    (1..100).to_a.map do |i|
      create(:issue, project: project, author: user, relative_position: nil)
    end
  end

  def issues_in_position_order
    project.reload.issues.order_by_relative_position.to_a
  end

  subject(:service) { described_class.new(Project.id_in(project)) }

  context 'execute' do
    it 're-balances a set of issues with clumps at the end and start' do
      all_issues = start_clump + unclumped + end_clump.reverse

      expect { service.execute }.not_to change { issues_in_position_order.map(&:id) }

      caching = service.send(:caching)
      all_issues.each(&:reset)

      gaps = all_issues.take(all_issues.count - 1).zip(all_issues.drop(1)).map do |a, b|
        b.relative_position - a.relative_position
      end

      expect(caching.issue_count).to eq(900)
      expect(gaps).to all(be > RelativePositioning::MIN_GAP)
      expect(all_issues.first.relative_position).to be > (RelativePositioning::MIN_POSITION * 0.9999)
      expect(all_issues.last.relative_position).to be < (RelativePositioning::MAX_POSITION * 0.9999)
      expect(project.root_namespace.issue_repositioning_disabled?).to be false
      expect(project.issues.with_null_relative_position.count).to eq(100)
    end

    it 'is idempotent' do
      expect do
        service.execute
        service.execute
      end.not_to change { issues_in_position_order.map(&:id) }
    end

    it 'acts if the flag is enabled for the root namespace' do
      issue = create(:issue, project: project, author: user, relative_position: max_pos)

      expect { service.execute }.to change { issue.reload.relative_position }
    end

    it 'acts if the flag is enabled for the group' do
      issue = create(:issue, project: project, author: user, relative_position: max_pos)
      project.update!(group: create(:group))

      expect { service.execute }.to change { issue.reload.relative_position }
    end

    it 'aborts if there are too many rebalances running' do
      caching = service.send(:caching)
      allow(caching).to receive(:rebalance_in_progress?).and_return(false)
      allow(caching).to receive(:concurrent_running_rebalances_count).and_return(10)
      allow(service).to receive(:caching).and_return(caching)

      expect { service.execute }.to raise_error(Issues::RelativePositionRebalancingService::TooManyConcurrentRebalances)
      expect(project.root_namespace.issue_repositioning_disabled?).to be false
    end

    it 'resumes a started rebalance even if there are already too many rebalances running' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.sadd("gitlab:issues-position-rebalances:running_rebalances",
          [
            "#{::Gitlab::Issues::Rebalancing::State::PROJECT}/#{project.id}",
            "1/100"
          ]
        )
      end

      caching = service.send(:caching)
      allow(caching).to receive(:concurrent_running_rebalances_count).and_return(10)
      allow(service).to receive(:caching).and_return(caching)

      expect { service.execute }.not_to raise_error
    end

    context 're-balancing is retried on statement timeout exceptions' do
      subject { service }

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

    context 'when resuming a stopped rebalance' do
      before do
        service.send(:preload_issue_ids)
        expect(service.send(:caching).get_cached_issue_ids(0, 300)).not_to be_empty
        # simulate we already rebalanced half the issues
        index = clump_size * 3 / 2 + 1
        service.send(:caching).cache_current_index(index)
      end

      it 'rebalances the other half of issues' do
        expect(subject).to receive(:update_positions_with_retry).exactly(5).and_call_original

        subject.execute
      end
    end
  end
end
