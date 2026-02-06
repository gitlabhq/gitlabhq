# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDisplayGitlabCreditsUserDataForNamespaceSetting,
  feature_category: :consumables_cost_management,
  schema: :latest do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:namespace_settings) { table(:namespace_settings) }

  let!(:organization) { organizations.create!(name: 'Organization', path: 'organization') }

  let!(:top_level_group) do
    namespaces.create!(name: 'top-level-group', path: 'top-level-group', type: 'Group',
      organization_id: organization.id)
  end

  let!(:subgroup) do
    namespaces.create!(
      name: 'subgroup',
      path: 'subgroup',
      type: 'Group',
      parent_id: top_level_group.id,
      organization_id: organization.id
    )
  end

  let!(:user_namespace) do
    namespaces.create!(name: 'user', path: 'user', type: 'User', organization_id: organization.id)
  end

  let!(:top_level_group_settings) do
    namespace_settings.create!(namespace_id: top_level_group.id, usage_billing: {})
  end

  let!(:subgroup_settings) do
    namespace_settings.create!(namespace_id: subgroup.id, usage_billing: {})
  end

  let!(:user_namespace_settings) do
    namespace_settings.create!(namespace_id: user_namespace.id, usage_billing: {})
  end

  let(:migration_attrs) do
    {
      start_id: namespace_settings.minimum(:namespace_id),
      end_id: namespace_settings.maximum(:namespace_id),
      batch_table: :namespace_settings,
      batch_column: :namespace_id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  subject(:migration) { described_class.new(**migration_attrs) }

  describe '#perform' do
    it 'updates all group namespace_settings' do
      migration.perform

      # Top-level group should be updated
      expect(top_level_group_settings.reload.usage_billing).to eq(
        { 'display_gitlab_credits_user_data' => true }
      )

      # Subgroup should also be updated
      expect(subgroup_settings.reload.usage_billing).to eq(
        { 'display_gitlab_credits_user_data' => true }
      )

      # User namespace should NOT be updated (not a Group)
      expect(user_namespace_settings.reload.usage_billing).to eq({})
    end

    context 'when namespace_setting already has display_gitlab_credits_user_data set to false' do
      let!(:top_level_group_with_opt_out) do
        namespaces.create!(
          name: 'opted-out-group',
          path: 'opted-out-group',
          type: 'Group',
          organization_id: organization.id
        )
      end

      let!(:opted_out_settings) do
        namespace_settings.create!(
          namespace_id: top_level_group_with_opt_out.id,
          usage_billing: { 'display_gitlab_credits_user_data' => false }
        )
      end

      it 'overwrites the existing value to true' do
        migration.perform

        # Even explicitly opted-out groups get updated
        # (product decision: enable for all existing groups)
        expect(opted_out_settings.reload.usage_billing).to eq(
          { 'display_gitlab_credits_user_data' => true }
        )
      end
    end

    context 'when namespace_setting has been set to true already' do
      let!(:group_opted_in) do
        namespaces.create!(
          name: 'opted-in-group',
          path: 'opted-in-group',
          type: 'Group',
          organization_id: organization.id
        )
      end

      let!(:opted_in_settings) do
        namespace_settings.create!(
          namespace_id: group_opted_in.id,
          usage_billing: { 'display_gitlab_credits_user_data' => true }
        )
      end

      it 'does not attempt to update the setting' do
        expect { migration.perform }.not_to change { opted_in_settings.reload.updated_at }
      end
    end

    context 'when usage_billing has other keys' do
      let!(:top_level_group_with_other_settings) do
        namespaces.create!(
          name: 'group-with-settings',
          path: 'group-with-settings',
          type: 'Group',
          organization_id: organization.id
        )
      end

      let!(:settings_with_other_keys) do
        namespace_settings.create!(
          namespace_id: top_level_group_with_other_settings.id,
          usage_billing: { 'some_other_key' => 'some_value' }
        )
      end

      it 'preserves other keys while adding display_gitlab_credits_user_data' do
        migration.perform

        expect(settings_with_other_keys.reload.usage_billing).to eq(
          { 'some_other_key' => 'some_value', 'display_gitlab_credits_user_data' => true }
        )
      end
    end
  end
end
