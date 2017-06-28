class FakeRenameReservedPathMigrationV1 < ActiveRecord::Migration
  include Gitlab::Database::RenameReservedPathsMigration::V1
end
