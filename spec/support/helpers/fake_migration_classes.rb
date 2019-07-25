# frozen_string_literal: true

class FakeRenameReservedPathMigrationV1 < ActiveRecord::Migration[4.2]
  include Gitlab::Database::RenameReservedPathsMigration::V1

  def version
    '20170316163845'
  end

  def name
    "FakeRenameReservedPathMigrationV1"
  end
end
