# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveInvalidDeployAccessLevel, :migration, feature_category: :continuous_integration do
  let(:users) { table(:users) }
  let(:groups) { table(:namespaces) }
  let(:protected_environments) { table(:protected_environments) }
  let(:deploy_access_levels) { table(:protected_environment_deploy_access_levels) }

  let(:user) { users.create!(email: 'email@email.com', name: 'foo', username: 'foo', projects_limit: 0) }
  let(:group) { groups.create!(name: 'test-group', path: 'test-group') }
  let(:pe) do
    protected_environments.create!(name: 'test-pe', group_id: group.id)
  end

  let!(:invalid_access_level) do
    deploy_access_levels.create!(
      access_level: 40,
      user_id: user.id,
      group_id: group.id,
      protected_environment_id: pe.id)
  end

  let!(:group_access_level) do
    deploy_access_levels.create!(
      group_id: group.id,
      protected_environment_id: pe.id)
  end

  let!(:user_access_level) do
    deploy_access_levels.create!(
      user_id: user.id,
      protected_environment_id: pe.id)
  end

  it 'removes invalid access_level entries' do
    expect { migrate! }.to change {
      deploy_access_levels.where(
        protected_environment_id: pe.id,
        access_level: nil).count
    }.from(2).to(3)

    expect(invalid_access_level.reload.access_level).to be_nil
  end
end
