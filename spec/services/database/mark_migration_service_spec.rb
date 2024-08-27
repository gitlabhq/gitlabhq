# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::MarkMigrationService, feature_category: :database do
  let(:service) { described_class.new(connection: connection, version: version) }
  let(:version) { 1 }
  let(:connection) { ApplicationRecord.connection }

  let(:migrations) do
    [
      instance_double(
        ActiveRecord::MigrationProxy,
        version: 1,
        name: 'migration_pending',
        filename: 'db/migrate/1_migration_pending.rb'
      )
    ]
  end

  before do
    ctx = instance_double(ActiveRecord::MigrationContext, migrations: migrations)
    allow(connection).to receive(:migration_context).and_return(ctx)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    def versions
      if ::Gitlab.next_rails?
        connection.schema_migration.versions.count { |v| v == version.to_s }
      else
        ActiveRecord::SchemaMigration.where(version: version).count
      end
    end

    it 'marks the migration as successful' do
      expect { execute }
        .to change { versions }
        .by(1)

      is_expected.to be_success
    end

    context 'when the migration does not exist' do
      let(:version) { 123 }

      it { is_expected.to be_error }
      it { expect(execute.reason).to eq(:not_found) }

      it 'does not insert records' do
        expect { execute }
          .not_to change { versions }
      end
    end

    context 'when the migration was already executed' do
      before do
        allow(service).to receive(:all_versions).and_return([version])
      end

      it { is_expected.to be_error }
      it { expect(execute.reason).to eq(:invalid) }

      it 'does not insert records' do
        expect { execute }
          .not_to change { versions }
      end
    end

    context 'when the insert fails' do
      it 'returns an error response' do
        expect(service).to receive(:create_version).with(version).and_return(false)

        is_expected.to be_error
      end
    end
  end
end
