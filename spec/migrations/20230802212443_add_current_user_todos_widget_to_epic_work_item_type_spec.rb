# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddCurrentUserTodosWidgetToEpicWorkItemType, :migration, feature_category: :team_planning do
  include MigrationHelpers::WorkItemTypesHelper

  let(:work_item_types) { table(:work_item_types) }
  let(:work_item_widget_definitions) { table(:work_item_widget_definitions) }
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

  let(:epic_widgets) do
    {
      'Assignees' => 0,
      'Description' => 1,
      'Hierarchy' => 2,
      'Labels' => 3,
      'Notes' => 5,
      'Start and due date' => 6,
      'Health status' => 7,
      'Status' => 11,
      'Notifications' => 14,
      'Award emoji' => 16
    }.freeze
  end

  after(:all) do
    # Make sure base types are recreated after running the migration
    # because migration specs are not run in a transaction
    reset_work_item_types
  end

  before do
    reset_db_state_prior_to_migration
  end

  describe '#up' do
    it 'adds current user todos widget to epic work item type', :aggregate_failures do
      expect do
        migrate!
      end.to change { work_item_widget_definitions.count }.by(1)

      epic_type = work_item_types.find_by(namespace_id: nil, base_type: described_class::EPIC_ENUM_VALUE)
      created_widget = work_item_widget_definitions.last

      expect(created_widget).to have_attributes(
        widget_type: described_class::WIDGET_ENUM_VALUE,
        name: described_class::WIDGET_NAME,
        work_item_type_id: epic_type.id
      )
    end

    context 'when epic type does not exist' do
      it 'skips creating the new widget definition' do
        work_item_types.where(namespace_id: nil, base_type: base_types[:epic]).delete_all

        expect do
          migrate!
        end.to not_change(work_item_widget_definitions, :count)
      end
    end
  end

  describe '#down' do
    it 'removes current user todos widget from epic work item type' do
      migrate!

      expect { schema_migrate_down! }.to change { work_item_widget_definitions.count }.by(-1)
    end
  end

  def reset_db_state_prior_to_migration
    # Database needs to be in a similar state as when this migration was created
    work_item_types.delete_all

    create_work_item!('Issue', :issue, 'issue-type-issue')
    create_work_item!('Incident', :incident, 'issue-type-incident')
    create_work_item!('Test Case', :test_case, 'issue-type-test-case')
    create_work_item!('Requirement', :requirement, 'issue-type-requirements')
    create_work_item!('Task', :task, 'issue-type-task')
    create_work_item!('Objective', :objective, 'issue-type-objective')
    create_work_item!('Key Result', :key_result, 'issue-type-keyresult')

    epic_type = create_work_item!('Epic', :epic, 'issue-type-epic')

    widgets = epic_widgets.map do |widget_name, widget_enum_value|
      {
        work_item_type_id: epic_type.id,
        name: widget_name,
        widget_type: widget_enum_value
      }
    end

    # Creating all widgets for the type so the state in the DB is as close as possible to the actual state
    work_item_widget_definitions.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def create_work_item!(type_name, base_type, icon_name)
    work_item_types.create!(
      name: type_name,
      namespace_id: nil,
      base_type: base_types[base_type],
      icon_name: icon_name
    )
  end
end
