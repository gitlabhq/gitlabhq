# frozen_string_literal: true

module MigrationHelpers
  module WorkItemTypesHelper
    def reset_work_item_types
      Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.upsert_types
      WorkItems::HierarchyRestriction.reset_column_information
      Gitlab::DatabaseImporters::WorkItems::HierarchyRestrictionsImporter.upsert_restrictions
      return unless WorkItems::RelatedLinkRestriction.table_exists?

      Gitlab::DatabaseImporters::WorkItems::RelatedLinksRestrictionsImporter.upsert_restrictions
    end
  end
end
