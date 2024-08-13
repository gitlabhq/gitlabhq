# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateHierarchyRestrictionSubepicsMaximumDepth, :migration, feature_category: :portfolio_management do
  let(:work_item_types) { table(:work_item_types) }
  let(:work_item_hierarchy_restrictions) { table(:work_item_hierarchy_restrictions) }
  let(:base_types) { { epic: 7 } }

  let(:epic_type) { work_item_types.find_by!(namespace_id: nil, base_type: base_types[:epic]) }

  shared_examples 'migration that updates maximum_depth column' do
    it 'updates column value' do
      expect { subject }.to not_change { work_item_hierarchy_restrictions.count }

      expect(
        work_item_hierarchy_restrictions.where(parent_type_id: epic_type.id, child_type_id: epic_type.id)
                                        .pluck(:child_type_id, :maximum_depth, :cross_hierarchy_enabled)
      ).to contain_exactly([epic_type.id, expected_maximum_depth, true])
    end

    it 'logs a warning if type is missing' do
      allow(described_class::MigrationWorkItemType).to receive(:find_by_name_and_namespace_id).and_call_original
      allow(described_class::MigrationWorkItemType).to receive(:find_by_name_and_namespace_id).with('Epic', nil)
                                                                                              .and_return(nil)

      expect(Gitlab::AppLogger).to receive(:warn)
        .with('Epic work item type not found, skipping hierarchy restrictions update')

      migrate!
    end

    context "when restriction doesn't exist" do
      before do
        WorkItems::HierarchyRestriction.where(parent_type_id: epic_type.id, child_type_id: epic_type.id).delete_all
      end

      it 'inserts the restriction with correct maximum_depth' do
        expect { subject }.to change { work_item_hierarchy_restrictions.count }.by(1)

        expect(
          work_item_hierarchy_restrictions
            .where(parent_type_id: epic_type.id, child_type_id: epic_type.id)
            .pluck(:child_type_id, :maximum_depth, :cross_hierarchy_enabled)
        ).to contain_exactly([epic_type.id, expected_maximum_depth, true])
      end
    end
  end

  describe 'up' do
    let(:expected_maximum_depth) { described_class::NEW_DEPTH }

    subject { migrate! }

    it_behaves_like 'migration that updates maximum_depth column'
  end

  describe 'down' do
    let(:expected_maximum_depth) { 9 }

    subject do
      migrate!
      schema_migrate_down!
    end

    it_behaves_like 'migration that updates maximum_depth column'
  end
end
