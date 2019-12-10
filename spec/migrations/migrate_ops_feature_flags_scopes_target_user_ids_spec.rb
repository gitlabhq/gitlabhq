# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191118211629_migrate_ops_feature_flags_scopes_target_user_ids.rb')

describe MigrateOpsFeatureFlagsScopesTargetUserIds, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects)   { table(:projects) }
  let(:flags)      { table(:operations_feature_flags) }
  let(:scopes)     { table(:operations_feature_flag_scopes) }

  def setup
    namespace = namespaces.create!(name: 'foo', path: 'foo')
    project = projects.create!(namespace_id: namespace.id)
    flag = flags.create!(project_id: project.id, active: true, name: 'test_flag')

    flag
  end

  it 'migrates successfully when there are no scopes in the database' do
    setup

    disable_migrations_output { migrate! }

    expect(scopes.count).to eq(0)
  end

  it 'migrates a disabled scope with gradualRolloutUserId and userWithId strategies' do
    flag = setup
    scope = scopes.create!(feature_flag_id: flag.id, active: false, strategies: [
      { name: 'gradualRolloutUserId', parameters: { groupId: 'default', percentage: '50' } },
      { name: 'userWithId', parameters: { userIds: '5' } }
    ])

    disable_migrations_output { migrate! }

    scope.reload
    expect(scope.active).to eq(true)
    expect(scope.strategies).to eq([{ 'name' => 'userWithId', 'parameters' => { 'userIds' => '5' } }])
  end

  it 'migrates a disabled scope with default and userWithId strategies' do
    flag = setup
    scope = scopes.create!(feature_flag_id: flag.id, active: false, strategies: [
      { name: 'default', parameters: {} },
      { name: 'userWithId', parameters: { userIds: 'amy@gmail.com,karen@gmail.com' } }
    ])

    disable_migrations_output { migrate! }

    scope.reload
    expect(scope.active).to eq(true)
    expect(scope.strategies).to eq([{ 'name' => 'userWithId', 'parameters' => { 'userIds' => 'amy@gmail.com,karen@gmail.com' } }])
  end

  it 'migrates an enabled scope with default and userWithId strategies' do
    flag = setup
    scope = scopes.create!(feature_flag_id: flag.id, active: true, strategies: [
      { name: 'default', parameters: {} },
      { name: 'userWithId', parameters: { userIds: 'tim' } }
    ])

    disable_migrations_output { migrate! }

    scope.reload
    expect(scope.active).to eq(true)
    expect(scope.strategies).to eq([{ 'name' => 'default', 'parameters' => {} }])
  end

  it 'does not alter an enabled scope with gradualRolloutUserId and userWithId strategies' do
    flag = setup
    scope = scopes.create!(feature_flag_id: flag.id, active: true, strategies: [
      { name: 'gradualRolloutUserId', parameters: { groupId: 'default', percentage: '50' } },
      { name: 'userWithId', parameters: { userIds: '5' } }
    ])

    disable_migrations_output { migrate! }

    scope.reload
    expect(scope.active).to eq(true)
    expect(scope.strategies).to eq([
      { 'name' => 'gradualRolloutUserId', 'parameters' => { 'groupId' => 'default', 'percentage' => '50' } },
      { 'name' => 'userWithId', 'parameters' => { 'userIds' => '5' } }
    ])
  end

  it 'does not alter a disabled scope without a userWithId strategy' do
    flag = setup
    scope = scopes.create!(feature_flag_id: flag.id, active: false, strategies: [
      { name: 'gradualRolloutUserId', parameters: { percentage: '60' } }
    ])

    disable_migrations_output { migrate! }

    scope.reload
    expect(scope.active).to eq(false)
    expect(scope.strategies).to eq([
      { 'name' => 'gradualRolloutUserId', 'parameters' => { 'percentage' => '60' } }
    ])
  end

  it 'does not alter an enabled scope without a userWithId strategy' do
    flag = setup
    scope = scopes.create!(feature_flag_id: flag.id, active: true, strategies: [
      { name: 'default', parameters: {} }
    ])

    disable_migrations_output { migrate! }

    scope.reload
    expect(scope.active).to eq(true)
    expect(scope.strategies).to eq([
      { 'name' => 'default', 'parameters' => {} }
    ])
  end

  it 'migrates multiple scopes' do
    flag = setup
    scope_a = scopes.create!(feature_flag_id: flag.id, active: false, strategies: [
      { name: 'gradualRolloutUserId', parameters: { groupId: 'default', percentage: '50' } },
      { name: 'userWithId', parameters: { userIds: '5,6,7' } }
    ])
    scope_b = scopes.create!(feature_flag_id: flag.id, active: false, environment_scope: 'production', strategies: [
      { name: 'default', parameters: {} },
      { name: 'userWithId', parameters: { userIds: 'lisa,carol' } }
    ])

    disable_migrations_output { migrate! }

    scope_a.reload
    scope_b.reload
    expect(scope_a.active).to eq(true)
    expect(scope_a.strategies).to eq([{ 'name' => 'userWithId', 'parameters' => { 'userIds' => '5,6,7' } }])
    expect(scope_b.active).to eq(true)
    expect(scope_b.strategies).to eq([{ 'name' => 'userWithId', 'parameters' => { 'userIds' => 'lisa,carol' } }])
  end
end
