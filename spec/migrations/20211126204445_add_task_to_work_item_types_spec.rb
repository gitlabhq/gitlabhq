# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddTaskToWorkItemTypes, :migration, feature_category: :team_planning do
  include MigrationHelpers::WorkItemTypesHelper

  let!(:work_item_types) { table(:work_item_types) }

  let(:base_types) do
    {
      issue: 0,
      incident: 1,
      test_case: 2,
      requirement: 3,
      task: 4
    }
  end

  append_after(:all) do
    # Make sure base types are recreated after running the migration
    # because migration specs are not run in a transaction
    reset_work_item_types
  end

  it 'skips creating the record if it already exists' do
    reset_db_state_prior_to_migration
    work_item_types.find_or_create_by!(name: 'Task', namespace_id: nil, base_type: base_types[:task], icon_name: 'issue-type-task')

    expect do
      migrate!
    end.to not_change(work_item_types, :count)
  end

  it 'adds task to base work item types' do
    reset_db_state_prior_to_migration

    expect do
      migrate!
    end.to change(work_item_types, :count).from(4).to(5)

    expect(work_item_types.all.pluck(:base_type)).to include(base_types[:task])
  end

  def reset_db_state_prior_to_migration
    # Database needs to be in a similar state as when this migration was created
    work_item_types.delete_all
    work_item_types.find_or_create_by!(name: 'Issue', namespace_id: nil, base_type: base_types[:issue], icon_name: 'issue-type-issue')
    work_item_types.find_or_create_by!(name: 'Incident', namespace_id: nil, base_type: base_types[:incident], icon_name: 'issue-type-incident')
    work_item_types.find_or_create_by!(name: 'Test Case', namespace_id: nil, base_type: base_types[:test_case], icon_name: 'issue-type-test-case')
    work_item_types.find_or_create_by!(name: 'Requirement', namespace_id: nil, base_type: base_types[:requirement], icon_name: 'issue-type-requirements')
  end
end
