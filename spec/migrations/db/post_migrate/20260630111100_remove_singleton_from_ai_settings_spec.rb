# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveSingletonFromAiSettings, migration: :gitlab_main, feature_category: :ai_abstraction_layer do
  let(:migration) { described_class.new }
  let(:connection) { migration.connection }
  let(:constraint_name) { 'check_singleton' }
  let(:index_name) { 'index_ai_settings_on_singleton' }

  before do
    connection.add_check_constraint(:ai_settings, 'singleton IS TRUE', name: constraint_name)
    connection.add_index(:ai_settings, :singleton, unique: true, name: index_name)
  end

  describe '#up' do
    it 'removes the singleton check constraint and unique index' do
      expect(migration.check_constraint_exists?(:ai_settings, constraint_name)).to be(true)
      expect(migration.index_exists_by_name?(:ai_settings, index_name)).to be(true)

      migration.migrate(:up)

      expect(migration.check_constraint_exists?(:ai_settings, constraint_name)).to be(false)
      expect(migration.index_exists_by_name?(:ai_settings, index_name)).to be(false)
    end
  end

  describe '#down' do
    it 'does not restore the singleton check constraint or unique index' do
      migration.migrate(:up)

      migration.migrate(:down)

      expect(migration.check_constraint_exists?(:ai_settings, constraint_name)).to be(false)
      expect(migration.index_exists_by_name?(:ai_settings, index_name)).to be(false)
    end
  end
end
