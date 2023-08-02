# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddEpicWorkItemType, :migration, feature_category: :team_planning do
  include MigrationHelpers::WorkItemTypesHelper

  let(:work_item_types) { table(:work_item_types) }
  let(:work_item_widget_definitions) { table(:work_item_widget_definitions) }
  let(:work_item_hierarchy_restrictions) { table(:work_item_hierarchy_restrictions) }
  let(:base_types) do
    {
      issue: 0,
      incident: 1,
      test_case: 2,
      requirement: 3,
      task: 4,
      objective: 5,
      key_result: 6,
      epic: 7
    }
  end

  after(:all) do
    # Make sure base types are recreated after running the migration
    # because migration specs are not run in a transaction
    reset_work_item_types
  end

  before do
    reset_db_state_prior_to_migration
  end

  it 'adds the epic type, widget definitions and hierarchy restrictions', :aggregate_failures do
    expect do
      migrate!
    end.to change { work_item_types.count }.by(1)
      .and(change { work_item_widget_definitions.count }.by(10))
      .and(change { work_item_hierarchy_restrictions.count }.by(2))

    epic_type = work_item_types.last
    issue_type = work_item_types.find_by!(namespace_id: nil, base_type: base_types[:issue])

    expect(work_item_types.pluck(:base_type)).to include(base_types[:epic])
    expect(
      work_item_widget_definitions.where(work_item_type_id: epic_type.id).pluck(:widget_type)
    ).to match_array(described_class::EPIC_WIDGETS.values)
    expect(
      work_item_hierarchy_restrictions.where(parent_type_id: epic_type.id).pluck(:child_type_id, :maximum_depth)
    ).to contain_exactly([epic_type.id, 9], [issue_type.id, 1])
  end

  it 'skips creating the new type an it\'s definitions' do
    work_item_types.find_or_create_by!(
      name: 'Epic', namespace_id: nil, base_type: base_types[:epic], icon_name: 'issue-type-epic'
    )

    expect do
      migrate!
    end.to not_change(work_item_types, :count)
      .and(not_change(work_item_widget_definitions, :count))
      .and(not_change(work_item_hierarchy_restrictions, :count))
  end

  def reset_db_state_prior_to_migration
    # Database needs to be in a similar state as when this migration was created
    work_item_types.delete_all
    work_item_types.find_or_create_by!(
      name: 'Issue', namespace_id: nil, base_type: base_types[:issue], icon_name: 'issue-type-issue'
    )
    work_item_types.find_or_create_by!(
      name: 'Incident', namespace_id: nil, base_type: base_types[:incident], icon_name: 'issue-type-incident'
    )
    work_item_types.find_or_create_by!(
      name: 'Test Case', namespace_id: nil, base_type: base_types[:test_case], icon_name: 'issue-type-test-case'
    )
    work_item_types.find_or_create_by!(
      name: 'Requirement', namespace_id: nil, base_type: base_types[:requirement], icon_name: 'issue-type-requirements'
    )
    work_item_types.find_or_create_by!(
      name: 'Task', namespace_id: nil, base_type: base_types[:task], icon_name: 'issue-type-task'
    )
    work_item_types.find_or_create_by!(
      name: 'Objective', namespace_id: nil, base_type: base_types[:objective], icon_name: 'issue-type-objective'
    )
    work_item_types.find_or_create_by!(
      name: 'Key Result', namespace_id: nil, base_type: base_types[:key_result], icon_name: 'issue-type-keyresult'
    )
  end
end
