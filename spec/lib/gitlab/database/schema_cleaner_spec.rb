# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaCleaner, feature_category: :database do
  let(:example_schema) { fixture_file(File.join('gitlab', 'database', 'structure_example.sql')) }
  let(:io) { StringIO.new }

  subject do
    described_class.new(example_schema).clean(io)
    io.string
  end

  it 'removes comments on extensions' do
    expect(subject).not_to include('COMMENT ON EXTENSION')
  end

  it 'removes CVE-2025-8714 commands' do
    expect(subject).not_to include('\restrict y3wouDIYP3FMwyd8IGypIuseLnvvBg5K9lzspwH03FEuizx9xcZzUByeEjJdABC')
    expect(subject).not_to include('\unrestrict y3wouDIYP3FMwyd8IGypIuseLnvvBg5K9lzspwH03FEuizx9xcZzUByeEjJdABC')
  end

  it 'no assumption about public being the default schema' do
    expect(subject).not_to match(/public\.\w+/)
  end

  it 'cleans up all the gitlab_schema_prevent_write table triggers' do
    expect(subject).not_to match(/CREATE TRIGGER gitlab_schema_write_trigger_for_\w+/)
    expect(subject).not_to match(/FOR EACH STATEMENT EXECUTE FUNCTION gitlab_schema_prevent_write/)
  end

  it 'cleans up all the gitlab_schema_prevent_write with schema prefix' do
    trigger_statement = <<~SQL.strip
      CREATE TRIGGER gitlab_schema_write_trigger_for_p_ci_pipeline_iids_00
      BEFORE INSERT OR DELETE OR UPDATE OR TRUNCATE ON gitlab_partitions_static.p_ci_pipeline_iids_00
      FOR EACH STATEMENT EXECUTE FUNCTION gitlab_schema_prevent_write();
    SQL

    expect(subject).not_to include(trigger_statement)
  end

  it 'keeps the lock_writes trigger functions' do
    expect(subject).to match(/CREATE FUNCTION gitlab_schema_prevent_write/)
  end

  it 'cleans up the full schema as expected (blackbox test with example)' do
    expected_schema = fixture_file(File.join('gitlab', 'database', 'structure_example_cleaned.sql'))

    expect(subject).to eq(expected_schema)
  end
end
