# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ProjectStage do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
  end

  it 'default stages must be valid' do
    project = build(:project)

    Gitlab::Analytics::CycleAnalytics::DefaultStages.all.each do |params|
      stage = described_class.new(params.merge(project: project))
      expect(stage).to be_valid
    end
  end

  it_behaves_like 'value stream analytics stage' do
    let(:factory) { :cycle_analytics_project_stage }
    let(:parent) { build(:project) }
    let(:parent_name) { :project }
  end

  describe '.distinct_stages_within_hierarchy' do
    let_it_be(:top_level_group) { create(:group) }
    let_it_be(:sub_group_1) { create(:group, parent: top_level_group) }
    let_it_be(:sub_group_2) { create(:group, parent: sub_group_1) }

    let_it_be(:project_1) { create(:project, group: sub_group_1) }
    let_it_be(:project_2) { create(:project, group: sub_group_2) }
    let_it_be(:project_3) { create(:project, group: top_level_group) }

    let_it_be(:stage1) { create(:cycle_analytics_project_stage, project: project_1, start_event_identifier: :issue_created, end_event_identifier: :issue_deployed_to_production) }
    let_it_be(:stage2) { create(:cycle_analytics_project_stage, project: project_3, start_event_identifier: :issue_created, end_event_identifier: :issue_deployed_to_production) }

    let_it_be(:stage3) { create(:cycle_analytics_project_stage, project: project_1, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged) }
    let_it_be(:stage4) { create(:cycle_analytics_project_stage, project: project_3, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged) }

    subject(:distinct_start_and_end_event_identifiers) { described_class.distinct_stages_within_hierarchy(top_level_group).to_a.pluck(:start_event_identifier, :end_event_identifier) }

    it 'returns distinct stages by start and end events (using stage_event_hash_id)' do
      expect(distinct_start_and_end_event_identifiers).to match_array(
        [
          %w[issue_created issue_deployed_to_production],
          %w[merge_request_created merge_request_merged]
        ])
    end
  end
end
