# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CleanupWebHookLogsDailyShardingKeyOrphans, feature_category: :webhooks do
  let(:connection) { ApplicationRecord.connection }
  let(:organizations) { table(:organizations) }
  let(:web_hooks) { table(:web_hooks) }
  let(:web_hook_logs_daily) { table(:web_hook_logs_daily) }

  let(:organization) { organizations.create!(name: 'Default', path: 'default') }
  let(:hook) { web_hooks.create!(type: 'SystemHook', organization_id: organization.id) }

  before do
    # Drop the trigger and constraint so we can insert rows with all sharding keys NULL
    # (the trigger would otherwise assign them and the constraint would reject them).
    drop_trigger_and_constraint
  end

  after do
    restore_trigger_and_constraint
  end

  subject(:perform_migration) do
    described_class.new(
      start_cursor: [web_hook_logs_daily.minimum(:id), web_hook_logs_daily.minimum(:created_at)],
      end_cursor: [web_hook_logs_daily.maximum(:id), web_hook_logs_daily.maximum(:created_at)],
      batch_table: :web_hook_logs_daily,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: connection
    ).perform
  end

  it 'deletes only constraint-violating rows whose parent web_hook no longer exists' do
    # violates the constraint (all keys NULL) and the parent is gone -> deleted
    violating_orphan = create_log(web_hook_id: deleted_web_hook_id)
    # violates the constraint but the parent still exists -> kept (VALIDATE would surface it)
    violating_with_parent = create_log(web_hook_id: hook.id)
    # satisfies the constraint but the parent is gone -> kept (valid log of a deleted hook)
    valid_orphan = create_log(web_hook_id: deleted_web_hook_id, organization_id: organization.id)
    # satisfies the constraint and the parent exists -> kept
    valid_with_parent = create_log(web_hook_id: hook.id, organization_id: organization.id)

    perform_migration

    expect(web_hook_logs_daily.where(id: violating_orphan.id)).not_to exist
    expect(web_hook_logs_daily.where(id: violating_with_parent.id)).to exist
    expect(web_hook_logs_daily.where(id: valid_orphan.id)).to exist
    expect(web_hook_logs_daily.where(id: valid_with_parent.id)).to exist
  end

  it 'deletes no more than the violating orphans across multiple sub-batches' do
    # sub_batch_size of 1 forces several sub-batches so a mis-scoped materialized CTE (deleting
    # outside the sub-batch, or the classic CTE-dropped-DELETE that wipes the whole table)
    # would surface here.
    violating_orphans = Array.new(3) { create_log(web_hook_id: deleted_web_hook_id) }
    keepers = [
      create_log(web_hook_id: hook.id), # violating, parent exists
      create_log(web_hook_id: deleted_web_hook_id, organization_id: organization.id), # valid, orphan
      create_log(web_hook_id: hook.id, organization_id: organization.id) # valid, parent exists
    ]

    perform_migration

    expect(web_hook_logs_daily.where(id: violating_orphans.map(&:id))).not_to exist
    keepers.each { |keeper| expect(web_hook_logs_daily.where(id: keeper.id)).to exist }
    # No row outside the violating orphans was touched.
    expect(web_hook_logs_daily.count).to eq(keepers.size)
  end

  private

  # Creates a web_hook and deletes it, returning an id that no longer points to a row
  # (web_hook_logs_daily has no foreign key to web_hooks, so such orphans can exist).
  def deleted_web_hook_id
    web_hooks.create!(type: 'SystemHook', organization_id: organization.id).id.tap do |id|
      web_hooks.where(id: id).delete_all
    end
  end

  def create_log(web_hook_id:, organization_id: nil, group_id: nil, project_id: nil)
    web_hook_logs_daily.create!(
      web_hook_id: web_hook_id,
      trigger: 'push_hooks',
      url: 'http://example.com',
      request_headers: {},
      request_data: {},
      response_headers: {},
      response_body: '',
      response_status: '200',
      execution_duration: 0.1,
      internal_error_message: '',
      created_at: Time.current,
      updated_at: Time.current,
      organization_id: organization_id,
      group_id: group_id,
      project_id: project_id
    )
  end

  def drop_trigger_and_constraint
    connection.execute(<<~SQL)
      DROP TRIGGER IF EXISTS trigger_web_hook_logs_daily_assign_sharding_keys ON web_hook_logs_daily;
      ALTER TABLE web_hook_logs_daily DROP CONSTRAINT IF EXISTS check_19dc80d658;
    SQL
  end

  def restore_trigger_and_constraint
    # Restore the constraint as NOT VALID to match the production schema state: validation is
    # deferred to a later release. Re-adding it validated would leak a convalidated constraint
    # into the shared test schema (DDL is not rolled back by transactional fixtures) and trip
    # spec/lib/gitlab/organizations/sharding_key_spec.rb. NOT VALID also skips the existing-row
    # scan, so no pre-delete is needed. CREATE OR REPLACE keeps this safe if the before hook
    # ever fails mid-execution and leaves the trigger in place.
    connection.execute(<<~SQL)
      ALTER TABLE web_hook_logs_daily DROP CONSTRAINT IF EXISTS check_19dc80d658;
      ALTER TABLE web_hook_logs_daily
        ADD CONSTRAINT check_19dc80d658 CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;
      CREATE OR REPLACE TRIGGER trigger_web_hook_logs_daily_assign_sharding_keys BEFORE INSERT OR UPDATE
        ON web_hook_logs_daily FOR EACH ROW
        EXECUTE FUNCTION trigger_web_hook_logs_daily_assign_sharding_keys();
    SQL
  end
end
