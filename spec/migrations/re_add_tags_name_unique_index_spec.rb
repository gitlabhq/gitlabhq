# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReAddTagsNameUniqueIndex, :migration, feature_category: :runner do
  let(:migration) { described_class.new }
  let(:connection) { migration.connection }

  context 'when the index already exist' do
    it 'does not do anything' do
      expect(connection).not_to receive(:add_concurrent_index)

      migration.up
    end
  end

  context 'when the index does not exist' do
    it 'creates the index' do
      connection.remove_index(:tags, name: described_class::INDEX_NAME)

      migration.up

      exists = migration.index_exists_by_name?(:tags, described_class::INDEX_NAME)
      expect(exists).to eq(true)
    end
  end
end
