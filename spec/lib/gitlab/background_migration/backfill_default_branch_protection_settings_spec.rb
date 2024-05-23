# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDefaultBranchProtectionSettings, feature_category: :source_code_management do
  let(:namespaces_table) { table(:namespaces) }
  let(:namespace_settings_table) { table(:namespace_settings) }
  let(:protected_fully) do
    {
      "allow_force_push" => false,
      "allowed_to_merge" => [{ "access_level" => 40 }],
      "allowed_to_push" => [{ "access_level" => 40 }]
    }
  end

  let(:protection_none) do
    {
      "allow_force_push" => true,
      "allowed_to_merge" => [{ "access_level" => 30 }],
      "allowed_to_push" => [{ "access_level" => 30 }]
    }
  end

  let(:user_namespace) do
    namespaces_table.create!(name: 'user_namespace', path: 'path-2', type: 'User', default_branch_protection: nil)
  end

  let(:group_namespace) do
    namespaces_table.create!(name: 'group_namespace', path: 'path-1', type: 'Group', default_branch_protection: nil)
  end

  let(:group_two_namespace) do
    namespaces_table.create!(name: 'group_two_namespace', path: 'path-4', type: 'Group', default_branch_protection: 0)
  end

  let(:start_id) { user_namespace.id }
  let(:end_id) { group_two_namespace.id }

  subject(:perform_migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  before do
    namespace_settings_table.create!(namespace_id: user_namespace.id,
      default_branch_protection_defaults: protected_fully)
    namespace_settings_table.create!(namespace_id: group_namespace.id,
      default_branch_protection_defaults: protection_none)
    namespace_settings_table.create!(namespace_id: group_two_namespace.id,
      default_branch_protection_defaults: protection_none)
  end

  it 'updates default_branch_protection_defaults to a correct value', :aggregate_failures do
    expect(ActiveRecord::QueryRecorder.new { perform_migration }.count).to eq(7)

    expect(migrated_attribute(user_namespace.id)).to eq(protected_fully)
    expect(migrated_attribute(group_namespace.id)).to eq({})
    expect(migrated_attribute(group_two_namespace.id)).to eq(protection_none)
  end

  context 'when all the namespaces have `default_branch_protection` set' do
    let(:user_namespace) do
      namespaces_table.create!(name: 'user_namespace', path: 'path-2', type: 'User', default_branch_protection: 0)
    end

    let(:group_namespace) do
      namespaces_table.create!(name: 'group_namespace', path: 'path-1', type: 'Group', default_branch_protection: 0)
    end

    it 'does not update the settings' do
      expect(ActiveRecord::QueryRecorder.new { perform_migration }.count).to eq(7)

      expect(migrated_attribute(user_namespace.id)).to eq(protected_fully)
      expect(migrated_attribute(group_namespace.id)).to eq(protection_none)
      expect(migrated_attribute(group_two_namespace.id)).to eq(protection_none)
    end
  end

  def migrated_attribute(namespace_id)
    namespace_settings_table.find(namespace_id).default_branch_protection_defaults
  end
end
