# frozen_string_literal: true

module MigrationHelpers
  module NamespacesHelpers
    def create_namespace(name, visibility, options = {})
      table(:namespaces).create!(
        {
          name: name,
          path: name,
          type: 'Group',
          visibility_level: visibility
        }.merge(options))
    end
  end
end
