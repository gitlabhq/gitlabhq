# frozen_string_literal: true

RSpec.shared_examples 'All IDs are bigint' do |from_migration: false|
  include Gitlab::Database::SchemaHelpers

  it 'expects all IDs to be of type bigint' do
    migration.up if from_migration

    Gitlab::Database::EachDatabase.each_connection do |connection, _|
      non_big_int_columns = connection.select_rows(find_all_id_columns_sql)
      non_big_int_columns.reject! do |column_info|
        table_name, column_name, = column_info

        tables_with_non_bigint_columns[table_name]&.include?(column_name)
      end

      expect(non_big_int_columns).to be_empty
    end
  end

  private

  def tables_with_non_bigint_columns
    @tables_with_non_bigint_columns ||= YAML.load_file(
      Rails.root.join('spec/support/helpers/database/tables_with_non_bigint_columns.yml')
    ) || {}
  end
end
