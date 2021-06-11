# frozen_string_literal: true

require 'spec_helper'
require_migration!('fix_total_stage_in_vsa')

RSpec.describe FixTotalStageInVsa, :migration, schema: 20210518001450 do
  let(:namespaces) { table(:namespaces) }
  let(:group_value_streams) { table(:analytics_cycle_analytics_group_value_streams) }
  let(:group_stages) { table(:analytics_cycle_analytics_group_stages) }

  let!(:group) { namespaces.create!(name: 'ns1', path: 'ns1', type: 'Group') }
  let!(:group_vs_1) { group_value_streams.create!(name: 'default', group_id: group.id) }
  let!(:group_vs_2) { group_value_streams.create!(name: 'other', group_id: group.id) }
  let!(:group_vs_3) { group_value_streams.create!(name: 'another', group_id: group.id) }
  let!(:group_stage_total) { group_stages.create!(name: 'Total', custom: false, group_id: group.id, group_value_stream_id: group_vs_1.id, start_event_identifier: 1, end_event_identifier: 2) }
  let!(:group_stage_different_name) { group_stages.create!(name: 'Issue', custom: false, group_id: group.id, group_value_stream_id: group_vs_2.id, start_event_identifier: 1, end_event_identifier: 2) }
  let!(:group_stage_total_custom) { group_stages.create!(name: 'Total', custom: true, group_id: group.id, group_value_stream_id: group_vs_3.id, start_event_identifier: 1, end_event_identifier: 2) }

  it 'deduplicates issue_metrics table' do
    migrate!

    group_stage_total.reload
    group_stage_different_name.reload
    group_stage_total_custom.reload

    expect(group_stage_total.custom).to eq(true)
    expect(group_stage_different_name.custom).to eq(false)
    expect(group_stage_total_custom.custom).to eq(true)
  end
end
