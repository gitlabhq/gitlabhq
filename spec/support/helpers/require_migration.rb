# frozen_string_literal: true

require 'find'

class RequireMigration
  class AutoLoadError < RuntimeError
    MESSAGE = "Can not find any migration file for `%{file_name}`!\n" \
              "You can try to provide the migration file name manually."

    def initialize(file_name)
      message = format(MESSAGE, file_name: file_name)

      super(message)
    end
  end

  MIGRATION_FOLDERS = %w[db/migrate db/post_migrate].freeze
  SPEC_FILE_PATTERN = %r{.+/(?:\d+_)?(?<file_name>.+)_spec\.rb}

  class << self
    def require_migration!(file_name)
      file_paths = search_migration_file(file_name)
      raise AutoLoadError, file_name unless file_paths.first

      require file_paths.first
    end

    def search_migration_file(file_name)
      migration_file_pattern = /\A\d+_#{file_name}\.rb\z/

      migration_folders.flat_map do |path|
        migration_path = Rails.root.join(path).to_s

        Find.find(migration_path).select { |m| migration_file_pattern.match? File.basename(m) }
      end
    end

    private

    def migration_folders
      MIGRATION_FOLDERS
    end
  end
end

RequireMigration.prepend_mod_with('RequireMigration')

def require_migration!(file_name = nil)
  location_info = caller_locations.first.path.match(RequireMigration::SPEC_FILE_PATTERN)
  file_name ||= location_info[:file_name]

  RequireMigration.require_migration!(file_name)
end
