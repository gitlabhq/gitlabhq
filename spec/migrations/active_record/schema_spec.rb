require 'spec_helper'

# Check consistency of db/schema.rb version, migrations' timestamps, and the latest migration timestamp
# stored in the database's schema_migrations table.

describe ActiveRecord::Schema do
  let(:latest_migration_timestamp) do
    migrations_paths = %w[db/migrate db/post_migrate]
      .map { |path| Rails.root.join(*path, '*') }

    migrations = Dir[*migrations_paths]
    migrations.map { |migration| File.basename(migration).split('_').first.to_i }.max
  end

  it '> schema version equals last migration timestamp' do
    defined_schema_version = File.open(Rails.root.join('db', 'schema.rb')) do |file|
      file.find { |line| line =~ /ActiveRecord::Schema.define/ }
    end.match(/(\d{4}_\d{2}_\d{2}_\d{6})/)[0].to_i

    expect(defined_schema_version).to eq(latest_migration_timestamp)
  end

  it '> schema version should equal the latest migration timestamp stored in schema_migrations table' do
    expect(latest_migration_timestamp).to eq(ActiveRecord::Migrator.current_version.to_i)
  end
end
