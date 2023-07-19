# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass
class ClickHouseTestRunner
  def truncate_tables
    ClickHouse::Client.configuration.databases.each_key do |db|
      tables_for(db).each do |table|
        ClickHouse::Client.execute("TRUNCATE TABLE #{table}", db)
      end
    end
  end

  def ensure_schema
    return if @ensure_schema

    ClickHouse::Client.configuration.databases.each_key do |db|
      # drop all tables
      lookup_tables(db).each do |table|
        ClickHouse::Client.execute("DROP TABLE IF EXISTS #{table}", db)
      end

      # run the schema SQL files
      Dir[Rails.root.join("db/click_house/#{db}/*.sql")].each do |file|
        ClickHouse::Client.execute(File.read(file), db)
      end
    end

    @ensure_schema = true
  end

  private

  def tables_for(db)
    @tables ||= {}
    @tables[db] ||= lookup_tables(db)
  end

  def lookup_tables(db)
    ClickHouse::Client.select('SHOW TABLES', db).pluck('name')
  end
end
# rubocop: enable Gitlab/NamespacedClass

RSpec.configure do |config|
  click_house_test_runner = ClickHouseTestRunner.new

  config.around(:each, :click_house) do |example|
    with_net_connect_allowed do
      click_house_test_runner.ensure_schema
      click_house_test_runner.truncate_tables

      example.run
    end
  end
end
