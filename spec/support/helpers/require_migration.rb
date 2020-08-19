# frozen_string_literal: true

require 'find'

class RequireMigration
  MIGRATION_FOLDERS = %w(db/migrate db/post_migrate ee/db/geo/migrate ee/db/geo/post_migrate).freeze
  SPEC_FILE_PATTERN = /.+\/(?<file_name>.+)_spec\.rb/.freeze

  class << self
    def require_migration!(file_name)
      file_paths = search_migration_file(file_name)

      require file_paths.first
    end

    def search_migration_file(file_name)
      MIGRATION_FOLDERS.flat_map do |path|
        migration_path = Rails.root.join(path).to_s

        Find.find(migration_path).grep(/\d+_#{file_name}\.rb/)
      end
    end
  end
end

def require_migration!(file_name = nil)
  location_info = caller_locations.first.path.match(RequireMigration::SPEC_FILE_PATTERN)
  file_name ||= location_info[:file_name]

  RequireMigration.require_migration!(file_name)
end
