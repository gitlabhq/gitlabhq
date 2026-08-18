# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Queue::PendingBuildsStrategy, feature_category: :continuous_integration do
  let_it_be(:group) { create(:group) }
  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let_it_be(:build_1) { create(:ci_build, :created, pipeline: pipeline) }
  let_it_be(:build_2) { create(:ci_build, :created, pipeline: pipeline) }
  let_it_be(:build_3) { create(:ci_build, :created, pipeline: pipeline) }
  let_it_be(:pending_build_1) { create(:ci_pending_build, build: build_2, project: project) }
  let_it_be(:pending_build_2) { create(:ci_pending_build, build: build_3, project: project) }
  let_it_be(:pending_build_3) { create(:ci_pending_build, build: build_1, project: project) }

  describe 'builds_for_group_runner' do
    it 'returns builds ordered by build ID' do
      strategy = described_class.new(group_runner)
      expect(strategy.builds_for_group_runner).to eq([pending_build_3, pending_build_1, pending_build_2])
    end
  end

  describe 'build_and_partition_ids' do
    it 'returns build id with partition id' do
      strategy = described_class.new(group_runner)
      relation = strategy.builds_for_group_runner
      expect(strategy.build_and_partition_ids(relation)).to match_array(
        [
          [pending_build_3.build_id, pending_build_3.partition_id],
          [pending_build_1.build_id, pending_build_1.partition_id],
          [pending_build_2.build_id, pending_build_2.partition_id]
        ]
      )
    end
  end

  describe 'build_partition_and_project_ids' do
    it 'returns build id with partition id and project id' do
      strategy = described_class.new(group_runner)
      relation = strategy.builds_for_group_runner
      expect(strategy.build_partition_and_project_ids(relation)).to match_array(
        [
          [pending_build_3.build_id, pending_build_3.partition_id, pending_build_3.project_id],
          [pending_build_1.build_id, pending_build_1.partition_id, pending_build_1.project_id],
          [pending_build_2.build_id, pending_build_2.partition_id, pending_build_2.project_id]
        ]
      )
    end
  end

  describe 'builds_for_runner_manager' do
    let_it_be(:runner_manager) { create(:ci_runner_machine, runner: group_runner) }
    let_it_be(:other_runner_manager) { create(:ci_runner_machine, runner: group_runner) }

    let_it_be(:routed_build) { create(:ci_build, :created, pipeline: pipeline) }
    let_it_be(:routed_pending_build) do
      create(:ci_pending_build, build: routed_build, project: project, runner_machine_id: runner_manager.id)
    end

    it 'includes both unrouted builds and builds routed to this runner_manager' do
      strategy = described_class.new(group_runner)

      expect(strategy.builds_for_runner_manager(::Ci::PendingBuild.all, runner_manager)).to include(
        routed_pending_build, pending_build_1, pending_build_2, pending_build_3
      )
    end

    it 'excludes builds routed to a different runner_manager' do
      strategy = described_class.new(group_runner)

      expect(strategy.builds_for_runner_manager(::Ci::PendingBuild.all, other_runner_manager))
        .not_to include(routed_pending_build)
    end

    it 'excludes routed builds when no runner_manager is given' do
      strategy = described_class.new(group_runner)

      expect(strategy.builds_for_runner_manager(::Ci::PendingBuild.all, nil)).not_to include(routed_pending_build)
    end

    it 'still includes unrouted builds when no runner_manager is given' do
      strategy = described_class.new(group_runner)

      expect(strategy.builds_for_runner_manager(::Ci::PendingBuild.all, nil)).to include(
        pending_build_1, pending_build_2, pending_build_3
      )
    end
  end
end
