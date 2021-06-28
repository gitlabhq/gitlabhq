# frozen_string_literal: true

require 'spec_helper'

# Check consistency of db/structure.sql version, migrations' timestamps, and the latest migration timestamp
# stored in the database's schema_migrations table.

RSpec.describe ActiveRecord::Schema, schema: :latest do
  let(:all_migrations) do
    migrations_directories = %w[db/migrate db/post_migrate].map { |path| Rails.root.join(path).to_s }
    migrations_paths = migrations_directories.map { |path| File.join(path, '*') }

    migrations = Dir[*migrations_paths] - migrations_directories
    migrations.map { |migration| File.basename(migration).split('_').first.to_i }.sort
  end

  let(:latest_migration_timestamp) do
    all_migrations.max
  end

  it '> schema version should equal the latest migration timestamp stored in schema_migrations table' do
    expect(latest_migration_timestamp).to eq(ActiveRecord::Migrator.current_version.to_i)
  end

  it 'the schema_migrations table contains all schema versions' do
    versions = ActiveRecord::Base.connection.execute('SELECT version FROM schema_migrations ORDER BY version').map { |m| Integer(m['version']) }

    expect(versions).to match_array(all_migrations)
  end
end
