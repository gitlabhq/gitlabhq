# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddShardingKeyTriggerToWebHookLogsDaily, :migration, feature_category: :webhooks do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:web_hooks) { table(:web_hooks) }
  let(:web_hook_logs_daily) { table(:web_hook_logs_daily) }

  let(:organization) { organizations.create!(name: 'Default', path: 'default') }

  let(:group) do
    namespaces.create!(
      name: 'test-group',
      path: 'test-group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let(:project_namespace) do
    namespaces.create!(
      name: 'test-project',
      path: 'test-project',
      organization_id: organization.id
    )
  end

  let(:project) do
    projects.create!(
      name: 'test-project',
      path: 'test-project',
      organization_id: organization.id,
      namespace_id: group.id,
      project_namespace_id: project_namespace.id
    )
  end

  let(:system_hook) do
    web_hooks.create!(
      type: 'SystemHook',
      organization_id: organization.id
    )
  end

  let(:project_hook) do
    web_hooks.create!(
      type: 'ProjectHook',
      project_id: project.id
    )
  end

  let(:group_hook) do
    web_hooks.create!(
      type: 'GroupHook',
      group_id: group.id
    )
  end

  # Create log for system hook
  let(:system_log) do
    web_hook_logs_daily.create!(
      web_hook_id: system_hook.id,
      trigger: 'push_hooks',
      url: 'http://example.com',
      request_headers: {},
      request_data: {},
      response_headers: {},
      response_body: '',
      response_status: '200',
      execution_duration: 0.1,
      internal_error_message: '',
      organization_id: nil,
      group_id: nil,
      project_id: nil
    )
  end

  # Create log for project hook
  let(:project_log) do
    web_hook_logs_daily.create!(
      web_hook_id: project_hook.id,
      trigger: 'push_hooks',
      url: 'http://example.com',
      request_headers: {},
      request_data: {},
      response_headers: {},
      response_body: '',
      response_status: '200',
      execution_duration: 0.1,
      internal_error_message: '',
      organization_id: nil,
      group_id: nil,
      project_id: nil
    )
  end

  # Create log for group hook
  let(:group_log) do
    web_hook_logs_daily.create!(
      web_hook_id: group_hook.id,
      trigger: 'push_hooks',
      url: 'http://example.com',
      request_headers: {},
      request_data: {},
      response_headers: {},
      response_body: '',
      response_status: '200',
      execution_duration: 0.1,
      internal_error_message: '',
      organization_id: nil,
      group_id: nil,
      project_id: nil
    )
  end

  describe '#up' do
    before do
      migrate!

      # Create records after the migration to test that the trigger works on new inserts
      system_log
      project_log
      group_log
    end

    it 'installs triggers that assign sharding keys from web_hooks table' do
      # Verify sharding keys were assigned correctly
      system_log.reload
      expect(system_log.organization_id).to eq(organization.id)
      expect(system_log.project_id).to be_nil
      expect(system_log.group_id).to be_nil

      project_log.reload
      expect(project_log.organization_id).to be_nil
      expect(project_log.group_id).to be_nil
      expect(project_log.project_id).to eq(project.id)

      group_log.reload
      expect(group_log.organization_id).to be_nil
      expect(group_log.group_id).to eq(group.id)
      expect(group_log.project_id).to be_nil
    end
  end
end
