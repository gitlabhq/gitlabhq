# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillDeploymentApprovalData, :aggregate_failures,
  feature_category: :environment_management do
  let(:pear) { table(:protected_environment_approval_rules) }

  let!(:user) { table(:users).create!(email: 'user1@example.com', username: 'user1', projects_limit: 100) }
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path') }
  let(:other_namespace) { table(:namespaces).create!(name: 'othername', path: 'otherpath') }

  let(:project) do
    table(:projects).create!(
      name: 'My project name', description: 'My description',
      namespace_id: namespace.id, project_namespace_id: namespace.id
    )
  end

  let!(:protected_environment_1) do
    create_protected_environment('env1', required_approval_count: 6).tap do |p_env|
      create_deploy_access_level_for_role(p_env, Gitlab::Access::MAINTAINER)
    end
  end

  let!(:protected_environment_2) do
    create_protected_environment('env2', required_approval_count: 7).tap do |p_env|
      create_deploy_access_level_for_user(p_env, user.id)
    end
  end

  let!(:protected_environment_3) do
    create_protected_environment('env3', required_approval_count: 8).tap do |p_env|
      # group_inheritance_type is based on ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE
      create_deploy_access_level_for_group(p_env, namespace.id, 0)
      create_deploy_access_level_for_group(p_env, other_namespace.id, 1)
    end
  end

  let!(:protected_environment_4) do
    create_protected_environment('env4', required_approval_count: 17).tap do |p_env|
      create_deploy_access_level_for_user(p_env, user.id)

      pear.create!(
        protected_environment_id: p_env.id,
        access_level: Gitlab::Access::DEVELOPER,
        required_approvals: 10
      )
    end
  end

  let!(:protected_environment_5) do
    create_protected_environment('env5', required_approval_count: 0)
  end

  let!(:protected_environment_6) do
    create_protected_environment('env6', required_approval_count: 12)
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)
  end

  it 'creates new approval rules for relevant protected_enviroments per deploy_access_level' do
    # Here we are migrating the following:
    #   - protected_environment_1 - 1 rule for maintainer
    #   - protected_environment_2 - 1 rule for user
    #   - protected_environment_3 - 2 rules for 2 groups, with different group_inheritance_types
    #   - protected_environment_4 - 0 rules since this environment already has approval rules
    #   - protected_environment_5 - 0 rules since the required_approval_count=0
    #   - protected_environment_6 - 0 rules since this does not have a deploy_access_level
    expect { migrate! }.to change { pear.count }.by(4)

    # protected_environment with deploy_access_level for role
    env1_pears = pear.where(protected_environment_id: protected_environment_1.id)
    expect(env1_pears.count).to eq(1)
    expect(env1_pears.first.attributes).to include(
      'required_approvals' => 6,
      'access_level' => Gitlab::Access::MAINTAINER,
      'user_id' => nil,
      'group_id' => nil,
      'group_inheritance_type' => 0
    )

    # protected_environment with deploy_access_level for user
    env2_pears = pear.where(protected_environment_id: protected_environment_2.id)
    expect(env2_pears.count).to eq(1)
    expect(env2_pears.first.attributes).to include(
      'required_approvals' => 7,
      'access_level' => nil,
      'user_id' => user.id,
      'group_id' => nil,
      'group_inheritance_type' => 0
    )

    # protected_environment with deploy_access_level for groups
    env3_pears = pear.where(protected_environment_id: protected_environment_3.id).order(:id)
    expect(env3_pears.count).to eq(2)
    expect(env3_pears.first.attributes).to include(
      'required_approvals' => 8,
      'access_level' => nil,
      'user_id' => nil,
      'group_id' => namespace.id,
      'group_inheritance_type' => 0
    )
    expect(env3_pears.second.attributes).to include(
      'required_approvals' => 8,
      'access_level' => nil,
      'user_id' => nil,
      'group_id' => other_namespace.id,
      'group_inheritance_type' => 1
    )

    # protected_environment with an existing approval rule
    # the existing approval_rule should not be changed or added to by the migration
    env4_pears = pear.where(protected_environment_id: protected_environment_4.id)
    expect(env4_pears.count).to eq(1)
    expect(env4_pears.first.attributes).to include(
      'required_approvals' => 10,
      'access_level' => Gitlab::Access::DEVELOPER,
      'user_id' => nil,
      'group_id' => nil,
      'group_inheritance_type' => 0
    )

    # protected_environment with required_approval_count = 0
    env5_pears = pear.where(protected_environment_id: protected_environment_5.id)
    expect(env5_pears.count).to eq(0)

    # protected_environment with required_approval_count > 0, but without any deploy_access_levels
    env6_pears = pear.where(protected_environment_id: protected_environment_6.id)
    expect(env6_pears.count).to eq(0)
  end

  def create_protected_environment(name, required_approval_count:)
    table(:protected_environments).create!(
      project_id: project.id,
      name: name,
      required_approval_count: required_approval_count
    )
  end

  def create_deploy_access_level_for_role(protected_environment, access_level)
    table(:protected_environment_deploy_access_levels).create!(
      protected_environment_id: protected_environment.id,
      access_level: access_level
    )
  end

  def create_deploy_access_level_for_user(protected_environment, user_id)
    table(:protected_environment_deploy_access_levels).create!(
      protected_environment_id: protected_environment.id,
      user_id: user_id
    )
  end

  def create_deploy_access_level_for_group(protected_environment, group_id, group_inheritance_type)
    table(:protected_environment_deploy_access_levels).create!(
      protected_environment_id: protected_environment.id,
      group_id: group_id,
      group_inheritance_type: group_inheritance_type
    )
  end
end
