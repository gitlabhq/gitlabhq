# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RerunRemoveInvalidDeployAccessLevel, :migration, feature_category: :continuous_integration do
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

  let!(:access_level) do
    deploy_access_levels.create!(
      access_level: 40,
      user_id: nil,
      group_id: nil,
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

  let!(:user_and_group_access_level) do
    deploy_access_levels.create!(
      user_id: user.id,
      group_id: group.id,
      protected_environment_id: pe.id)
  end

  it 'fixes invalid access_level entries and does not affect others' do
    expect { migrate! }.to change {
      deploy_access_levels.where(protected_environment_id: pe.id)
                          .where("num_nonnulls(user_id, group_id, access_level) = 1").count
    }.from(3).to(5)

    invalid_access_level.reload
    access_level.reload
    group_access_level.reload
    user_access_level.reload
    user_and_group_access_level.reload

    expect(invalid_access_level.access_level).to be_nil
    expect(invalid_access_level.user_id).to eq(user.id)
    expect(invalid_access_level.group_id).to be_nil

    expect(access_level.access_level).to eq(40)
    expect(access_level.user_id).to be_nil
    expect(access_level.group_id).to be_nil

    expect(group_access_level.access_level).to be_nil
    expect(group_access_level.user_id).to be_nil
    expect(group_access_level.group_id).to eq(group.id)

    expect(user_access_level.access_level).to be_nil
    expect(user_access_level.user_id).to eq(user.id)
    expect(user_access_level.group_id).to be_nil

    expect(user_and_group_access_level.access_level).to be_nil
    expect(user_and_group_access_level.user_id).to eq(user.id)
    expect(user_and_group_access_level.group_id).to be_nil
  end
end
