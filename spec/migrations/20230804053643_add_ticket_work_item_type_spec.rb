# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddTicketWorkItemType, :migration, feature_category: :service_desk do
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
      epic: 7,
      ticket: 8
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

  it 'adds the ticket type, widget definitions and hierarchy restrictions', :aggregate_failures do
    expect do
      migrate!
    end.to change { work_item_types.count }.by(1)
      .and(change { work_item_widget_definitions.count }.by(13))
      .and(change { work_item_hierarchy_restrictions.count }.by(2))

    ticket_type = work_item_types.last
    issue_type = work_item_types.find_by!(namespace_id: nil, base_type: base_types[:issue])

    expect(work_item_types.pluck(:base_type)).to include(base_types[:ticket])
    expect(
      work_item_widget_definitions.where(work_item_type_id: ticket_type.id).pluck(:widget_type)
    ).to match_array(described_class::TICKET_WIDGETS.values)
    expect(
      work_item_hierarchy_restrictions.where(parent_type_id: ticket_type.id).pluck(:child_type_id, :maximum_depth)
    ).to contain_exactly([ticket_type.id, 1], [issue_type.id, 1])
  end

  it "skips creating the new type and it's definitions when it already exists" do
    work_item_types.find_or_create_by!(
      name: 'Ticket', namespace_id: nil, base_type: base_types[:ticket], icon_name: 'issue-type-issue'
    )

    expect do
      migrate!
    end.to not_change(work_item_types, :count)
      .and(not_change(work_item_widget_definitions, :count))
      .and(not_change(work_item_hierarchy_restrictions, :count))
  end

  it "skips creating the new type and it's definitions when type creation fails" do
    allow(described_class::MigrationWorkItemType).to receive(:create)
      .and_return(described_class::MigrationWorkItemType.new)

    expect do
      migrate!
    end.to not_change(work_item_types, :count)
      .and(not_change(work_item_widget_definitions, :count))
      .and(not_change(work_item_hierarchy_restrictions, :count))
  end

  def reset_db_state_prior_to_migration
    # Database needs to be in a similar state as when this migration was created
    work_item_types.delete_all

    {
      issue: { name: 'Issue', icon_name: 'issue-type-issue' },
      incident: { name: 'Incident', icon_name: 'issue-type-incident' },
      test_case: { name: 'Test Case', icon_name: 'issue-type-test-case' },
      requirement: { name: 'Requirement', icon_name: 'issue-type-requirements' },
      task: { name: 'Task', icon_name: 'issue-type-task' },
      objective: { name: 'Objective', icon_name: 'issue-type-objective' },
      key_result: { name: 'Key Result', icon_name: 'issue-type-keyresult' },
      epic: { name: 'Epic', icon_name: 'issue-type-epic' }
    }.each do |type, opts|
      work_item_types.find_or_create_by!(
        name: opts[:name], namespace_id: nil, base_type: base_types[type], icon_name: opts[:icon_name]
      )
    end
  end
end
