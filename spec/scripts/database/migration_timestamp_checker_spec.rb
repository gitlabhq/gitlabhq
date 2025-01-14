# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/database/migration_timestamp_checker'

RSpec.describe MigrationTimestampChecker, feature_category: :database do
  subject(:checker) { described_class.new }

  before do
    stub_const('MigrationTimestampChecker::MIGRATION_DIRS', [db_migration_path])
  end

  describe "#check" do
    let(:db_migration_path) { 'spec/fixtures/migrations/db/post_migrate' }

    subject(:check) { checker.check }

    context "when migrations are valid" do
      it { expect(check).to be_nil }
    end

    context 'when a migration does not have a timestamp' do
      let(:db_migration_path) { 'spec/fixtures/migrations/db/migrate' }

      it 'raises an error' do
        expect { check }.to raise_error(RuntimeError)
      end
    end

    context 'when a migration is in the future' do
      let(:future_timestamp) { 1.day.from_now.strftime('%Y%m%d%H%M%S') }
      let(:file_path) { "spec/fixtures/migrations/db/post_migrate/#{future_timestamp}_future_migration.rb" }

      before do
        File.write(file_path, "This is a future migration file", mode: 'w')
      end

      after do
        File.delete("spec/fixtures/migrations/db/post_migrate/#{future_timestamp}_future_migration.rb")
      end

      it 'returns the error code' do
        expect(check.error_code).to eq(1)
      end

      it 'returns the error message' do
        expect(check.error_message).to include(
          'Invalid Timestamp was found in migrations', file_path, 'has a future timestamp'
        )
      end
    end
  end
end
