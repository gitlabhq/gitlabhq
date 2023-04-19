# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateCodeSuggestionsForNamespaceSettings, schema: 20230418164957, feature_category: :code_suggestions do
  let(:namespaces_table) { table(:namespaces) }
  let(:namespace_settings_table) { table(:namespace_settings) }

  subject(:perform_migration) do
    described_class.new(
      start_id: 1,
      end_id: 5,
      batch_table: :namespace_settings,
      batch_column: :namespace_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  before do
    namespaces_table.create!(id: 1, name: 'group_namespace', path: 'path-1', type: 'Group')
    namespaces_table.create!(id: 2, name: 'subgroup', path: 'path-2', type: 'Group', parent_id: 2)
    namespaces_table.create!(id: 3, name: 'user_namespace', path: 'path-3', type: 'User')
    namespaces_table.create!(id: 4, name: 'group_four_namespace', path: 'path-4', type: 'Group')
    namespaces_table.create!(id: 5, name: 'group_five_namespace', path: 'path-5', type: 'Group')

    namespace_settings_table.create!(namespace_id: 1, code_suggestions: false)
    namespace_settings_table.create!(namespace_id: 2, code_suggestions: false)
    namespace_settings_table.create!(namespace_id: 3, code_suggestions: false)
    namespace_settings_table.create!(namespace_id: 4, code_suggestions: false)
    namespace_settings_table.create!(namespace_id: 5, code_suggestions: true)
  end

  it 'updates `code_suggestions` column to true for namespaces', :aggregate_failures do
    perform_migration

    expect(migrated_attribute(1)).to be_truthy
    expect(migrated_attribute(2)).to be_truthy
    expect(migrated_attribute(3)).to be_truthy
    expect(migrated_attribute(4)).to be_truthy
    expect(migrated_attribute(5)).to be_truthy
  end

  def migrated_attribute(namespace_id)
    namespace_settings_table.find(namespace_id).code_suggestions
  end
end
