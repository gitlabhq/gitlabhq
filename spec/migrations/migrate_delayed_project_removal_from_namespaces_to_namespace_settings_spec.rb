# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe MigrateDelayedProjectRemovalFromNamespacesToNamespaceSettings, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:namespace_settings) { table(:namespace_settings) }

  let!(:namespace_wo_settings) { namespaces.create!(name: generate(:name), path: generate(:name), delayed_project_removal: true) }
  let!(:namespace_wo_settings_delay_false) { namespaces.create!(name: generate(:name), path: generate(:name), delayed_project_removal: false) }
  let!(:namespace_w_settings_delay_true) { namespaces.create!(name: generate(:name), path: generate(:name), delayed_project_removal: true) }
  let!(:namespace_w_settings_delay_false) { namespaces.create!(name: generate(:name), path: generate(:name), delayed_project_removal: false) }

  let!(:namespace_settings_delay_true) { namespace_settings.create!(namespace_id: namespace_w_settings_delay_true.id, delayed_project_removal: false, created_at: DateTime.now, updated_at: DateTime.now) }
  let!(:namespace_settings_delay_false) { namespace_settings.create!(namespace_id: namespace_w_settings_delay_false.id, delayed_project_removal: false, created_at: DateTime.now, updated_at: DateTime.now) }

  it 'migrates delayed_project_removal to namespace_settings' do
    disable_migrations_output { migrate! }

    expect(namespace_settings.count).to eq(3)

    expect(namespace_settings.find_by(namespace_id: namespace_wo_settings.id).delayed_project_removal).to eq(true)
    expect(namespace_settings.find_by(namespace_id: namespace_wo_settings_delay_false.id)).to be_nil

    expect(namespace_settings_delay_true.reload.delayed_project_removal).to eq(true)
    expect(namespace_settings_delay_false.reload.delayed_project_removal).to eq(false)
  end
end
