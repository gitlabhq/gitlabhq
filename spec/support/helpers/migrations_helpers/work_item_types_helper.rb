# frozen_string_literal: true

module MigrationHelpers
  module WorkItemTypesHelper
    def reset_work_item_types
      Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.upsert_types
      Gitlab::DatabaseImporters::WorkItems::HierarchyRestrictionsImporter.upsert_restrictions
    end
  end
end
