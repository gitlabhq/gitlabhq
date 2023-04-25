# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Stage, feature_category: :value_stream_management do
  describe 'uniqueness validation on name' do
    subject { build(:cycle_analytics_stage) }

    it { is_expected.to validate_uniqueness_of(:name).scoped_to([:group_id, :group_value_stream_id]) }
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
    let_it_be(:sub_group) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, group: sub_group).reload }

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

  describe 'events tracking' do
    let(:category) { described_class.to_s }
    let(:label) { described_class.table_name }
    let(:namespace) { create(:group) }
    let(:action) { "database_event_#{property}" }
    let(:value_stream) { create(:cycle_analytics_value_stream) }
    let(:feature_flag_name) { :product_intelligence_database_event_tracking }
    let(:stage) { described_class.create!(stage_params) }
    let(:stage_params) do
      {
        namespace: namespace,
        name: 'st1',
        start_event_identifier: :merge_request_created,
        end_event_identifier: :merge_request_merged,
        group_value_stream_id: value_stream.id
      }
    end

    let(:record_tracked_attributes) do
      {
        "id" => stage.id,
        "created_at" => stage.created_at,
        "updated_at" => stage.updated_at,
        "relative_position" => stage.relative_position,
        "start_event_identifier" => stage.start_event_identifier,
        "end_event_identifier" => stage.end_event_identifier,
        "group_id" => stage.group_id,
        "start_event_label_id" => stage.start_event_label_id,
        "end_event_label_id" => stage.end_event_label_id,
        "hidden" => stage.hidden,
        "custom" => stage.custom,
        "name" => stage.name,
        "group_value_stream_id" => stage.group_value_stream_id
      }
    end

    context 'with database event tracking' do
      before do
        allow(Gitlab::Tracking).to receive(:database_event).and_call_original
      end

      describe '#create' do
        it_behaves_like 'Snowplow event tracking', overrides: { tracking_method: :database_event } do
          let(:property) { 'create' }
          let(:extra) { record_tracked_attributes }

          subject(:new_group_stage) { stage }
        end
      end

      describe '#update', :freeze_time do
        it_behaves_like 'Snowplow event tracking', overrides: { tracking_method: :database_event } do
          subject(:create_group_stage) { stage.update!(name: 'st 2') }

          let(:extra) { record_tracked_attributes.merge('name' => 'st 2') }
          let(:property) { 'update' }
        end
      end

      describe '#destroy' do
        it_behaves_like 'Snowplow event tracking', overrides: { tracking_method: :database_event } do
          subject(:delete_stage_group) { stage.destroy! }

          let(:extra) { record_tracked_attributes }
          let(:property) { 'destroy' }
        end
      end
    end
  end
end
