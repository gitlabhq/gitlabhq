# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDefaultBranchProtectionNamespaceSetting,
  schema: 20231220225325,
  feature_category: :database do
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
    namespaces_table.create!(id: 1, name: 'group_namespace', path: 'path-1', type: 'Group',
      default_branch_protection: 0)
    namespaces_table.create!(id: 2, name: 'user_namespace', path: 'path-2', type: 'User', default_branch_protection: 1)
    namespaces_table.create!(id: 3, name: 'user_three_namespace', path: 'path-3', type: 'User',
      default_branch_protection: 2)
    namespaces_table.create!(id: 4, name: 'group_four_namespace', path: 'path-4', type: 'Group',
      default_branch_protection: 3)
    namespaces_table.create!(id: 5, name: 'group_five_namespace', path: 'path-5', type: 'Group',
      default_branch_protection: 4)

    namespace_settings_table.create!(namespace_id: 1, default_branch_protection_defaults: {})
    namespace_settings_table.create!(namespace_id: 2, default_branch_protection_defaults: {})
    namespace_settings_table.create!(namespace_id: 3, default_branch_protection_defaults: {})
    namespace_settings_table.create!(namespace_id: 4, default_branch_protection_defaults: {})
    namespace_settings_table.create!(namespace_id: 5, default_branch_protection_defaults: {})
  end

  it 'updates default_branch_protection_defaults to a correct value', :aggregate_failures do
    expect(ActiveRecord::QueryRecorder.new { perform_migration }.count).to eq(16)

    expect(migrated_attribute(1)).to eq({ "allow_force_push" => true,
                                          "allowed_to_merge" => [{ "access_level" => 30 }],
                                          "allowed_to_push" => [{ "access_level" => 30 }] })
    expect(migrated_attribute(2)).to eq({ "allow_force_push" => false,
                                          "allowed_to_merge" => [{ "access_level" => 30 }],
                                          "allowed_to_push" => [{ "access_level" => 30 }] })
    expect(migrated_attribute(3)).to eq({ "allow_force_push" => false,
                                          "allowed_to_merge" => [{ "access_level" => 40 }],
                                          "allowed_to_push" => [{ "access_level" => 40 }] })
    expect(migrated_attribute(4)).to eq({ "allow_force_push" => true,
                                          "allowed_to_merge" => [{ "access_level" => 30 }],
                                          "allowed_to_push" => [{ "access_level" => 40 }] })
    expect(migrated_attribute(5)).to eq({ "allow_force_push" => true,
                                          "allowed_to_merge" => [{ "access_level" => 30 }],
                                          "allowed_to_push" => [{ "access_level" => 40 }],
                                          "developer_can_initial_push" => true })
  end

  def migrated_attribute(namespace_id)
    namespace_settings_table.find(namespace_id).default_branch_protection_defaults
  end
end
