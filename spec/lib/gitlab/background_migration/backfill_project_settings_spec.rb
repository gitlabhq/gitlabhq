# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectSettings, :migration, schema: 20220324165436 do
  let(:migration) { described_class.new }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:project_settings_table) { table(:project_settings) }

  let(:table_name) { 'projects' }
  let(:batch_column) { :id }
  let(:sub_batch_size) { 2 }
  let(:pause_ms) { 0 }

  subject(:perform_migration) { migration.perform(1, 30, table_name, batch_column, sub_batch_size, pause_ms) }

  before do
    namespaces_table.create!(id: 1, name: 'namespace', path: 'namespace-path', type: 'Group')
    projects_table.create!(id: 11, name: 'group-project-1', path: 'group-project-path-1', namespace_id: 1)
    projects_table.create!(id: 12, name: 'group-project-2', path: 'group-project-path-2', namespace_id: 1)
    project_settings_table.create!(project_id: 11)

    namespaces_table.create!(id: 2, name: 'namespace', path: 'namespace-path', type: 'User')
    projects_table.create!(id: 21, name: 'user-project-1', path: 'user--project-path-1', namespace_id: 2)
    projects_table.create!(id: 22, name: 'user-project-2', path: 'user-project-path-2', namespace_id: 2)
    project_settings_table.create!(project_id: 21)
  end

  it 'backfills project settings when it does not exist', :aggregate_failures do
    expect(project_settings_table.count).to eq 2

    queries = ActiveRecord::QueryRecorder.new do
      perform_migration
    end

    expect(queries.count).to eq(5)

    expect(project_settings_table.count).to eq 4
  end
end
