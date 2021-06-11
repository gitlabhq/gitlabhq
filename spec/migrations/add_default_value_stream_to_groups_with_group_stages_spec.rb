# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddDefaultValueStreamToGroupsWithGroupStages, schema: 20200624142207 do
  let(:groups) { table(:namespaces) }
  let(:group_stages) { table(:analytics_cycle_analytics_group_stages) }
  let(:value_streams) { table(:analytics_cycle_analytics_group_value_streams) }

  let!(:group) { groups.create!(name: 'test', path: 'path', type: 'Group') }
  let!(:group_stage) { group_stages.create!(name: 'test', group_id: group.id, start_event_identifier: 1, end_event_identifier: 2) }

  describe '#up' do
    it 'creates default value stream record for the group' do
      migrate!

      group_value_streams = value_streams.where(group_id: group.id)
      expect(group_value_streams.size).to eq(1)

      value_stream = group_value_streams.first
      expect(value_stream.name).to eq('default')
    end

    it 'migrates existing stages to the default value stream' do
      migrate!

      group_stage.reload

      value_stream = value_streams.find_by(group_id: group.id, name: 'default')
      expect(group_stage.group_value_stream_id).to eq(value_stream.id)
    end
  end

  describe '#down' do
    it 'sets the group_value_stream_id to nil' do
      described_class.new.down

      group_stage.reload

      expect(group_stage.group_value_stream_id).to be_nil
    end
  end
end
