# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveUserNamespaceRecordsFromVsaAggregation,
  migration: :gitlab_main,
  feature_category: :value_stream_management do
  let(:migration) { described_class::MIGRATION }
  let!(:namespaces) { table(:namespaces) }
  let!(:aggregations) { table(:analytics_cycle_analytics_aggregations) }

  let!(:group) { namespaces.create!(name: 'aaa', path: 'aaa', type: 'Group') }
  let!(:user_namespace) { namespaces.create!(name: 'ccc', path: 'ccc', type: 'User') }
  let!(:project_namespace) { namespaces.create!(name: 'bbb', path: 'bbb', type: 'Project') }

  let!(:group_aggregation) { aggregations.create!(group_id: group.id) }
  let!(:user_namespace_aggregation) { aggregations.create!(group_id: user_namespace.id) }
  let!(:project_namespace_aggregation) { aggregations.create!(group_id: project_namespace.id) }

  describe '#up' do
    it 'deletes the non-group namespace aggregation records' do
      stub_const('RemoveUserNamespaceRecordsFromVsaAggregation::BATCH_SIZE', 1)

      expect { migrate! }.to change {
                               aggregations.order(:group_id)
                             }.from([group_aggregation, user_namespace_aggregation,
                               project_namespace_aggregation]).to([group_aggregation])
    end
  end

  describe '#down' do
    it 'does nothing' do
      migrate!

      expect { schema_migrate_down! }.not_to change {
                                               aggregations.order(:group_id).pluck(:group_id)
                                             }.from([group_aggregation.id])
    end
  end
end
