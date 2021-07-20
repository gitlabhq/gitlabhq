# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaMigrations::Context do
  let(:connection) { ActiveRecord::Base.connection }

  let(:context) { described_class.new(connection) }

  describe '#schema_directory' do
    it 'returns db/schema_migrations' do
      expect(context.schema_directory).to eq(File.join(Rails.root, 'db/schema_migrations'))
    end

    context 'multiple databases' do
      let(:connection) { Ci::BaseModel.connection }

      it 'returns a directory path that is database specific' do
        skip_if_multiple_databases_not_setup

        expect(context.schema_directory).to eq(File.join(Rails.root, 'db/ci_schema_migrations'))
      end
    end
  end

  describe '#versions_to_create' do
    before do
      allow(connection).to receive_message_chain(:schema_migration, :all_versions).and_return(migrated_versions)

      migrations_struct = Struct.new(:version)
      migrations = file_versions.map { |version| migrations_struct.new(version) }
      allow(connection).to receive_message_chain(:migration_context, :migrations).and_return(migrations)
    end

    let(:version1) { '20200123' }
    let(:version2) { '20200410' }
    let(:version3) { '20200602' }
    let(:version4) { '20200809' }

    let(:migrated_versions) { file_versions }
    let(:file_versions) { [version1, version2, version3, version4] }

    context 'migrated versions is the same as migration file versions' do
      it 'returns migrated versions' do
        expect(context.versions_to_create).to eq(migrated_versions)
      end
    end

    context 'migrated versions is subset of migration file versions' do
      let(:migrated_versions) { [version1, version2] }

      it 'returns migrated versions' do
        expect(context.versions_to_create).to eq(migrated_versions)
      end
    end

    context 'migrated versions is superset of migration file versions' do
      let(:migrated_versions) { file_versions + ['20210809'] }

      it 'returns file versions' do
        expect(context.versions_to_create).to eq(file_versions)
      end
    end

    context 'migrated versions has slightly different versions to migration file versions' do
      let(:migrated_versions) { [version1, version2, version3, version4, '20210101'] }
      let(:file_versions) { [version1, version2, version3, version4, '20210102'] }

      it 'returns the common set' do
        expect(context.versions_to_create).to eq([version1, version2, version3, version4])
      end
    end
  end

  def skip_if_multiple_databases_not_setup
    skip 'Skipping because multiple databases not set up' unless Gitlab::Database.has_config?(:ci)
  end
end
