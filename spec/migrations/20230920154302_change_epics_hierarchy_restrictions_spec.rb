# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ChangeEpicsHierarchyRestrictions, :migration, feature_category: :portfolio_management do
  include MigrationHelpers::WorkItemTypesHelper

  let(:work_item_types) { table(:work_item_types) }
  let(:work_item_hierarchy_restrictions) { table(:work_item_hierarchy_restrictions) }
  let(:base_types) { { issue: 0, epic: 7 } }

  let(:epic_type) { work_item_types.find_by!(namespace_id: nil, base_type: base_types[:epic]) }
  let(:issue_type) { work_item_types.find_by!(namespace_id: nil, base_type: base_types[:issue]) }

  shared_examples 'migration that updates cross_hierarchy_enabled column' do
    it 'updates column value' do
      expect { subject }.to not_change { work_item_hierarchy_restrictions.count }

      expect(
        work_item_hierarchy_restrictions.where(parent_type_id: epic_type.id)
                                        .pluck(:child_type_id, :maximum_depth, :cross_hierarchy_enabled)
      ).to contain_exactly(
        [epic_type.id, 9, expected_cross_hierarchy_status],
        [issue_type.id, 1, expected_cross_hierarchy_status]
      )
    end

    it_behaves_like 'logs an error if type is missing', 'Epic'
    it_behaves_like 'logs an error if type is missing', 'Issue'
  end

  shared_examples 'logs an error if type is missing' do |type_name|
    let(:error_msg) { 'Issue or Epic work item types not found, skipping hierarchy restrictions update' }

    it 'logs a warning' do
      allow(described_class::MigrationWorkItemType).to receive(:find_by_name_and_namespace_id).and_call_original
      allow(described_class::MigrationWorkItemType).to receive(:find_by_name_and_namespace_id).with(type_name, nil)
                                                                                              .and_return(nil)

      expect(Gitlab::AppLogger).to receive(:warn).with(error_msg)
      migrate!
    end
  end

  describe 'up' do
    let(:expected_cross_hierarchy_status) { true }

    subject { migrate! }

    it_behaves_like 'migration that updates cross_hierarchy_enabled column'
  end

  describe 'down' do
    let(:expected_cross_hierarchy_status) { false }

    subject do
      migrate!
      schema_migrate_down!
    end

    it_behaves_like 'migration that updates cross_hierarchy_enabled column'
  end
end
