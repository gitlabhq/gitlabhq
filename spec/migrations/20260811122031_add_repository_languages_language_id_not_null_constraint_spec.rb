# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddRepositoryLanguagesLanguageIdNotNullConstraint,
  migration: :gitlab_main_org,
  feature_category: :source_code_management do
  let(:constraint_name) { 'check_732edd0c38' }
  let(:constraints) do
    Gitlab::Database::PostgresConstraint.check_constraints
      .by_table_identifier('public.repository_languages')
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
      'ALTER TABLE repository_languages DROP CONSTRAINT IF EXISTS check_732edd0c38'
    )
  end

  def add_constraint
    ApplicationRecord.connection.execute(
      <<~SQL
        ALTER TABLE repository_languages
        ADD CONSTRAINT check_732edd0c38 CHECK (language_id IS NOT NULL) NOT VALID
      SQL
    )
  end
end
