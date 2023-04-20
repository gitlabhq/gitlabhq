# frozen_string_literal: true

# Sometimes data migration specs require adding invalid test data in order to test
# the migration (e.g. adding a row with null foreign key). Certain db migrations that
# add constraints (e.g. NOT NULL constraint) prevent invalid records from being added
# and data migration from being tested. For this reason, SchemaVersionFinder can be used
# to find and use schema prior to specified one.
#
# @example
#   RSpec.describe CleanupThings, :migration,
#     schema: MigrationHelpers::SchemaVersionFinder.migration_prior(AddNotNullConstraint) do ...
#
# SchemaVersionFinder returns schema version prior to the one specified, which allows to then add
# invalid records to the database, which in return allows to properly test data migration.
module MigrationHelpers
  class SchemaVersionFinder
    def self.migrations_paths
      ActiveRecord::Migrator.migrations_paths
    end

    def self.migration_context
      ActiveRecord::MigrationContext.new(migrations_paths, ActiveRecord::SchemaMigration)
    end

    def self.migrations
      migration_context.migrations
    end

    def self.migration_prior(migration_klass)
      migrations.each_cons(2) do |previous, migration|
        break previous.version if migration.name == migration_klass.name
      end
    end
  end
end
