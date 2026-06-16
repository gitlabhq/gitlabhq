# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropOrganizationPushRulesSyncTriggers, feature_category: :source_code_management do
  include Gitlab::Database::SchemaHelpers

  let(:connection) { ApplicationRecord.connection }
  let(:insert_update_trigger_name) { 'trigger_sync_organization_push_rules_insert_update' }
  let(:insert_update_function_name) { 'sync_organization_push_rules_on_insert_update' }
  let(:delete_trigger_name) { 'trigger_sync_organization_push_rules_delete' }
  let(:delete_function_name) { 'sync_organization_push_rules_on_delete' }

  describe '#up', :aggregate_failures do
    it 'drops both triggers and both functions' do
      migrate!

      expect(trigger_exists?('push_rules', insert_update_trigger_name)).to be(false)
      expect(trigger_exists?('push_rules', delete_trigger_name)).to be(false)
      expect(function_exists?(insert_update_function_name)).to be(false)
      expect(function_exists?(delete_function_name)).to be(false)
    end
  end

  describe '#down', :aggregate_failures do
    it 'recreates both triggers and both functions' do
      migrate!
      schema_migrate_down!

      expect(trigger_exists?('push_rules', insert_update_trigger_name)).to be(true)
      expect(trigger_exists?('push_rules', delete_trigger_name)).to be(true)
      expect(function_exists?(insert_update_function_name)).to be(true)
      expect(function_exists?(delete_function_name)).to be(true)
    end
  end
end
