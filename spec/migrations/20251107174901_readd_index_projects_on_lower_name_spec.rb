# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReaddIndexProjectsOnLowerName, :migration, feature_category: :groups_and_projects do
  let(:migration) { described_class.new }
  let(:connection) { migration.connection }
  let(:table_name) { :projects }

  context 'when the index already exists' do
    it 'does not do anything' do
      expect(migration.index_exists_by_name?(table_name, described_class::INDEX_NAME)).to be true
      expect(connection).not_to receive(:execute).with(/CREATE INDEX/)

      migration.up

      expect(migration.index_exists_by_name?(table_name, described_class::INDEX_NAME)).to be true
    end
  end

  context 'when the index does not exist' do
    before do
      connection.execute("DROP INDEX IF EXISTS #{described_class::INDEX_NAME}")
    end

    it 'creates the index and it exists after migration' do
      migration.up

      expect(migration.index_exists_by_name?(table_name, described_class::INDEX_NAME)).to be true
    end
  end
end
