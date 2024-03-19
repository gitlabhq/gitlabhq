# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCodeSuggestionsNamespaceSettings, schema: 20230616082958, feature_category: :code_suggestions do # rubocop:disable Layout/LineLength
  let(:namespaces_table) { table(:namespaces) }
  let(:namespace_settings_table) { table(:namespace_settings) }

  let(:group_namespace) { namespaces_table.create!(name: 'Group#1', type: 'Group', path: 'group') }
  let(:user_namespace) { namespaces_table.create!(name: 'User#1', type: 'User', path: 'user') }
  let(:project_namespace) { namespaces_table.create!(name: 'Project#1', type: 'Project', path: 'project') }

  subject(:perform_migration) do
    described_class.new(
      start_id: namespace_settings_table.minimum(:namespace_id),
      end_id: namespace_settings_table.maximum(:namespace_id),
      batch_table: :namespace_settings,
      batch_column: :namespace_id,
      sub_batch_size: 3,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  before do
    namespace_settings_table.create!(namespace_id: group_namespace.id, code_suggestions: false)
    namespace_settings_table.create!(namespace_id: user_namespace.id, code_suggestions: true)
    namespace_settings_table.create!(namespace_id: project_namespace.id, code_suggestions: true)
  end

  it 'updates the code suggestions values only for group and user namespace', :aggregate_failures do
    expect { perform_migration }
      .to change { namespace_settings_table.find_by_namespace_id(group_namespace.id).code_suggestions }.to(true)
      .and change { namespace_settings_table.find_by_namespace_id(user_namespace.id).code_suggestions }.to(false)

    expect(namespace_settings_table.find_by_namespace_id(project_namespace.id).code_suggestions).to eq(true)
  end
end
