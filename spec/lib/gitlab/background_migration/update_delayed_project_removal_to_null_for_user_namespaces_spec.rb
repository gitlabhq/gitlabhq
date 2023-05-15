# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateDelayedProjectRemovalToNullForUserNamespaces,
  :migration do
  let(:namespaces_table) { table(:namespaces) }
  let(:namespace_settings_table) { table(:namespace_settings) }

  subject(:perform_migration) do
    described_class.new(
      start_id: 1,
      end_id: 30,
      batch_table: :namespace_settings,
      batch_column: :namespace_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  before do
    namespaces_table.create!(id: 1, name: 'group_namespace', path: 'path-1', type: 'Group')
    namespaces_table.create!(id: 2, name: 'user_namespace', path: 'path-2', type: 'User')
    namespaces_table.create!(id: 3, name: 'user_three_namespace', path: 'path-3', type: 'User')
    namespaces_table.create!(id: 4, name: 'group_four_namespace', path: 'path-4', type: 'Group')
    namespaces_table.create!(id: 5, name: 'group_five_namespace', path: 'path-5', type: 'Group')

    namespace_settings_table.create!(namespace_id: 1, delayed_project_removal: false)
    namespace_settings_table.create!(namespace_id: 2, delayed_project_removal: false)
    namespace_settings_table.create!(namespace_id: 3, delayed_project_removal: nil)
    namespace_settings_table.create!(namespace_id: 4, delayed_project_removal: true)
    namespace_settings_table.create!(namespace_id: 5, delayed_project_removal: nil)
  end

  it 'updates `delayed_project_removal` column to null for user namespaces', :aggregate_failures do
    expect(ActiveRecord::QueryRecorder.new { perform_migration }.count).to eq(7)

    expect(migrated_attribute(1)).to be_falsey
    expect(migrated_attribute(2)).to be_nil
    expect(migrated_attribute(3)).to be_nil
    expect(migrated_attribute(4)).to be_truthy
    expect(migrated_attribute(5)).to be_nil
  end

  def migrated_attribute(namespace_id)
    namespace_settings_table.find(namespace_id).delayed_project_removal
  end
end
