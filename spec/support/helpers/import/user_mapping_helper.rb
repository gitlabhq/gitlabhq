# frozen_string_literal: true

# Helper methods for import user mapping specs
module Import
  module UserMappingHelper
    # Return references pushed to Redis as an array
    #
    # Example:
    #
    # [
    #   "Issue", 1, "author_id", 1,
    #   "Issue", 1, "last_edited_by_id", 1,
    #   "Note", 2, "author_id", 1
    # ]
    #
    # @param import_type [String]
    # @param import_uid [Integer]
    # @param limit [Integer]
    # @return [Array]
    def placeholder_user_references(import_type, import_uid, limit = 100)
      user_references = ::Import::PlaceholderReferences::Store.new(import_source: import_type, import_uid: import_uid)
        .get(limit)

      user_references.map do |item|
        item = Import::SourceUserPlaceholderReference.from_serialized(item)
        key = item.numeric_key || item.composite_key

        [item.model, key, item.user_reference_column, item.source_user_id]
      end
    end

    # Generate a source user with a provided project and identifier
    #
    # @param project [Project]
    # @param identifier [String, Integer]
    # @return [Import::SourceUser]
    def generate_source_user(project, identifier)
      create(
        :import_source_user,
        source_user_identifier: identifier,
        source_hostname: project.import_url,
        import_type: project.import_type,
        namespace: project.root_ancestor
      )
    end
  end
end
