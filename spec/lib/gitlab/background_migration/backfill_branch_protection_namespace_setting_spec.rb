# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBranchProtectionNamespaceSetting,
  feature_category: :source_code_management do
  let(:namespaces_table) { table(:namespaces) }
  let(:namespace_settings_table) { table(:namespace_settings) }
  let(:group_namespace) do
    namespaces_table.create!(name: 'group_namespace', path: 'path-1', type: 'Group', default_branch_protection: 0)
  end

  let(:user_namespace) do
    namespaces_table.create!(name: 'user_namespace', path: 'path-2', type: 'User', default_branch_protection: 1)
  end

  let(:user_three_namespace) do
    namespaces_table.create!(name: 'user_three_namespace', path: 'path-3', type: 'User', default_branch_protection: 2)
  end

  let(:group_four_namespace) do
    namespaces_table.create!(name: 'group_four_namespace', path: 'path-4', type: 'Group', default_branch_protection: 3)
  end

  let(:group_five_namespace) do
    namespaces_table.create!(name: 'group_five_namespace', path: 'path-5', type: 'Group', default_branch_protection: 4)
  end

  let(:start_id) { group_namespace.id }
  let(:end_id) { group_five_namespace.id }

  subject(:perform_migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :namespace_settings,
      batch_column: :namespace_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  before do
    namespace_settings_table.create!(namespace_id: group_namespace.id, default_branch_protection_defaults: {})
    namespace_settings_table.create!(namespace_id: user_namespace.id, default_branch_protection_defaults: {})
    namespace_settings_table.create!(namespace_id: user_three_namespace.id, default_branch_protection_defaults: {})
    namespace_settings_table.create!(namespace_id: group_four_namespace.id, default_branch_protection_defaults: {})
    namespace_settings_table.create!(namespace_id: group_five_namespace.id, default_branch_protection_defaults: {})
  end

  it 'updates default_branch_protection_defaults to a correct value', :aggregate_failures do
    expect(ActiveRecord::QueryRecorder.new { perform_migration }.count).to eq(16)

    expect(migrated_attribute(group_namespace.id)).to eq({ "allow_force_push" => true,
                                          "allowed_to_merge" => [{ "access_level" => 30 }],
                                          "allowed_to_push" => [{ "access_level" => 30 }] })
    expect(migrated_attribute(user_namespace.id)).to eq({ "allow_force_push" => false,
                                          "allowed_to_merge" => [{ "access_level" => 40 }],
                                          "allowed_to_push" => [{ "access_level" => 30 }] })
    expect(migrated_attribute(user_three_namespace.id)).to eq({ "allow_force_push" => false,
                                          "allowed_to_merge" => [{ "access_level" => 40 }],
                                          "allowed_to_push" => [{ "access_level" => 40 }] })
    expect(migrated_attribute(group_four_namespace.id)).to eq({ "allow_force_push" => false,
                                          "allowed_to_merge" => [{ "access_level" => 30 }],
                                          "allowed_to_push" => [{ "access_level" => 40 }] })
    expect(migrated_attribute(group_five_namespace.id)).to eq({ "allow_force_push" => false,
                                          "allowed_to_merge" => [{ "access_level" => 40 }],
                                          "allowed_to_push" => [{ "access_level" => 40 }],
                                          "developer_can_initial_push" => true })
  end

  def migrated_attribute(namespace_id)
    namespace_settings_table.find(namespace_id).default_branch_protection_defaults
  end
end
