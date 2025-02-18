# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Dictionary, feature_category: :database do
  subject(:dictionary) { described_class.entries('') }

  describe '.entries' do
    it 'all tables and views are unique' do
      table_and_view_names = dictionary.to_a
      table_and_view_names += described_class.entries('views').to_a

      # ignore gitlab_internal due to `ar_internal_metadata`, `schema_migrations`
      table_and_view_names = table_and_view_names
        .reject { |database_dictionary| database_dictionary.schema?('gitlab_internal') }

      duplicated_tables = table_and_view_names
        .group_by(&:key_name)
        .select { |_, schemas| schemas.count > 1 }
        .keys

      expect(duplicated_tables).to be_empty, \
        "Duplicated table(s) #{duplicated_tables.to_a} found in #{described_class}.views_and_tables_to_schema. " \
        "Any duplicated table must be removed from db/docs/ or ee/db/docs/. " \
        "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
    end

    it 'builds a Dictionary with validated Entry records' do
      expect { dictionary }.not_to raise_error

      expect(dictionary).to be_instance_of(described_class)
      expect(dictionary).to all(be_instance_of(Gitlab::Database::Dictionary::Entry))
    end
  end

  describe '#to_name_and_schema_mapping' do
    it 'returns a hash of name and schema mappings' do
      expect(dictionary.to_name_and_schema_mapping).to include(
        {
          'application_settings' => :gitlab_main_clusterwide,
          'members' => :gitlab_main_cell
        }
      )
    end
  end

  describe '#find_by_table_name' do
    it 'finds an entry by table name' do
      entry = dictionary.find_by_table_name('application_settings')
      expect(entry).to be_instance_of(Gitlab::Database::Dictionary::Entry)
      expect(entry.key_name).to eq('application_settings')
      expect(entry.gitlab_schema).to eq('gitlab_main_clusterwide')
    end

    it 'returns nil if the entry is not found' do
      entry = dictionary.find_by_table_name('non_existent_table')
      expect(entry).to be_nil
    end
  end

  describe '#find_all_by_schema' do
    it 'returns an array of entries with a given schema' do
      entries = dictionary.find_all_by_schema('gitlab_main_cell')
      expect(entries).to all(be_instance_of(Gitlab::Database::Dictionary::Entry))
      expect(entries).to all(have_attributes(gitlab_schema: 'gitlab_main_cell'))
    end

    it 'returns an empty array if no entries match the schema' do
      entries = dictionary.find_all_by_schema('non_existent_schema')
      expect(entries).to be_empty
    end
  end

  describe '#find_all_having_desired_sharding_key_migration_job' do
    it 'returns an array of entries having desired sharding key migration job' do
      entries = dictionary.find_all_having_desired_sharding_key_migration_job
      expect(entries).to all(be_instance_of(Gitlab::Database::Dictionary::Entry))
      expect(entries.map(&:desired_sharding_key_migration_job_name)).to all(be_present)
    end
  end

  describe '.any_entry' do
    it 'loads an entry from any scope' do
      expect(described_class.any_entry('ci_pipelines')).to be_present # Regular table
      expect(described_class.any_entry('audit_events_archived')).to be_present # Deleted table
      expect(described_class.any_entry('postgres_constraints')).to be_present # View
      expect(described_class.any_entry('not_a_table_ever')).to be_nil
    end
  end

  describe '.entry' do
    it 'loads an Entry from the given scope' do
      expect(described_class.entry('ci_pipelines')).to be_present # Regular table
      expect(described_class.entry('audit_events_archived')).not_to be_present # Deleted table
      expect(described_class.entry('postgres_constraints')).not_to be_present # Deleted table
      expect(described_class.entry('audit_events_archived', 'deleted_tables')).to be_present # Deleted table
      expect(described_class.entry('postgres_constraints', 'views')).to be_present # View
    end
  end

  describe '::Entry' do
    subject(:database_dictionary) { described_class::Entry.new(file_path) }

    context 'for a table' do
      let(:file_path) { 'db/docs/application_settings.yml' }

      describe '#name_and_schema' do
        it 'returns the name of the table and its gitlab schema' do
          expect(database_dictionary.name_and_schema).to match_array(['application_settings', :gitlab_main_clusterwide])
        end
      end

      describe '#table_name' do
        it 'returns the name of the table' do
          expect(database_dictionary.table_name).to eq('application_settings')
        end
      end

      describe '#view_name' do
        it 'returns nil' do
          expect(database_dictionary.view_name).to be_nil
        end
      end

      describe '#milestone' do
        it 'returns the milestone in which the table was introduced' do
          expect(database_dictionary.milestone).to eq('7.7')
        end
      end

      describe '#milestone_greater_than_or_equal_to?' do
        using RSpec::Parameterized::TableSyntax

        where(:milestone, :other_milestone, :result) do
          '16.9'          | '16.10'        | false
          '16.10'         | '16.11'        | false
          '16.12'         | '16.10'        | true
          '16.11'         | '16.10'        | true
          '16.10'         | '16.10'        | true
          '16.9'          | '16.6'         | true
          '<6.0'          | '16.6'         | false
          'TODO'          | '16.6'         | false
        end

        with_them do
          before do
            allow(database_dictionary).to receive(:milestone).and_return(milestone)
          end

          it 'returns the right result' do
            expect(database_dictionary.milestone_greater_than_or_equal_to?(other_milestone)).to eq(result)
          end
        end
      end

      describe '#gitlab_schema' do
        it 'returns the gitlab_schema of the table' do
          expect(database_dictionary.table_name).to eq('application_settings')
        end
      end

      describe '#table_size' do
        it 'returns the table_size of the table' do
          expect(database_dictionary.table_size).to eq('small')
        end
      end

      describe '#schema?' do
        it 'checks if the given schema matches the schema of the table' do
          expect(database_dictionary.schema?('gitlab_main')).to eq(false)
          expect(database_dictionary.schema?('gitlab_main_clusterwide')).to eq(true)
        end
      end

      describe '#key_name' do
        it 'returns the value of the name of the table' do
          expect(database_dictionary.key_name).to eq('application_settings')
        end
      end

      describe '#desired_sharding_key_migration_job_name' do
        let(:file_path) { 'db/docs/work_item_progresses.yml' }

        it 'returns the name of the migration that backfills the desired sharding key' do
          expect(database_dictionary.desired_sharding_key_migration_job_name)
            .to eq('BackfillWorkItemProgressesNamespaceId')
        end
      end

      describe '#validate!' do
        it 'raises an error if the gitlab_schema is empty' do
          allow(database_dictionary).to receive(:gitlab_schema).and_return(nil)

          expect { database_dictionary.validate! }.to raise_error(Gitlab::Database::GitlabSchema::UnknownSchemaError)
        end
      end

      context 'with allow_cross_joins' do
        let(:file_path) { 'db/docs/achievements.yml' }

        describe '#allow_cross_to_schemas' do
          it 'returns the list of allowed schemas' do
            expect(database_dictionary.allow_cross_to_schemas(:joins))
              .to be_empty
          end
        end
      end

      context 'with allow_cross_transactions' do
        let(:file_path) { 'db/docs/activity_pub_releases_subscriptions.yml' }

        describe '#allow_cross_to_schemas' do
          it 'returns the list of allowed schemas' do
            expect(database_dictionary.allow_cross_to_schemas(:transactions))
              .to be_empty
          end
        end
      end

      context 'with allow_cross_foreign_keys' do
        let(:file_path) { 'db/docs/agent_group_authorizations.yml' }

        describe '#allow_cross_to_schemas' do
          it 'returns the list of allowed schemas' do
            expect(database_dictionary.allow_cross_to_schemas(:foreign_keys))
              .to be_empty
          end
        end
      end
    end

    context 'for a view' do
      let(:file_path) { 'db/docs/views/postgres_constraints.yml' }

      describe '#table_name' do
        it 'returns nil' do
          expect(database_dictionary.table_name).to be_nil
        end
      end

      describe '#view_name' do
        it 'returns the name of the view' do
          expect(database_dictionary.view_name).to eq('postgres_constraints')
        end
      end

      describe '#key_name' do
        it 'returns the value of the name of the view' do
          expect(database_dictionary.key_name).to eq('postgres_constraints')
        end
      end
    end
  end
end
