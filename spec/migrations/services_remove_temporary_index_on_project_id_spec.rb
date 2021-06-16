# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ServicesRemoveTemporaryIndexOnProjectId do
  let(:migration_instance) { described_class.new }

  it 'adds and removes temporary partial index in up and down methods' do
    reversible_migration do |migration|
      migration.before -> {
        expect(migration_instance.index_exists?(:services, :project_id, name: described_class::INDEX_NAME)).to be true
      }

      migration.after -> {
        expect(migration_instance.index_exists?(:services, :project_id, name: described_class::INDEX_NAME)).to be false
      }
    end
  end

  describe '#up' do
    context 'index does not exist' do
      it 'skips removal action' do
        migrate!

        expect { migrate! }.not_to change { migration_instance.index_exists?(:services, :project_id, name: described_class::INDEX_NAME) }
      end
    end
  end

  describe '#down' do
    context 'index already exists' do
      it 'skips creation of duplicated temporary partial index on project_id' do
        schema_migrate_down!

        expect { schema_migrate_down! }.not_to change { migration_instance.index_exists?(:services, :project_id, name: described_class::INDEX_NAME) }
      end
    end
  end
end
