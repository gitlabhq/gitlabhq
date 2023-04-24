# frozen_string_literal: true
require 'spec_helper'

RSpec.shared_examples 'validate path globs' do |path_globs|
  it 'returns an array of path globs' do
    expect(path_globs).to be_an(Array)
    expect(path_globs).to all(be_an(Pathname))
  end
end

RSpec.shared_examples 'validate schema data' do |tables_and_views|
  it 'all tables and views have assigned a known gitlab_schema' do
    expect(tables_and_views).to all(
      match([be_a(String), be_in(Gitlab::Database.schemas_to_base_models.keys.map(&:to_sym))])
    )
  end
end

RSpec.describe Gitlab::Database::GitlabSchema, feature_category: :database do
  shared_examples 'maps table name to table schema' do
    using RSpec::Parameterized::TableSyntax

    where(:name, :classification) do
      'ci_builds'                              | :gitlab_ci
      'my_schema.ci_builds'                    | :gitlab_ci
      'my_schema.ci_runner_machine_builds_100' | :gitlab_ci
      'my_schema._test_gitlab_main_table'      | :gitlab_main
      'information_schema.columns'             | :gitlab_internal
      'audit_events_part_5fc467ac26'           | :gitlab_main
      '_test_gitlab_main_table'                | :gitlab_main
      '_test_gitlab_ci_table'                  | :gitlab_ci
      '_test_my_table'                         | :gitlab_shared
      'pg_attribute'                           | :gitlab_internal
    end

    with_them do
      it { is_expected.to eq(classification) }
    end
  end

  describe '.deleted_views_and_tables_to_schema' do
    include_examples 'validate schema data', described_class.deleted_views_and_tables_to_schema
  end

  describe '.views_and_tables_to_schema' do
    include_examples 'validate schema data', described_class.views_and_tables_to_schema

    # This being run across different databases indirectly also tests
    # a general consistency of structure across databases
    Gitlab::Database.database_base_models.except(:geo).each do |db_config_name, db_class|
      context "for #{db_config_name} using #{db_class}" do
        let(:db_data_sources) { db_class.connection.data_sources }

        # The embedding and Geo databases do not share the same structure as all decomposed databases
        subject do
          described_class.views_and_tables_to_schema.reject { |_, v| v == :gitlab_embedding || v == :gitlab_geo }
        end

        it 'new data sources are added' do
          missing_data_sources = db_data_sources.to_set - subject.keys

          expect(missing_data_sources).to be_empty, \
            "Missing table/view(s) #{missing_data_sources.to_a} not found in " \
            "#{described_class}.views_and_tables_to_schema. " \
            "Any new tables or views must be added to the database dictionary. " \
            "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
        end

        it 'non-existing data sources are removed' do
          extra_data_sources = subject.keys.to_set - db_data_sources

          expect(extra_data_sources).to be_empty, \
            "Extra table/view(s) #{extra_data_sources.to_a} found in #{described_class}.views_and_tables_to_schema. " \
            "Any removed or renamed tables or views must be removed from the database dictionary. " \
            "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
        end
      end
    end
  end

  describe '.dictionary_path_globs' do
    include_examples 'validate path globs', described_class.dictionary_path_globs
  end

  describe '.view_path_globs' do
    include_examples 'validate path globs', described_class.view_path_globs
  end

  describe '.deleted_tables_path_globs' do
    include_examples 'validate path globs', described_class.deleted_tables_path_globs
  end

  describe '.deleted_views_path_globs' do
    include_examples 'validate path globs', described_class.deleted_views_path_globs
  end

  describe '.tables_to_schema' do
    let(:database_models) { Gitlab::Database.database_base_models.except(:geo) }
    let(:views) { database_models.flat_map { |_, m| m.connection.views }.sort.uniq }

    subject { described_class.tables_to_schema }

    it 'returns only tables' do
      tables = subject.keys

      expect(tables).not_to include(views.to_set)
    end
  end

  describe '.views_to_schema' do
    let(:database_models) { Gitlab::Database.database_base_models.except(:geo) }
    let(:tables) { database_models.flat_map { |_, m| m.connection.tables }.sort.uniq }

    subject { described_class.views_to_schema }

    it 'returns only views' do
      views = subject.keys

      expect(views).not_to include(tables.to_set)
    end
  end

  describe '.table_schemas' do
    let(:tables) { %w[users projects ci_builds] }

    subject { described_class.table_schemas(tables) }

    it 'returns the matched schemas' do
      expect(subject).to match_array %i[gitlab_main gitlab_ci].to_set
    end

    context 'when one of the tables does not have a matching table schema' do
      let(:tables) { %w[users projects unknown ci_builds] }

      context 'and undefined parameter is false' do
        subject { described_class.table_schemas(tables, undefined: false) }

        it 'includes a nil value' do
          is_expected.to match_array [:gitlab_main, nil, :gitlab_ci].to_set
        end
      end

      context 'and undefined parameter is true' do
        subject { described_class.table_schemas(tables, undefined: true) }

        it 'includes "undefined_<table_name>"' do
          is_expected.to match_array [:gitlab_main, :undefined_unknown, :gitlab_ci].to_set
        end
      end

      context 'and undefined parameter is not specified' do
        it 'includes a nil value' do
          is_expected.to match_array [:gitlab_main, :undefined_unknown, :gitlab_ci].to_set
        end
      end
    end
  end

  describe '.table_schema' do
    subject { described_class.table_schema(name) }

    it_behaves_like 'maps table name to table schema'

    context 'when mapping fails' do
      let(:name) { 'unknown_table' }

      context "and parameter 'undefined' is set to true" do
        subject { described_class.table_schema(name, undefined: true) }

        it { is_expected.to eq(:undefined_unknown_table) }
      end

      context "and parameter 'undefined' is set to false" do
        subject { described_class.table_schema(name, undefined: false) }

        it { is_expected.to be_nil }
      end

      context "and parameter 'undefined' is not set" do
        subject { described_class.table_schema(name) }

        it { is_expected.to eq(:undefined_unknown_table) }
      end
    end
  end

  describe '.table_schema!' do
    subject { described_class.table_schema!(name) }

    it_behaves_like 'maps table name to table schema'

    context 'when mapping fails' do
      let(:name) { 'non_existing_table' }

      it "raises error" do
        expect { subject }.to raise_error(
          Gitlab::Database::GitlabSchema::UnknownSchemaError,
          "Could not find gitlab schema for table #{name}: " \
          "Any new tables must be added to the database dictionary"
        )
      end
    end
  end
end
