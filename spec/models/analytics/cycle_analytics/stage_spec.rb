# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Stage, feature_category: :value_stream_management do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:group) { create(:group, organization: organization) }

  describe 'validations' do
    subject { build(:cycle_analytics_stage, namespace: group) }

    it { is_expected.to validate_uniqueness_of(:name).scoped_to([:group_id, :group_value_stream_id]) }

    it 'validates count of stages per value stream' do
      stub_const("#{described_class.name}::MAX_STAGES_PER_VALUE_STREAM", 1)
      value_stream = create(:cycle_analytics_value_stream, name: 'test')
      create(:cycle_analytics_stage, name: "stage 1", value_stream: value_stream)

      new_stage = build(:cycle_analytics_stage, name: "stage 2", value_stream: value_stream)

      expect do
        new_stage.save!
      end.to raise_error(ActiveRecord::RecordInvalid,
        _('Validation failed: Value stream Maximum number of stages per value stream exceeded'))
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
    it { is_expected.to belong_to(:value_stream) }
  end

  it_behaves_like 'value stream analytics namespace models' do
    let(:factory_name) { :cycle_analytics_stage }
  end

  it_behaves_like 'value stream analytics stage' do
    let(:factory) { :cycle_analytics_stage }
    let(:parent) { create(:group) }
    let(:parent_name) { :namespace }
  end

  describe '.distinct_stages_within_hierarchy' do
    let_it_be(:group) { create(:group) }
    let_it_be(:sub_group) { create(:group, organization: group.organization, parent: group) }
    let_it_be(:project) { create(:project, organization: group.organization, group: sub_group).reload }

    before do
      # event identifiers are the same
      create(:cycle_analytics_stage, name: 'Stage A1', namespace: group,
        start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged)
      create(:cycle_analytics_stage, name: 'Stage A2', namespace: sub_group,
        start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged)
      create(:cycle_analytics_stage, name: 'Stage A3', namespace: sub_group,
        start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged)
      create(:cycle_analytics_stage, name: 'Stage A4', project: project,
        start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged)

      create(:cycle_analytics_stage,
        name: 'Stage B1',
        namespace: group,
        start_event_identifier: :merge_request_last_build_started,
        end_event_identifier: :merge_request_last_build_finished)

      create(:cycle_analytics_stage, name: 'Stage C1', project: project,
        start_event_identifier: :issue_created, end_event_identifier: :issue_deployed_to_production)
      create(:cycle_analytics_stage, name: 'Stage C2', project: project,
        start_event_identifier: :issue_created, end_event_identifier: :issue_deployed_to_production)
    end

    it 'returns distinct stages by the event identifiers' do
      stages = described_class.distinct_stages_within_hierarchy(group).to_a

      expected_event_pairs = [
        %w[merge_request_created merge_request_merged],
        %w[merge_request_last_build_started merge_request_last_build_finished],
        %w[issue_created issue_deployed_to_production]
      ].sort

      current_event_pairs = stages.map do |stage|
        [stage.start_event_identifier, stage.end_event_identifier]
      end.sort

      expect(current_event_pairs).to eq(expected_event_pairs)
    end
  end
end
