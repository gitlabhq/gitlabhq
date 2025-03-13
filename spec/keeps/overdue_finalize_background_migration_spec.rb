# frozen_string_literal: true

require 'spec_helper'
require './keeps/overdue_finalize_background_migration'

MigrationRecord = Struct.new(:id, :finished_at, :updated_at, :gitlab_schema)

RSpec.describe Keeps::OverdueFinalizeBackgroundMigration, feature_category: :tooling do
  subject(:keep) { described_class.new }

  describe '#initialize_change' do
    let(:migration) { { 'feature_category' => 'shared' } }
    let(:feature_category) { migration['feature_category'] }
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01", gitlab_schema: 'gitlab_main')
    end

    let(:job_name) { "test_background_migration" }
    let(:last_migration_file) { "db/post_migrate/20200331140101_queue_test_background_migration.rb" }
    let(:groups_helper) { instance_double(::Keeps::Helpers::Groups) }
    let(:identifiers) { [described_class.new.class.name.demodulize, job_name] }

    subject(:change) { keep.initialize_change(migration, migration_record, job_name, last_migration_file) }

    before do
      allow(groups_helper).to receive(:labels_for_feature_category)
        .with(feature_category)
        .and_return([])

      allow(groups_helper).to receive(:pick_reviewer_for_feature_category)
        .with(feature_category, identifiers)
        .and_return("random-engineer")

      allow(keep).to receive(:groups_helper).and_return(groups_helper)
    end

    it 'returns a Gitlab::Housekeeper::Change', :aggregate_failures do
      expect(change).to be_a(::Gitlab::Housekeeper::Change)
      expect(change.title).to eq("Finalize migration #{job_name}")
      expect(change.identifiers).to eq(identifiers)
      expect(change.labels).to eq(['maintenance::removal'])
      expect(change.reviewers).to eq(['random-engineer'])
    end
  end

  describe '#change_description' do
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01", gitlab_schema: 'gitlab_main')
    end

    let(:job_name) { "test_background_migration" }
    let(:last_migration_file) { "db/post_migrate/20200331140101_queue_test_background_migration.rb" }
    let(:chatops_command) { %r{/chatops run batched_background_migrations status \d+ --database main} }

    subject(:description) { keep.change_description(migration_record, job_name, last_migration_file) }

    context 'when migration code is present' do
      before do
        allow(keep).to receive(:migration_code_present?).and_return(true)
      end

      it 'does not contain a warning' do
        expect(description).not_to match(/^### Warning/)
      end

      it 'contains the database name' do
        expect(description).to match(chatops_command)
      end
    end

    context 'when migration code is absent' do
      before do
        allow(keep).to receive(:migration_code_present?).and_return(false)
      end

      it 'does contain a warning' do
        expect(description).to match(/^### Warning/)
      end
    end
  end

  describe '#truncate_migration_name' do
    let(:migration_name) { 'FinalizeHKSomeLongMigrationNameThatIsLongerThanLimitMigrationNameThatIsLongerThanLimit' }

    subject(:truncated_name) { keep.truncate_migration_name(migration_name) }

    it 'returns truncated name' do
      expect(truncated_name).to eq('FinalizeHKSomeLongMigrationNameThatIsLongerThanLimitMigrationName51841')
    end

    context 'when name is short enough' do
      let(:migration_name) { 'FinalizeHKSomeShortMigrationName' }

      it 'returns the name' do
        expect(truncated_name).to eq(migration_name)
      end
    end
  end

  describe '#database_name' do
    let(:migration_record) do
      MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01", gitlab_schema: gitlab_schema)
    end

    subject(:database_name) { keep.database_name(migration_record) }

    context 'when schema is gitlab_main_cell' do
      let(:gitlab_schema) { 'gitlab_main_cell' }

      it 'returns the database name' do
        expect(database_name).to eq('main')
      end
    end

    context 'when schema is gitlab_main' do
      let(:gitlab_schema) { 'gitlab_main' }

      it 'returns the database name' do
        expect(database_name).to eq('main')
      end
    end

    context 'when using multiple databases' do
      before do
        skip_if_shared_database(:ci)
      end

      context 'when schema is gitlab_ci' do
        let(:gitlab_schema) { 'gitlab_ci' }

        it 'returns the database name' do
          expect(database_name).to eq('ci')
        end
      end
    end
  end
end
