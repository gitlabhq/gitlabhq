# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::GitlabSchema do
  describe '.tables_to_schema' do
    it 'all tables have assigned a known gitlab_schema' do
      expect(described_class.tables_to_schema).to all(
        match([be_a(String), be_in(Gitlab::Database.schemas_to_base_models.keys.map(&:to_sym))])
      )
    end

    # This being run across different databases indirectly also tests
    # a general consistency of structure across databases
    Gitlab::Database.database_base_models.select { |k, _| k != 'geo' }.each do |db_config_name, db_class|
      context "for #{db_config_name} using #{db_class}" do
        let(:db_data_sources) { db_class.connection.data_sources }

        # The Geo database does not share the same structure as all decomposed databases
        subject { described_class.tables_to_schema.select { |_, v| v != :gitlab_geo } }

        it 'new data sources are added' do
          missing_tables = db_data_sources.to_set - subject.keys

          expect(missing_tables).to be_empty, \
            "Missing table(s) #{missing_tables.to_a} not found in #{described_class}.tables_to_schema. " \
            "Any new tables must be added to #{described_class::GITLAB_SCHEMAS_FILE}."
        end

        it 'non-existing data sources are removed' do
          extra_tables = subject.keys.to_set - db_data_sources

          expect(extra_tables).to be_empty, \
            "Extra table(s) #{extra_tables.to_a} found in #{described_class}.tables_to_schema. " \
            "Any removed or renamed tables must be removed from #{described_class::GITLAB_SCHEMAS_FILE}."
        end
      end
    end
  end

  describe '.table_schema' do
    using RSpec::Parameterized::TableSyntax

    where(:name, :classification) do
      'ci_builds'                       | :gitlab_ci
      'my_schema.ci_builds'             | :gitlab_ci
      'information_schema.columns'      | :gitlab_internal
      'audit_events_part_5fc467ac26'    | :gitlab_main
      '_test_gitlab_main_table'         | :gitlab_main
      '_test_gitlab_ci_table'           | :gitlab_ci
      '_test_my_table'                  | :gitlab_shared
      'pg_attribute'                    | :gitlab_internal
      'my_other_table'                  | :undefined_my_other_table
    end

    with_them do
      subject { described_class.table_schema(name) }

      it { is_expected.to eq(classification) }
    end
  end
end
