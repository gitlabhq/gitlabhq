# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Queue::PendingBuildsStrategy, feature_category: :continuous_integration do
  let_it_be(:group) { create(:group) }
  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let!(:build_1) { create(:ci_build, :created, pipeline: pipeline) }
  let!(:build_2) { create(:ci_build, :created, pipeline: pipeline) }
  let!(:build_3) { create(:ci_build, :created, pipeline: pipeline) }
  let!(:pending_build_1) { create(:ci_pending_build, build: build_2, project: project) }
  let!(:pending_build_2) { create(:ci_pending_build, build: build_3, project: project) }
  let!(:pending_build_3) { create(:ci_pending_build, build: build_1, project: project) }

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
end
