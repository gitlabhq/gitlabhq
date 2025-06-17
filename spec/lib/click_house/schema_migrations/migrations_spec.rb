# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::SchemaMigrations::Migrations, feature_category: :database do
  let(:connection) { instance_double(ClickHouse::Connection) }
  let(:context) { instance_double(ClickHouse::SchemaMigrations::Context, connection: connection) }
  let(:migrations) { described_class.new(context) }

  describe '#load_all' do
    let(:schema_migration) { instance_double(ClickHouse::MigrationSupport::SchemaMigration) }

    before do
      allow(ClickHouse::MigrationSupport::SchemaMigration)
        .to receive(:new).with(connection).and_return(schema_migration)
      allow(schema_migration).to receive(:ensure_table)
      allow(schema_migration).to receive(:create!)
    end

    context 'when version_filenames is empty' do
      before do
        allow(migrations).to receive(:version_filenames).and_return([])
      end

      it 'returns early without creating schema migration table' do
        migrations.load_all

        expect(ClickHouse::MigrationSupport::SchemaMigration).not_to have_received(:new)
      end
    end

    context 'when version_filenames has versions' do
      let(:versions) { %w[20230705124511 20230707151359] }

      before do
        allow(migrations).to receive(:version_filenames).and_return(versions)
      end

      it 'ensures schema migration table exists' do
        migrations.load_all

        expect(schema_migration).to have_received(:ensure_table)
      end

      it 'creates migration records for each version' do
        migrations.load_all

        versions.each do |version|
          expect(schema_migration).to have_received(:create!).with(version: version)
        end
      end
    end
  end
end
