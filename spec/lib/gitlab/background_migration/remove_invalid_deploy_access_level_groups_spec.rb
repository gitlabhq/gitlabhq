# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveInvalidDeployAccessLevelGroups,
  :migration, schema: 20230616082958, feature_category: :continuous_delivery do
  let!(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }
  let!(:group) { table(:namespaces).create!(name: 'group', path: 'group', type: 'Group') }
  let!(:user) { table(:users).create!(email: 'deployer@example.com', username: 'deployer', projects_limit: 0) }
  let!(:protected_environment) { table(:protected_environments).create!(project_id: project.id, name: 'production') }

  let(:migration) do
    described_class.new(
      start_id: 1, end_id: 1000,
      batch_table: :protected_environment_deploy_access_levels, batch_column: :id,
      sub_batch_size: 10, pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    let!(:deploy_access_level_access_level) do
      table(:protected_environment_deploy_access_levels)
        .create!(protected_environment_id: protected_environment.id, access_level: 40)
    end

    let!(:deploy_access_level_user) do
      table(:protected_environment_deploy_access_levels)
        .create!(protected_environment_id: protected_environment.id, user_id: user.id)
    end

    let!(:deploy_access_level_group) do
      table(:protected_environment_deploy_access_levels)
        .create!(protected_environment_id: protected_environment.id, group_id: group.id)
    end

    let!(:deploy_access_level_namespace) do
      table(:protected_environment_deploy_access_levels)
        .create!(protected_environment_id: protected_environment.id, group_id: namespace.id)
    end

    it 'backfill tiers for all environments in range' do
      expect(deploy_access_level_access_level).to be_present
      expect(deploy_access_level_user).to be_present
      expect(deploy_access_level_group).to be_present
      expect(deploy_access_level_namespace).to be_present

      migration.perform

      expect { deploy_access_level_access_level.reload }.not_to raise_error
      expect { deploy_access_level_user.reload }.not_to raise_error
      expect { deploy_access_level_group.reload }.not_to raise_error
      expect { deploy_access_level_namespace.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
