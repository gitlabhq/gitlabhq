# frozen_string_literal: true

module MigrationHelpers
  module WorkItemTypesHelper
    DEFAULT_WORK_ITEM_TYPES = {
      issue: { name: 'Issue', icon_name: 'issue-type-issue', enum_value: 0 },
      incident: { name: 'Incident', icon_name: 'issue-type-incident', enum_value: 1 },
      test_case: { name: 'Test Case', icon_name: 'issue-type-test-case', enum_value: 2 },
      requirement: { name: 'Requirement', icon_name: 'issue-type-requirements', enum_value: 3 },
      task: { name: 'Task', icon_name: 'issue-type-task', enum_value: 4 }
    }.freeze

    def reset_work_item_types
      work_item_types_table.delete_all

      DEFAULT_WORK_ITEM_TYPES.each do |type, attributes|
        work_item_types_table.create!(base_type: attributes[:enum_value], **attributes.slice(:name, :icon_name))
      end
    end

    private

    def work_item_types_table
      table(:work_item_types)
    end
  end
end
