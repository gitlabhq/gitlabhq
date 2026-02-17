# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillWebHookLogsDailyShardingKeys, feature_category: :webhooks do
  let(:connection) { ApplicationRecord.connection }
  let(:function_name) { 'trigger_web_hook_logs_daily_assign_sharding_keys' }
  let(:trigger_name) { function_name }
  let(:constraint_name) { 'check_19dc80d658' }

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:web_hooks) { table(:web_hooks) }
  let(:web_hook_logs_daily) { table(:web_hook_logs_daily) }

  let(:start_cursor) { [web_hook_logs_daily.minimum(:id), web_hook_logs_daily.minimum(:created_at)] }
  let(:end_cursor) { [web_hook_logs_daily.maximum(:id), web_hook_logs_daily.maximum(:created_at)] }

  let!(:organization) { organizations.create!(name: 'Default', path: 'default') }

  let!(:group) do
    namespaces.create!(
      name: 'test-group',
      path: 'test-group',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:project_namespace) do
    namespaces.create!(
      name: 'test-project',
      path: 'test-project',
      organization_id: organization.id
    )
  end

  let!(:project) do
    projects.create!(
      name: 'test-project',
      path: 'test-project',
      organization_id: organization.id,
      namespace_id: group.id,
      project_namespace_id: project_namespace.id
    )
  end

  let!(:system_hook) do
    web_hooks.create!(
      type: 'SystemHook',
      organization_id: organization.id
    )
  end

  let!(:project_hook) do
    web_hooks.create!(
      type: 'ProjectHook',
      project_id: project.id
    )
  end

  let!(:group_hook) do
    web_hooks.create!(
      type: 'GroupHook',
      group_id: group.id
    )
  end

  let!(:system_log) do
    drop_constraint_and_trigger
    record = web_hook_logs_daily.create!(
      web_hook_id: system_hook.id,
      trigger: 'push_hooks',
      url: 'http://example.com',
      request_headers: {},
      request_data: {},
      response_headers: {},
      response_body: '',
      response_status: '200',
      execution_duration: 0.1,
      internal_error_message: ''
    )
    add_constraint_and_trigger
    record
  end

  let!(:project_log) do
    drop_constraint_and_trigger
    record = web_hook_logs_daily.create!(
      web_hook_id: project_hook.id,
      trigger: 'push_hooks',
      url: 'http://example.com',
      request_headers: {},
      request_data: {},
      response_headers: {},
      response_body: '',
      response_status: '200',
      execution_duration: 0.1,
      internal_error_message: ''
    )
    add_constraint_and_trigger
    record
  end

  let!(:group_log) do
    drop_constraint_and_trigger
    record = web_hook_logs_daily.create!(
      web_hook_id: group_hook.id,
      trigger: 'push_hooks',
      url: 'http://example.com',
      request_headers: {},
      request_data: {},
      response_headers: {},
      response_body: '',
      response_status: '200',
      execution_duration: 0.1,
      internal_error_message: ''
    )
    add_constraint_and_trigger
    record
  end

  subject(:migration) do
    described_class.new(
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      batch_table: :web_hook_logs_daily,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'backfills sharding keys from web_hooks table' do
      expect(system_log.reload.organization_id).to be_nil
      expect(system_log.reload.project_id).to be_nil
      expect(system_log.reload.group_id).to be_nil

      expect(project_log.reload.organization_id).to be_nil
      expect(project_log.reload.project_id).to be_nil
      expect(project_log.reload.group_id).to be_nil

      expect(group_log.reload.organization_id).to be_nil
      expect(group_log.reload.project_id).to be_nil
      expect(group_log.reload.group_id).to be_nil

      migration.perform

      expect(system_log.reload.organization_id).to eq(organization.id)
      expect(system_log.reload.project_id).to be_nil
      expect(system_log.reload.group_id).to be_nil

      expect(project_log.reload.project_id).to eq(project.id)
      expect(project_log.reload.organization_id).to be_nil
      expect(project_log.reload.group_id).to be_nil

      expect(group_log.reload.group_id).to eq(group.id)
      expect(group_log.reload.organization_id).to be_nil
      expect(group_log.reload.project_id).to be_nil
    end

    it 'does not update records that already have sharding keys' do
      # Manually set sharding keys
      system_log.update!(organization_id: organization.id)
      project_log.update!(project_id: project.id)
      group_log.update!(group_id: group.id)

      expect { migration.perform }.not_to change { system_log.reload.updated_at }
    end
  end

  private

  def drop_constraint_and_trigger
    connection.execute(
      <<~SQL
        DROP TRIGGER IF EXISTS #{trigger_name} ON web_hook_logs_daily;

        ALTER TABLE web_hook_logs_daily DROP CONSTRAINT IF EXISTS #{constraint_name};
      SQL
    )
  end

  def add_constraint_and_trigger
    connection.execute(
      <<~SQL
        ALTER TABLE web_hook_logs_daily ADD CONSTRAINT #{constraint_name} CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;

        CREATE TRIGGER #{trigger_name} BEFORE INSERT OR UPDATE ON web_hook_logs_daily FOR EACH ROW EXECUTE FUNCTION #{function_name}();
      SQL
    )
  end
end
