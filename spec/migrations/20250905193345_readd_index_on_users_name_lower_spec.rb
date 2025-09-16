# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReaddIndexOnUsersNameLower, :migration, feature_category: :user_profile do
  let(:migration) { described_class.new }
  let(:connection) { migration.connection }

  context 'when the index already exists' do
    it 'does not do anything' do
      expect(migration.index_exists_by_name?(:users, described_class::INDEX_NAME)).to be true
      expect(connection).not_to receive(:execute).with(/CREATE INDEX/)

      migration.up

      expect(migration.index_exists_by_name?(:users, described_class::INDEX_NAME)).to be true
    end
  end

  context 'when the index does not exist' do
    before do
      connection.execute("DROP INDEX IF EXISTS #{described_class::INDEX_NAME}")
    end

    it 'creates the index and it exists after migration' do
      migration.up

      expect(migration.index_exists_by_name?(:users, described_class::INDEX_NAME)).to be true
    end
  end
end
