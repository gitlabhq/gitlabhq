# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveOldAsyncFkValidationTableNameLengthConstraint, schema: 20260408183511,
  feature_category: :database do
  let(:migration) { described_class.new }
  let(:postgres_async_fk_validations) { table(:postgres_async_foreign_key_validations) }
  let(:old_length) { Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH }
  let(:long_table_name) { "#{'a' * old_length}.#{'b' * old_length}" }

  describe '.up' do
    it 'allows inserting longer table names' do
      migration.up

      expect do
        postgres_async_fk_validations.create!(
          name: 'some_constraint',
          table_name: long_table_name
        )
      end.not_to raise_error
    end
  end

  describe '.down' do
    it 'disallows inserting longer table names' do
      migration.down

      expect do
        postgres_async_fk_validations.create!(
          name: 'some_constraint',
          table_name: long_table_name
        )
      end.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'cleans up records with too long table_name' do
      migration.up

      # Delete
      postgres_async_fk_validations.create!(
        name: 'some_constraint',
        table_name: long_table_name
      )

      # Keep
      postgres_async_fk_validations.create!(
        name: 'other_constraint',
        table_name: 'short_name'
      )

      migration.down

      fk_validations = postgres_async_fk_validations.all
      expect(fk_validations.size).to eq(1)

      expect(fk_validations.first.name).to eq('other_constraint')
    end
  end
end
