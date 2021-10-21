# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Database::GitlabSchema do
  it 'matches all the tables in the database', :aggregate_failures do
    # These tables do not need a gitlab_schema
    excluded_tables = %w(ar_internal_metadata schema_migrations)

    all_tables_in_database = ApplicationRecord.connection.tables

    all_tables_with_gitlab_schema = described_class.tables_to_schema.keys

    missing = []
    all_tables_in_database.each do |table_in_database|
      next if table_in_database.in?(excluded_tables)

      missing << table_in_database unless all_tables_with_gitlab_schema.include?(table_in_database)
    end

    extras = []
    all_tables_with_gitlab_schema.each do |table_with_gitlab_schema|
      extras << table_with_gitlab_schema unless all_tables_in_database.include?(table_with_gitlab_schema)
    end

    expect(missing).to be_empty, "Missing table(s) #{missing} not found in #{described_class}.tables_to_schema. Any new tables must be added to spec/support/database/gitlab_schemas.yml ."

    expect(extras).to be_empty, "Extra table(s) #{extras} found in #{described_class}.tables_to_schema. Any removed or renamed tables must be removed from spec/support/database/gitlab_schemas.yml ."
  end
end
