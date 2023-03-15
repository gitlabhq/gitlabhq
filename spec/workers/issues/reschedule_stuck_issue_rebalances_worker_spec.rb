# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::RescheduleStuckIssueRebalancesWorker, :clean_gitlab_redis_shared_state, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'does not schedule a rebalance' do
      expect(Issues::RebalancingWorker).not_to receive(:perform_async)

      worker.perform
    end

    it 'schedules a rebalance in case there are any rebalances started' do
      expect(::Gitlab::Issues::Rebalancing::State).to receive(:fetch_rebalancing_groups_and_projects).and_return([[group.id], [project.id]])
      expect(Issues::RebalancingWorker).to receive(:bulk_perform_async).with([[nil, nil, group.id]]).once
      expect(Issues::RebalancingWorker).to receive(:bulk_perform_async).with([[nil, project.id, nil]]).once

      worker.perform
    end
  end
end
