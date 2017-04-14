class FakeRenameReservedPathMigration < ActiveRecord::Migration
  include Gitlab::Database::RenameReservedPathsMigration
end
