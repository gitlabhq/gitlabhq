# frozen_string_literal: true
require 'spec_helper'

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
      'ci_builds'                                    | :gitlab_ci
      'my_schema.ci_builds'                          | :gitlab_ci
      'my_schema.ci_runner_machine_builds_100'       | :gitlab_ci
      'my_schema._test_gitlab_main_table'            | :gitlab_main
      'information_schema.columns'                   | :gitlab_internal
      'audit_events_part_5fc467ac26'                 | :gitlab_main
      '_test_gitlab_main_table'                      | :gitlab_main
      '_test_gitlab_ci_table'                        | :gitlab_ci
      '_test_gitlab_main_clusterwide_table'          | :gitlab_main_clusterwide
      '_test_gitlab_main_cell_table'                 | :gitlab_main_cell
      '_test_gitlab_pm_table'                        | :gitlab_pm
      '_test_gitlab_sec_table'                       | :gitlab_sec
      '_test_my_table'                               | :gitlab_shared
      'pg_attribute'                                 | :gitlab_internal
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

    # group configurations by db_docs_dir, since then we expect all sharing this
    # to contain exactly those tables
    Gitlab::Database.all_database_connections.values.group_by(&:db_docs_dir).each do |db_docs_dir, db_infos|
      context "for #{db_docs_dir}" do
        let(:all_gitlab_schemas) { db_infos.flat_map(&:gitlab_schemas).to_set }

        let(:tables_for_gitlab_schemas) do
          described_class.views_and_tables_to_schema.select do |_, gitlab_schema|
            all_gitlab_schemas.include?(gitlab_schema)
          end
        end

        db_infos.to_h { |db_info| [db_info.name, db_info.connection_class] }
          .compact.each do |db_config_name, connection_class|
          context "validates '#{db_config_name}' using '#{connection_class}'" do
            let(:data_sources) { connection_class.connection.data_sources }

            it 'new data sources are added' do
              missing_data_sources = data_sources.to_set - tables_for_gitlab_schemas.keys

              expect(missing_data_sources).to be_empty, \
                "Missing table/view(s) #{missing_data_sources.to_a} not found in " \
                "#{described_class}.views_and_tables_to_schema. " \
                "Any new tables or views must be added to the database dictionary. " \
                "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
            end

            it 'non-existing data sources are removed' do
              extra_data_sources = tables_for_gitlab_schemas.keys.to_set - data_sources

              expect(extra_data_sources).to be_empty, \
                "Extra table/view(s) #{extra_data_sources.to_a} found in " \
                "#{described_class}.views_and_tables_to_schema. " \
                "Any removed or renamed tables or views must be removed from the database dictionary. " \
                "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
            end
          end
        end
      end
    end
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

  describe '.table_schemas!' do
    let(:tables) { %w[projects issues ci_builds] }

    subject { described_class.table_schemas!(tables) }

    it 'returns the matched schemas' do
      expect(subject).to match_array %i[gitlab_main_cell gitlab_ci].to_set
    end

    context 'when one of the tables does not have a matching table schema' do
      let(:tables) { %w[namespaces projects unknown ci_builds] }

      it 'raises error' do
        expect { subject }.to raise_error(/Could not find gitlab schema for table unknown/)
      end
    end
  end

  describe '.table_schema' do
    subject { described_class.table_schema(name) }

    it_behaves_like 'maps table name to table schema'

    context 'when mapping fails' do
      let(:name) { 'unknown_table' }

      it { is_expected.to be_nil }
    end

    context 'when an index name is used as the table name' do
      before do
        ApplicationRecord.connection.execute(<<~SQL)
          CREATE INDEX index_on_projects ON public.projects USING gin (name gin_trgm_ops)
        SQL
      end

      let(:name) { 'index_on_projects' }

      it { is_expected.to be_nil }
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
          "Any new or deleted tables must be added to the database dictionary " \
          "See https://docs.gitlab.com/ee/development/database/database_dictionary.html"
        )
      end
    end

    context 'gitlab_main_clusterwide and gitlab_main_cell allows' do
      let!(:gitlab_schemas) { %w[gitlab_main_clusterwide gitlab_main_cell] }

      it 'forbids explicit allows on cross joins on individual tables' do
        # Because we allow cross joins and cross database modifications across
        # via https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145669
        # on both of these schemas, we should not allow them explicitly on tables anymore

        tables = ::Gitlab::Database::Dictionary.entries.select do |entry|
          gitlab_schemas.include?(entry.gitlab_schema) &&
            (entry.allow_cross_to_schemas('joins') & gitlab_schemas.map(&:to_sym)).any?
        end

        expect(tables).to be_empty,
          "Cross join queries are allowed for all gitlab_main_clusterwide and gitlab_main_cell by default"
      end

      it 'forbids explicit allows on cross database modification on individual tables' do
        # Because we allow cross joins and cross database modifications across
        # via https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145669
        # on both of these schemas, we should not allow them explicitly on tables anymore

        tables = ::Gitlab::Database::Dictionary.entries.select do |entry|
          gitlab_schemas.include?(entry.gitlab_schema) &&
            (entry.allow_cross_to_schemas('transactions') & gitlab_schemas.map(&:to_sym)).any?
        end

        expect(tables).to be_empty,
          "Cross database modifications are allowed for all gitlab_main_clusterwide and gitlab_main_cell by default"
      end
    end
  end

  context 'when testing cross schema access' do
    using RSpec::Parameterized::TableSyntax

    describe '.cross_joins_allowed?' do
      where(:schemas, :tables, :result) do
        %i[] | %w[] | true
        %i[gitlab_main] | %w[evidences] | true
        %i[gitlab_main_clusterwide gitlab_main] | %w[users evidences] | true
        %i[gitlab_main_clusterwide gitlab_ci] | %w[users ci_pipelines] | false
        %i[gitlab_main_clusterwide gitlab_main gitlab_ci] | %w[users evidences ci_pipelines] | false
        %i[gitlab_main_clusterwide gitlab_internal] | %w[users schema_migrations] | false
        %i[gitlab_main gitlab_ci] | %w[evidences schema_migrations] | false
        %i[gitlab_main_clusterwide gitlab_main gitlab_shared] | %w[users evidences detached_partitions] | true
        %i[gitlab_main_clusterwide gitlab_shared] | %w[users detached_partitions] | true
        %i[gitlab_main_clusterwide gitlab_main_cell] | %w[users namespaces] | true
        %i[gitlab_main_clusterwide gitlab_main_cell] | %w[plans namespaces] | true
        %i[gitlab_main_clusterwide gitlab_main_cell] | %w[users achievements] | true
      end

      with_them do
        it { expect(described_class.cross_joins_allowed?(schemas, tables)).to eq(result) }
      end
    end

    describe '.cross_transactions_allowed?' do
      where(:schemas, :tables, :result) do
        %i[] | %w[] | true
        %i[gitlab_main] | %w[evidences] | true
        %i[gitlab_main_clusterwide gitlab_main] | %w[users evidences] | true
        %i[gitlab_main_clusterwide gitlab_ci] | %w[users ci_pipelines] | false
        %i[gitlab_main_clusterwide gitlab_main gitlab_ci] | %w[users evidences ci_pipelines] | false
        %i[gitlab_main_clusterwide gitlab_internal] | %w[users schema_migrations] | true
        %i[gitlab_main gitlab_ci] | %w[evidences ci_pipelines] | false
        %i[gitlab_main_clusterwide gitlab_main gitlab_shared] | %w[users evidences detached_partitions] | true
        %i[gitlab_main_clusterwide gitlab_shared] | %w[users detached_partitions] | true
        %i[gitlab_main_clusterwide gitlab_main_cell] | %w[users namespaces] | true
        %i[gitlab_main_clusterwide gitlab_main_cell] | %w[plans namespaces] | true
        %i[gitlab_main_clusterwide gitlab_main_cell] | %w[users achievements] | true
      end

      with_them do
        it { expect(described_class.cross_transactions_allowed?(schemas, tables)).to eq(result) }
      end
    end

    describe '.cross_foreign_key_allowed?' do
      where(:schemas, :tables, :result) do
        %i[] | %w[] | false
        %i[gitlab_main] | %w[evidences] | true
        %i[gitlab_main_clusterwide gitlab_main] | %w[users evidences] | true
        %i[gitlab_main_clusterwide gitlab_ci] | %w[users ci_pipelines] | false
        %i[gitlab_main_clusterwide gitlab_internal] | %w[users schema_migrations] | false
        %i[gitlab_main gitlab_ci] | %w[evidences ci_pipelines] | false
        %i[gitlab_main_clusterwide gitlab_shared] | %w[users detached_partitions] | false
        %i[gitlab_main_clusterwide gitlab_main_cell] | %w[users namespaces] | true
        %i[gitlab_main_clusterwide gitlab_main_cell] | %w[plans namespaces] | true
        %i[gitlab_main_clusterwide gitlab_main_cell] | %w[users achievements] | true
        %i[gitlab_main_clusterwide gitlab_main_cell] | %w[users agent_group_authorizations] | true
      end

      with_them do
        it { expect(described_class.cross_foreign_key_allowed?(schemas, tables)).to eq(result) }
      end
    end
  end
end
