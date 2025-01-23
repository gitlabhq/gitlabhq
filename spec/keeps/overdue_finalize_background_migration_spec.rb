# frozen_string_literal: true

require 'spec_helper'
require './keeps/overdue_finalize_background_migration'

MigrationRecord = Struct.new(:id, :finished_at, :updated_at)

RSpec.describe Keeps::OverdueFinalizeBackgroundMigration, feature_category: :tooling do
  subject(:keep) { described_class.new }

  describe '#initialize_change' do
    let(:migration) { { 'feature_category' => 'shared' } }
    let(:feature_category) { migration['feature_category'] }
    let(:migration_record) { MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01") }
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
    let(:migration_record) { MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01") }
    let(:job_name) { "test_background_migration" }
    let(:last_migration_file) { "db/post_migrate/20200331140101_queue_test_background_migration.rb" }

    subject(:description) { keep.change_description(migration_record, job_name, last_migration_file) }

    context 'when migration code is present' do
      before do
        allow(keep).to receive(:migration_code_present?).and_return(true)
      end

      it 'does not contain a warning' do
        expect(description).not_to match(/^### Warning/)
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

  describe '#each_change' do
    let(:migration) do
      { 'milestone' => '15.0', 'migration_job_name' => 'TestMigration', 'feature_category' => 'shared' }
    end

    let(:migration_record) { MigrationRecord.new(id: 1, finished_at: "2020-04-01 12:00:01") }
    let(:queue_method_node) do
      instance_double(RuboCop::AST::SendNode, children: [nil, nil, nil,
        instance_double(RuboCop::AST::StrNode, source: 'table'),
        instance_double(RuboCop::AST::StrNode, source: 'column')])
    end

    let(:generator) { instance_double(::PostDeploymentMigration::PostDeploymentMigrationGenerator) }
    let(:groups_helper) { instance_double(::Keeps::Helpers::Groups) }

    before do
      allow(keep).to receive_messages(batched_background_migrations: { 'path/to/migration.yml' => migration },
        before_cuttoff_milestone?: true, migration_finalized?: false, fetch_migration_status: migration_record,
        last_migration_for_job: 'path/to/last_migration.rb', find_queue_method_node: queue_method_node,
        groups_helper: groups_helper
      )
      allow(groups_helper).to receive_messages(labels_for_feature_category: [],
        pick_reviewer_for_feature_category: "reviewer")
      allow(PostDeploymentMigration::PostDeploymentMigrationGenerator).to receive(:source_root)

      stub_request(:any, /.*/).to_return(status: 200, body: "", headers: {})
    end

    context 'when generator raises Rails::Generators::Error' do
      before do
        allow(::PostDeploymentMigration::PostDeploymentMigrationGenerator).to receive(:new)
          .and_raise(Rails::Generators::Error)
      end

      it 'skips to the next iteration' do
        changes = []
        keep.each_change { |change| changes << change }

        expect(changes).to be_empty
      end

      it 'does not raise the error' do
        expect { keep.each_change { |change| change } }.not_to raise_error
      end
    end
  end
end
