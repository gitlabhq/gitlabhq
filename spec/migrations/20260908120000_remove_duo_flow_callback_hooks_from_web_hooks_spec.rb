# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveDuoFlowCallbackHooksFromWebHooks, feature_category: :duo_agent_platform do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:web_hooks) { table(:web_hooks) }
  let(:web_hook_logs) { table(:web_hook_logs_daily) }

  let!(:organization) { organizations.create!(name: 'Default', path: 'default') }
  let!(:namespace) do
    namespaces.create!(name: 'test-namespace', path: 'test-namespace', organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:legacy_hook) do
    web_hooks.create!(
      name: 'legacy-flow-callback',
      type: 'Ai::DuoWorkflows::FlowCallbackHook',
      organization_id: organization.id
    )
  end

  let!(:system_hook) do
    web_hooks.create!(
      name: 'system-hook',
      type: 'SystemHook',
      organization_id: organization.id
    )
  end

  let!(:project_hook) do
    web_hooks.create!(
      name: 'project-hook',
      type: 'ProjectHook',
      project_id: project.id
    )
  end

  let!(:legacy_log) do
    web_hook_logs.create!(web_hook_id: legacy_hook.id, url: 'https://example.com/legacy')
  end

  let!(:project_log) do
    web_hook_logs.create!(web_hook_id: project_hook.id, url: 'https://example.com/project')
  end

  describe '#up' do
    it 'removes only the legacy flow callback hooks and their logs', :aggregate_failures do
      expect { migrate! }.to change { web_hooks.count }.from(3).to(2)

      expect(web_hooks.where(type: 'Ai::DuoWorkflows::FlowCallbackHook')).to be_empty
      expect(web_hooks.where(id: [system_hook.id, project_hook.id]).count).to eq(2)
      expect(web_hook_logs.where(web_hook_id: legacy_hook.id)).to be_empty
      expect(web_hook_logs.where(web_hook_id: project_hook.id)).to exist
    end

    it 'is idempotent' do
      migrate!

      expect { schema_migrate_down! && migrate! }.not_to change { web_hooks.count }
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { described_class.new.down }.not_to raise_error
    end
  end
end
