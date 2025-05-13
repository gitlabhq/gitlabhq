# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/database/migration_checksum_checker'

RSpec.describe MigrationChecksumChecker, "#check", feature_category: :database do
  let(:db_migration_path) { 'spec/fixtures/migrations/db/migrate' }
  let(:checksum_dir_path) { 'spec/fixtures/migrations/db/schema_migrations' }
  let(:timestamp) { '20250320005730' }
  let(:migration_file) { "#{db_migration_path}/#{timestamp}_test_migration.rb" }
  let(:checksum_file) { "#{checksum_dir_path}/#{timestamp}" }
  let(:valid_checksum) { "85210d36999484fafe57284bc5c68985d68f48061530ff79429c84875a6420f2" }

  before do
    stub_const('MigrationChecksumChecker::MIGRATION_DIRS', [db_migration_path])
    stub_const('MigrationChecksumChecker::CHECKSUM_DIR', checksum_dir_path)
    FileUtils.mkdir_p(db_migration_path)
    FileUtils.mkdir_p(checksum_dir_path)
    File.write(migration_file, "class TestMigration < ActiveRecord::Migration[7.0]; end")
  end

  subject(:check) { described_class.new.check }

  context "when all migrations have matching checksum files" do
    before do
      File.write(checksum_file, valid_checksum)
    end

    after do
      File.delete(migration_file)
      File.delete(checksum_file)
    end

    it { expect(check).to be_nil }
  end

  context "when a migration is missing a checksum file" do
    after do
      File.delete(migration_file)
    end

    it 'returns an error result' do
      expect(check.error_code).to eq(1)
      expect(check.error_message).to include('Missing checksum file for migration')
      expect(check.error_message).to include(migration_file)
    end
  end

  context "when a migration has an empty checksum file" do
    before do
      File.write(checksum_file, "")
    end

    after do
      File.delete(migration_file)
      File.delete(checksum_file)
    end

    it 'returns an error result' do
      expect(check.error_code).to eq(1)
      expect(check.error_message).to include('Empty checksum file for migration')
      expect(check.error_message).to include(migration_file)
    end
  end

  context "when a migration has a checksum file with invalid length" do
    before do
      File.write(checksum_file, "invalid_checksum_that_is_not_64_characters")
    end

    after do
      File.delete(migration_file)
      File.delete(checksum_file)
    end

    it 'returns an error result' do
      expect(check.error_code).to eq(1)
      expect(check.error_message).to include('Invalid checksum length for migration')
      expect(check.error_message).to include(migration_file)
    end
  end

  context 'with multiple migrations' do
    let(:timestamp2) { '20250325123456' }
    let(:migration_file2) { "#{db_migration_path}/#{timestamp2}_another_migration.rb" }

    before do
      File.write(migration_file2, "class AnotherMigration < ActiveRecord::Migration[7.0]; end")
      File.write(checksum_file, valid_checksum)
    end

    after do
      File.delete(migration_file)
      File.delete(migration_file2)
      File.delete(checksum_file)
    end

    it 'reports only the missing checksum' do
      expect(check.error_message).to include(migration_file2)
      expect(check.error_message).not_to include(migration_file)
    end
  end
end
