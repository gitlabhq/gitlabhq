# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::GitlabSchema do
  describe '.tables_to_schema' do
    subject { described_class.tables_to_schema }

    it 'all tables have assigned a known gitlab_schema' do
      is_expected.to all(
        match([be_a(String), be_in([:gitlab_shared, :gitlab_main, :gitlab_ci])])
      )
    end

    # This being run across different databases indirectly also tests
    # a general consistency of structure across databases
    Gitlab::Database.database_base_models.each do |db_config_name, db_class|
      let(:db_data_sources) { db_class.connection.data_sources }

      context "for #{db_config_name} using #{db_class}" do
        it 'new data sources are added' do
          missing_tables = db_data_sources.to_set - subject.keys

          expect(missing_tables).to be_empty, \
            "Missing table(s) #{missing_tables.to_a} not found in #{described_class}.tables_to_schema. " \
            "Any new tables must be added to lib/gitlab/database/gitlab_schemas.yml."
        end

        it 'non-existing data sources are removed' do
          extra_tables = subject.keys.to_set - db_data_sources

          expect(extra_tables).to be_empty, \
            "Extra table(s) #{extra_tables.to_a} found in #{described_class}.tables_to_schema. " \
            "Any removed or renamed tables must be removed from lib/gitlab/database/gitlab_schemas.yml."
        end
      end
    end
  end

  describe '.table_schema' do
    using RSpec::Parameterized::TableSyntax

    where(:name, :classification) do
      'ci_builds'                       | :gitlab_ci
      'my_schema.ci_builds'             | :gitlab_ci
      'information_schema.columns'      | :gitlab_shared
      'audit_events_part_5fc467ac26'    | :gitlab_main
      '_test_gitlab_main_table'         | :gitlab_main
      '_test_gitlab_ci_table'           | :gitlab_ci
      '_test_my_table'                  | :gitlab_shared
      'pg_attribute'                    | :gitlab_shared
      'my_other_table'                  | :undefined_my_other_table
    end

    with_them do
      subject { described_class.table_schema(name) }

      it { is_expected.to eq(classification) }
    end
  end
end
