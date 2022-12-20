# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ToggleVsaAggregationsEnable, :migration, feature_category: :value_stream_management do
  let(:aggregations) { table(:analytics_cycle_analytics_aggregations) }
  let(:groups) { table(:namespaces) }

  let!(:group1) { groups.create!(name: 'aaa', path: 'aaa') }
  let!(:group2) { groups.create!(name: 'aaa', path: 'aaa') }
  let!(:group3) { groups.create!(name: 'aaa', path: 'aaa') }

  let!(:aggregation1) { aggregations.create!(group_id: group1.id, enabled: false) }
  let!(:aggregation2) { aggregations.create!(group_id: group2.id, enabled: true) }
  let!(:aggregation3) { aggregations.create!(group_id: group3.id, enabled: false) }

  it 'makes all aggregations enabled' do
    migrate!

    expect(aggregation1.reload).to be_enabled
    expect(aggregation2.reload).to be_enabled
    expect(aggregation3.reload).to be_enabled
  end
end
