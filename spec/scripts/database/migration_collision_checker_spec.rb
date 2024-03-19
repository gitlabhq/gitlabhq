# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../scripts/database/migration_collision_checker'

RSpec.describe MigrationCollisionChecker, feature_category: :database do
  subject(:checker) { described_class.new }

  before do
    stub_const('MigrationCollisionChecker::MIGRATION_FOLDERS', [db_migration_path, elasticsearch_migration_path])
  end

  describe "#check" do
    context "when there's no collision between migrations" do
      let(:db_migration_path) { 'spec/fixtures/migrations/db/migrate/*.txt' }
      let(:elasticsearch_migration_path) { 'spec/fixtures/migrations/elasticsearch/*.txt' }

      it { expect(checker.check).to be_nil }
    end

    context 'when migration class name clashes' do
      let(:db_migration_path) { 'spec/fixtures/migrations/db/*/*.txt' }
      let(:elasticsearch_migration_path) { 'spec/fixtures/migrations/elasticsearch/*.txt' }

      it 'returns the error code' do
        expect(checker.check.error_code).to eq(1)
      end

      it 'returns the error message' do
        expect(checker.check.error_message).to include(
          'Naming collisions were found between migrations', 'ClashMigration', 'Gitlab::ClashMigrationTwo'
        )
      end
    end
  end
end
