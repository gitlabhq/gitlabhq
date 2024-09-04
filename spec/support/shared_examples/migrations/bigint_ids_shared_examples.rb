# frozen_string_literal: true

RSpec.shared_examples 'All IDs are bigint' do |from_migration: false|
  include Gitlab::Database::SchemaHelpers

  it 'expects all IDs to be of type bigint' do
    migration.up if from_migration

    Gitlab::Database::EachDatabase.each_connection do |connection, _|
      expect(connection.select_rows(find_all_id_columns_sql)).to be_empty
    end
  end
end
