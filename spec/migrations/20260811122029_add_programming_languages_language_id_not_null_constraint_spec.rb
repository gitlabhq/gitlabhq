# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddProgrammingLanguagesLanguageIdNotNullConstraint,
  migration: :gitlab_main_cell_local,
  feature_category: :source_code_management do
  let(:constraint_name) { 'check_4e6f0ff707' }
  let(:constraints) do
    Gitlab::Database::PostgresConstraint.check_constraints
      .by_table_identifier('public.programming_languages')
  end

  before do
    remove_constraint
  end

  after do
    remove_constraint
    add_constraint
  end

  context 'when on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'adds a NOT VALID check constraint' do
      migrate!

      expect(constraints).to include(
        have_attributes(name: constraint_name, definition: 'CHECK ((language_id IS NOT NULL)) NOT VALID')
      )
    end

    it 'removes the check constraint when rolled back' do
      migrate!
      schema_migrate_down!

      expect(constraints).not_to include(have_attributes(name: constraint_name))
    end
  end

  context 'when not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'does not add the check constraint' do
      migrate!

      expect(constraints).not_to include(have_attributes(name: constraint_name))
    end

    it 'does not remove a pre-existing check constraint' do
      migrate!
      add_constraint

      schema_migrate_down!

      expect(constraints).to include(have_attributes(name: constraint_name))
    end
  end

  def remove_constraint
    ApplicationRecord.connection.execute(
      'ALTER TABLE programming_languages DROP CONSTRAINT IF EXISTS check_4e6f0ff707'
    )
  end

  def add_constraint
    ApplicationRecord.connection.execute(
      <<~SQL
        ALTER TABLE programming_languages
        ADD CONSTRAINT check_4e6f0ff707 CHECK (language_id IS NOT NULL) NOT VALID
      SQL
    )
  end
end
