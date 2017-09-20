require 'spec_helper'

# Check consistency of db/schema.rb version, migrations' timestamps, and the latest migration timestamp
# stored in the database's schema_migrations table.

describe ActiveRecord::Schema do
  let(:latest_migration_timestamp) do
    migrations = Dir[Rails.root.join('db', 'migrate', '*'), Rails.root.join('db', 'post_migrate', '*')]
    migrations.map { |migration| File.basename(migration).split('_').first.to_i }.max
  end

  it '> schema version equals last migration timestamp' do
    defined_schema_version = File.open(Rails.root.join('db', 'schema.rb')) do |file|
      file.find { |line| line =~ /ActiveRecord::Schema.define/ }
    end.match(/(\d+)/)[0].to_i

    expect(defined_schema_version).to eq(latest_migration_timestamp)
  end

  it '> schema version should equal the latest migration timestamp stored in schema_migrations table' do
    expect(latest_migration_timestamp).to eq(ActiveRecord::Migrator.current_version.to_i)
  end

  it '> schema does not contain any varchar(255) leftovers from MySQL' do
    return unless ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^postgresql/
    number_of_broken_columns = File.open(Rails.root.join('db', 'schema.rb')) do |file|
      file.find_all { |line| line =~ /limit: (255|510)/ }
    end.length

    expect(number_of_broken_columns).to eq(0)
  end
end
