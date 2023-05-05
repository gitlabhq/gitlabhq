# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillCycleAnalyticsAggregations, :migration, feature_category: :value_stream_management do
  let(:migration) { described_class.new }

  let(:aggregations) { table(:analytics_cycle_analytics_aggregations) }
  let(:namespaces) { table(:namespaces) }
  let(:group_value_streams) { table(:analytics_cycle_analytics_group_value_streams) }

  context 'when there are value stream records' do
    it 'inserts a record for each top-level namespace' do
      group1 = namespaces.create!(path: 'aaa', name: 'aaa')
      subgroup1 = namespaces.create!(path: 'bbb', name: 'bbb', parent_id: group1.id)
      group2 = namespaces.create!(path: 'ccc', name: 'ccc')

      namespaces.create!(path: 'ddd', name: 'ddd') # not used

      group_value_streams.create!(name: 'for top level group', group_id: group2.id)
      group_value_streams.create!(name: 'another for top level group', group_id: group2.id)

      group_value_streams.create!(name: 'for subgroup', group_id: subgroup1.id)
      group_value_streams.create!(name: 'another for subgroup', group_id: subgroup1.id)

      migrate!

      expect(aggregations.pluck(:group_id)).to match_array([group1.id, group2.id])
    end
  end

  it 'does nothing' do
    expect { migrate! }.not_to change { aggregations.count }
  end
end
