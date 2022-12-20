# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillStageEventHash, schema: 20210730103808, feature_category: :value_stream_management do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:labels) { table(:labels) }
  let(:group_stages) { table(:analytics_cycle_analytics_group_stages) }
  let(:project_stages) { table(:analytics_cycle_analytics_project_stages) }
  let(:group_value_streams) { table(:analytics_cycle_analytics_group_value_streams) }
  let(:project_value_streams) { table(:analytics_cycle_analytics_project_value_streams) }
  let(:stage_event_hashes) { table(:analytics_cycle_analytics_stage_event_hashes) }

  let(:issue_created) { 1 }
  let(:issue_closed) { 3 }
  let(:issue_label_removed) { 9 }
  let(:unknown_stage_event) { -1 }

  let(:namespace) { namespaces.create!(name: 'ns', path: 'ns', type: 'Group') }
  let(:project) { projects.create!(name: 'project', path: 'project', namespace_id: namespace.id) }
  let(:group_label) { labels.create!(title: 'label', type: 'GroupLabel', group_id: namespace.id) }
  let(:group_value_stream) { group_value_streams.create!(name: 'group vs', group_id: namespace.id) }
  let(:project_value_stream) { project_value_streams.create!(name: 'project vs', project_id: project.id) }

  let(:group_stage_1) do
    group_stages.create!(
      name: 'stage 1',
      group_id: namespace.id,
      start_event_identifier: issue_created,
      end_event_identifier: issue_closed,
      group_value_stream_id: group_value_stream.id
    )
  end

  let(:group_stage_2) do
    group_stages.create!(
      name: 'stage 2',
      group_id: namespace.id,
      start_event_identifier: issue_created,
      end_event_identifier: issue_label_removed,
      end_event_label_id: group_label.id,
      group_value_stream_id: group_value_stream.id
    )
  end

  let(:project_stage_1) do
    project_stages.create!(
      name: 'stage 1',
      project_id: project.id,
      start_event_identifier: issue_created,
      end_event_identifier: issue_closed,
      project_value_stream_id: project_value_stream.id
    )
  end

  let(:invalid_group_stage) do
    group_stages.create!(
      name: 'stage 3',
      group_id: namespace.id,
      start_event_identifier: issue_created,
      end_event_identifier: unknown_stage_event,
      group_value_stream_id: group_value_stream.id
    )
  end

  describe '#up' do
    it 'populates stage_event_hash_id column' do
      group_stage_1
      group_stage_2
      project_stage_1

      migrate!

      group_stage_1.reload
      group_stage_2.reload
      project_stage_1.reload

      expect(group_stage_1.stage_event_hash_id).not_to be_nil
      expect(group_stage_2.stage_event_hash_id).not_to be_nil
      expect(project_stage_1.stage_event_hash_id).not_to be_nil

      expect(stage_event_hashes.count).to eq(2) # group_stage_1 and project_stage_1 has the same hash
    end

    it 'runs without problem without stages' do
      expect { migrate! }.not_to raise_error
    end

    context 'when invalid event identifier is discovered' do
      it 'removes the stage' do
        group_stage_1
        invalid_group_stage

        expect { migrate! }.not_to change { group_stage_1 }

        expect(group_stages.find_by_id(invalid_group_stage.id)).to eq(nil)
      end
    end
  end
end
