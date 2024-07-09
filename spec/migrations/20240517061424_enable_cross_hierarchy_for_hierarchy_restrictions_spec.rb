# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnableCrossHierarchyForHierarchyRestrictions, :migration, feature_category: :portfolio_management do
  let(:work_item_types) { table(:work_item_types) }
  let(:task_type) { find_work_item_type(:task) }
  let(:issue_type) { find_work_item_type(:issue) }
  let(:objective_type) { find_work_item_type(:objective) }
  let(:key_result_type) { find_work_item_type(:key_result) }
  let(:incident_type) { find_work_item_type(:incident) }
  let(:ticket_type) { find_work_item_type(:ticket) }
  let(:work_item_hierarchy_restrictions) { table(:work_item_hierarchy_restrictions) }
  let(:base_types) { { issue: 0, objective: 5, key_result: 6, incident: 1, ticket: 8, task: 4 } }

  def find_work_item_type(base_type)
    work_item_types.find_by!(namespace_id: nil, base_type: base_types[base_type])
  end

  shared_examples 'updates cross_hierarchy_enabled column' do
    it 'updates column value' do
      expect { subject }.to not_change { work_item_hierarchy_restrictions.count }

      expect(
        work_item_hierarchy_restrictions.where(parent_type_id: objective_type.id)
                                        .pluck(:child_type_id, :maximum_depth, :cross_hierarchy_enabled)
      ).to contain_exactly(
        [objective_type.id, 9, expected_cross_hierarchy_status],
        [key_result_type.id, 1, expected_cross_hierarchy_status]
      )

      expect(
        work_item_hierarchy_restrictions.where(child_type_id: task_type.id)
                                        .pluck(:parent_type_id, :maximum_depth, :cross_hierarchy_enabled)
      ).to contain_exactly(
        [incident_type.id, 1, expected_cross_hierarchy_status],
        [ticket_type.id, 1, expected_cross_hierarchy_status],
        [issue_type.id, 1, expected_cross_hierarchy_status]
      )
    end

    it_behaves_like 'logs an error if type is missing', 'Task'
    it_behaves_like 'logs an error if type is missing', 'Issue'
    it_behaves_like 'logs an error if type is missing', 'Objective'
    it_behaves_like 'logs an error if type is missing', 'Key Result'
    it_behaves_like 'logs an error if type is missing', 'Incident'
    it_behaves_like 'logs an error if type is missing', 'Ticket'
  end

  shared_examples 'logs an error if type is missing' do |type_name|
    let(:error_msg) do
      'One of Issue, Task, Objective, Key Result, Incident, Ticket work item types not found, ' \
        'skipping hierarchy restrictions update'
    end

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

    it_behaves_like 'updates cross_hierarchy_enabled column'
  end

  describe 'down' do
    let(:expected_cross_hierarchy_status) { false }

    subject do
      migrate!
      schema_migrate_down!
    end

    it_behaves_like 'updates cross_hierarchy_enabled column'
  end
end
