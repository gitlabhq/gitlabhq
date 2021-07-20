# frozen_string_literal: true

require 'spec_helper'
require_migration!('replace_unique_index_on_cycle_analytics_stages')

RSpec.describe ReplaceUniqueIndexOnCycleAnalyticsStages, :migration, schema: 20200727142337 do
  let(:namespaces) { table(:namespaces) }
  let(:group_value_streams) { table(:analytics_cycle_analytics_group_value_streams) }
  let(:group_stages) { table(:analytics_cycle_analytics_group_stages) }

  let(:group) { namespaces.create!(type: 'Group', name: 'test', path: 'test') }

  let(:value_stream_1) { group_value_streams.create!(group_id: group.id, name: 'vs1') }
  let(:value_stream_2) { group_value_streams.create!(group_id: group.id, name: 'vs2') }

  let(:duplicated_stage_1) { group_stages.create!(group_id: group.id, group_value_stream_id: value_stream_1.id, name: 'stage', start_event_identifier: 1, end_event_identifier: 1) }
  let(:duplicated_stage_2) { group_stages.create!(group_id: group.id, group_value_stream_id: value_stream_2.id, name: 'stage', start_event_identifier: 1, end_event_identifier: 1) }

  let(:stage_record) { group_stages.create!(group_id: group.id, group_value_stream_id: value_stream_2.id, name: 'other stage', start_event_identifier: 1, end_event_identifier: 1) }

  describe '#down' do
    subject { described_class.new.down }

    before do
      described_class.new.up

      duplicated_stage_1
      duplicated_stage_2
      stage_record
    end

    it 'removes duplicated stage records' do
      subject

      stage = group_stages.find_by_id(duplicated_stage_2.id)
      expect(stage).to be_nil
    end

    it 'does not change the first duplicated stage record' do
      expect { subject }.not_to change { duplicated_stage_1.reload.attributes }
    end

    it 'does not change not duplicated stage record' do
      expect { subject }.not_to change { stage_record.reload.attributes }
    end
  end
end
