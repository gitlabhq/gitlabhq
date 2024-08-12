# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaMigrations::Context do
  let(:connection_class) { ActiveRecord::Base }
  let(:connection) { connection_class.connection }

  let(:context) { described_class.new(connection) }

  describe '#schema_directory' do
    it 'returns db/schema_migrations' do
      expect(context.schema_directory).to eq(File.join(Rails.root, described_class.default_schema_migrations_path))
    end

    context 'CI database' do
      let(:connection_class) { Ci::ApplicationRecord }

      it 'returns a directory path that is database specific' do
        skip_if_multiple_databases_not_setup(:ci)

        expect(context.schema_directory).to eq(File.join(Rails.root, described_class.default_schema_migrations_path))
      end
    end

    context 'multiple databases', :reestablished_active_record_base do
      before do
        db_config =
          ActiveRecord::Base
            .connection_pool
            .db_config
            .configuration_hash
            .merge(configuration_overrides)

        connection_class.establish_connection(
          ActiveRecord::DatabaseConfigurations::HashConfig.new(Rails.env, 'main', db_config)
        )
      end

      context 'when `schema_migrations_path` is configured as string' do
        let(:configuration_overrides) do
          { "schema_migrations_path" => "db/ci_schema_migrations" }
        end

        it 'returns a configured directory path that' do
          skip_if_multiple_databases_not_setup(:ci)

          expect(context.schema_directory).to eq(File.join(Rails.root, 'db/ci_schema_migrations'))
        end
      end

      context 'when `schema_migrations_path` is configured as symbol' do
        let(:configuration_overrides) do
          { schema_migrations_path: "db/ci_schema_migrations" }
        end

        it 'returns a configured directory path that' do
          skip_if_multiple_databases_not_setup(:ci)

          expect(context.schema_directory).to eq(File.join(Rails.root, 'db/ci_schema_migrations'))
        end
      end
    end
  end

  describe '#versions_to_create' do
    before do
      allow(connection).to receive_message_chain(:schema_migration, :all_versions).and_return(migrated_versions)

      # Can be removed after Gitlab.next_rails?
      allow(connection).to receive_message_chain(:schema_migration, :versions).and_return(migrated_versions)

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
end
