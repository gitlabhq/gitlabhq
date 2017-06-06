class FakeRenameReservedPathMigrationV1 < ActiveRecord::Migration
  include Gitlab::Database::RenameReservedPathsMigration::V1

  def version
    '20170316163845'
  end
end
