# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveOldAsyncIndexTableNameLengthConstraint, schema: 20230523074248, feature_category: :database do
  let(:migration) { described_class.new }
  let(:postgres_async_indexes) { table(:postgres_async_indexes) }
  let(:old_length) { Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH }
  let(:long_table_name) { "#{'a' * old_length}.#{'b' * old_length}" }

  describe '.up' do
    it 'allows inserting longer table names' do
      migration.up

      expect do
        postgres_async_indexes.create!(
          name: 'some_index',
          definition: '(id)',
          table_name: long_table_name
        )
      end.not_to raise_error
    end
  end

  describe '.down' do
    it 'disallows inserting longer table names' do
      migration.down

      expect do
        postgres_async_indexes.create!(
          name: 'some_index',
          definition: '(id)',
          table_name: long_table_name
        )
      end.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'cleans up records with too long table_name' do
      migration.up

      # Delete
      postgres_async_indexes.create!(
        name: 'some_index',
        definition: '(id)',
        table_name: long_table_name
      )

      # Keep
      postgres_async_indexes.create!(
        name: 'other_index',
        definition: '(id)',
        table_name: 'short_name'
      )

      migration.down

      async_indexes = postgres_async_indexes.all
      expect(async_indexes.size).to eq(1)

      expect(async_indexes.first.name).to eq('other_index')
    end
  end
end
