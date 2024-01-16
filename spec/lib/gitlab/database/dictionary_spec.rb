# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Dictionary, feature_category: :database do
  describe '.entries' do
    it 'all tables and views are unique' do
      table_and_view_names = described_class.entries('')
      table_and_view_names += described_class.entries('views')

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

      describe '#gitlab_schema' do
        it 'returns the gitlab_schema of the table' do
          expect(database_dictionary.table_name).to eq('application_settings')
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
              .to contain_exactly(:gitlab_main_clusterwide)
          end
        end
      end

      context 'with allow_cross_transactions' do
        let(:file_path) { 'db/docs/activity_pub_releases_subscriptions.yml' }

        describe '#allow_cross_to_schemas' do
          it 'returns the list of allowed schemas' do
            expect(database_dictionary.allow_cross_to_schemas(:transactions))
              .to contain_exactly(:gitlab_main_clusterwide)
          end
        end
      end

      context 'with allow_cross_foreign_keys' do
        let(:file_path) { 'db/docs/agent_group_authorizations.yml' }

        describe '#allow_cross_to_schemas' do
          it 'returns the list of allowed schemas' do
            expect(database_dictionary.allow_cross_to_schemas(:foreign_keys))
              .to contain_exactly(:gitlab_main_clusterwide)
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
