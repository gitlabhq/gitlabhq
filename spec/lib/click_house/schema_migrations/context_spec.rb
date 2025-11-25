# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ClickHouse::SchemaMigrations::Context, feature_category: :database do
  let(:connection) { instance_double(ClickHouse::Connection) }
  let(:database) { :main }
  let(:context) { described_class.new(connection, database) }

  describe '#initialize' do
    it 'sets connection and database' do
      expect(context.connection).to eq(connection)
      expect(context.database).to eq(database)
    end
  end

  describe '#schema_directory' do
    it 'returns the correct schema directory path' do
      expected_path = Rails.root.join('db/click_house/schema_migrations/main').to_s
      expect(context.schema_directory).to eq(expected_path)
    end

    it 'uses the database name in the path' do
      test_context = described_class.new(connection, :test_db)
      expected_path = Rails.root.join('db/click_house/schema_migrations/test_db').to_s
      expect(test_context.schema_directory).to eq(expected_path)
    end
  end

  describe '#versions_to_create' do
    let(:schema_migration) { instance_double(ClickHouse::MigrationSupport::SchemaMigration) }

    before do
      allow(ClickHouse::MigrationSupport::SchemaMigration)
        .to receive(:new).with(connection).and_return(schema_migration)
    end

    context 'when not in test environment' do
      before do
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      it 'returns all versions from schema migration' do
        versions = %w[20230705124511 20230707151359]
        allow(schema_migration).to receive(:all_versions).and_return(versions)

        expect(context.versions_to_create).to eq(versions)
      end
    end

    context 'when in test environment' do
      before do
        allow(Rails.env).to receive(:test?).and_return(true)
      end

      it 'returns empty array' do
        expect(context.versions_to_create).to eq([])
      end
    end
  end

  describe '#current_schema_migration_files' do
    let(:schema_directory) { '/path/to/schema/migrations' }

    before do
      allow(context).to receive(:schema_directory).and_return(schema_directory)
    end

    context 'when schema directory exists' do
      before do
        allow(File).to receive(:directory?).with(schema_directory).and_return(true)
      end

      it 'returns files in the directory' do
        files = %w[20230705124511 20230707151359]
        allow(Dir).to receive(:glob).with('*', base: schema_directory).and_return(files)

        expect(context.current_schema_migration_files).to eq(files)
      end
    end

    context 'when schema directory does not exist' do
      before do
        allow(File).to receive(:directory?).with(schema_directory).and_return(false)
      end

      it 'returns empty array' do
        expect(context.current_schema_migration_files).to eq([])
      end
    end
  end
end
