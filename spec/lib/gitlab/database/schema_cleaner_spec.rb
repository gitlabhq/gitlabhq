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

  context 'with replication objects created by rake tasks' do
    let(:example_schema) do
      <<~SQL
        CREATE TABLE issues (id bigint NOT NULL);

        CREATE FUNCTION public.siphon_alter_publication(pbl text, tbl text, op integer) RETURNS void
            LANGUAGE plpgsql SECURITY DEFINER
            SET search_path TO ''
            AS $_$
        BEGIN
          RAISE EXCEPTION 'Invalid publication name';
        END;
        $_$;

        CREATE PUBLICATION siphon_publication_main_1 WITH (publish = 'insert, update, delete, truncate');
        ALTER PUBLICATION siphon_publication_main_1 OWNER TO siphon;
        ALTER PUBLICATION siphon_publication_main_1 ADD TABLE ONLY public.issues;
        CREATE PUBLICATION geo_publication;
      SQL
    end

    it 'removes publications, which are replication config rather than schema' do
      expect(subject).not_to match(/PUBLICATION/)
    end

    it 'removes the siphon helper function, body included', :aggregate_failures do
      expect(subject).not_to include('siphon_alter_publication')
      expect(subject).not_to include('RAISE EXCEPTION')
    end

    it 'keeps the surrounding schema' do
      expect(subject).to include('CREATE TABLE issues')
    end
  end

  it 'cleans up the full schema as expected (blackbox test with example)' do
    expected_schema = fixture_file(File.join('gitlab', 'database', 'structure_example_cleaned.sql'))

    expect(subject).to eq(expected_schema)
  end
end
