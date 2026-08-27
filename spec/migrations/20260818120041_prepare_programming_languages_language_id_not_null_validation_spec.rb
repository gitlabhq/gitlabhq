# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe PrepareProgrammingLanguagesLanguageIdNotNullValidation,
  migration: :gitlab_main_cell_local,
  feature_category: :source_code_management do
  let(:table_name) { 'programming_languages' }
  let(:constraint_name) { 'check_4e6f0ff707' }
  let(:validation_model) do
    Gitlab::Database::AsyncConstraints::PostgresAsyncConstraintValidation
  end

  let(:validations) do
    validation_model.where(
      table_name: table_name,
      name: constraint_name,
      constraint_type: :check_constraint
    )
  end

  let(:constraints) do
    Gitlab::Database::PostgresConstraint.check_constraints
      .by_table_identifier("public.#{table_name}")
  end

  before do
    remove_constraint
    validations.delete_all
    add_constraint
  end

  after do
    validations.delete_all
    remove_constraint
  end

  context 'when on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'queues the check constraint validation' do
      migrate!

      expect(validations).to contain_exactly(
        have_attributes(table_name: table_name, name: constraint_name, constraint_type: 'check_constraint')
      )
    end

    it 'removes the queued validation when rolled back', :aggregate_failures do
      migrate!

      schema_migrate_down!

      expect(validations).to be_empty
      expect(constraints).to include(have_attributes(name: constraint_name))
    end
  end

  context 'when not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'does not queue the check constraint validation' do
      migrate!

      expect(validations).to be_empty
    end

    it 'does not remove a pre-existing queued validation when rolled back' do
      migrate!
      validations.create!

      schema_migrate_down!

      expect(validations).to exist
    end
  end

  def add_constraint
    ApplicationRecord.connection.execute(
      <<~SQL
        ALTER TABLE programming_languages
        ADD CONSTRAINT check_4e6f0ff707 CHECK (language_id IS NOT NULL) NOT VALID
      SQL
    )
  end

  def remove_constraint
    ApplicationRecord.connection.execute(
      'ALTER TABLE programming_languages DROP CONSTRAINT IF EXISTS check_4e6f0ff707'
    )
  end
end
