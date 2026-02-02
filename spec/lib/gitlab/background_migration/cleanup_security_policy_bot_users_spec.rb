# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- many memoized helpers needed to setup test data
RSpec.describe Gitlab::BackgroundMigration::CleanupSecurityPolicyBotUsers, feature_category: :security_policy_management do
  let(:users_table) { table(:users) }
  let(:members_table) { table(:members) }
  let(:projects_table) { table(:projects) }
  let(:namespaces_table) { table(:namespaces) }
  let(:plans_table) { table(:plans) }
  let(:gitlab_subscriptions_table) { table(:gitlab_subscriptions) }
  let(:organizations_table) { table(:organizations) }

  let!(:organization) { organizations_table.create!(name: 'Organization', path: 'organization') }
  let!(:premium_plan) { plans_table.create!(name: 'premium', title: 'Premium', plan_name_uid: 5) }
  let!(:silver_plan) { plans_table.create!(name: 'silver', title: 'Silver', plan_name_uid: 4) }
  let!(:premium_trial_plan) { plans_table.create!(name: 'premium_trial', title: 'Premium Trial', plan_name_uid: 6) }
  let!(:ultimate_plan) { plans_table.create!(name: 'ultimate', title: 'Ultimate', plan_name_uid: 7) }
  let!(:free_plan) { plans_table.create!(name: 'free', title: 'Free', plan_name_uid: 2) }

  let!(:ultimate_namespace) do
    namespaces_table.create!(
      name: 'ultimate-namespace',
      path: 'ultimate-namespace',
      type: 'Group',
      organization_id: organization.id
    ).tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  let!(:premium_namespace) do
    namespaces_table.create!(
      name: 'premium-namespace',
      path: 'premium-namespace',
      type: 'Group',
      organization_id: organization.id
    ).tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  let!(:silver_namespace) do
    namespaces_table.create!(
      name: 'silver-namespace',
      path: 'silver-namespace',
      type: 'Group',
      organization_id: organization.id
    ).tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  let!(:premium_trial_namespace) do
    namespaces_table.create!(
      name: 'premium-trial-namespace',
      path: 'premium-trial-namespace',
      type: 'Group',
      organization_id: organization.id
    ).tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  let!(:free_namespace) do
    namespaces_table.create!(
      name: 'free-namespace',
      path: 'free-namespace',
      type: 'Group',
      organization_id: organization.id
    ).tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  let!(:premium_subgroup) do
    namespaces_table.create!(
      name: 'premium-subgroup',
      path: 'premium-subgroup',
      type: 'Group',
      parent_id: premium_namespace.id,
      organization_id: organization.id
    ).tap { |ns| ns.update!(traversal_ids: [premium_namespace.id, ns.id]) }
  end

  let!(:ultimate_subscription) do
    gitlab_subscriptions_table.create!(
      namespace_id: ultimate_namespace.id,
      hosted_plan_id: ultimate_plan.id,
      seats: 10
    )
  end

  let!(:premium_subscription) do
    gitlab_subscriptions_table.create!(
      namespace_id: premium_namespace.id,
      hosted_plan_id: premium_plan.id,
      seats: 10
    )
  end

  let!(:silver_subscription) do
    gitlab_subscriptions_table.create!(
      namespace_id: silver_namespace.id,
      hosted_plan_id: silver_plan.id,
      seats: 10
    )
  end

  let!(:premium_trial_subscription) do
    gitlab_subscriptions_table.create!(
      namespace_id: premium_trial_namespace.id,
      hosted_plan_id: premium_trial_plan.id,
      seats: 10
    )
  end

  let!(:free_subscription) do
    gitlab_subscriptions_table.create!(
      namespace_id: free_namespace.id,
      hosted_plan_id: free_plan.id,
      seats: 10
    )
  end

  let!(:ultimate_project) do
    projects_table.create!(
      name: 'ultimate-project',
      path: 'ultimate-project',
      namespace_id: ultimate_namespace.id,
      project_namespace_id: ultimate_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:premium_project) do
    projects_table.create!(
      name: 'premium-project',
      path: 'premium-project',
      namespace_id: premium_namespace.id,
      project_namespace_id: premium_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:silver_project) do
    projects_table.create!(
      name: 'silver-project',
      path: 'silver-project',
      namespace_id: silver_namespace.id,
      project_namespace_id: silver_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:premium_trial_project) do
    projects_table.create!(
      name: 'premium-trial-project',
      path: 'premium-trial-project',
      namespace_id: premium_trial_namespace.id,
      project_namespace_id: premium_trial_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:free_project) do
    projects_table.create!(
      name: 'free-project',
      path: 'free-project',
      namespace_id: free_namespace.id,
      project_namespace_id: free_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:premium_subgroup_project) do
    projects_table.create!(
      name: 'premium-subgroup-project',
      path: 'premium-subgroup-project',
      namespace_id: premium_subgroup.id,
      project_namespace_id: premium_subgroup.id,
      organization_id: organization.id
    )
  end

  let!(:policy_bot_with_ultimate_project) do
    users_table.create!(
      username: 'policy-bot-ultimate',
      email: 'policy-bot-ultimate@example.com',
      user_type: HasUserType::USER_TYPES[:security_policy_bot],
      projects_limit: 0,
      organization_id: organization.id
    )
  end

  let!(:policy_bot_with_premium_project) do
    users_table.create!(
      username: 'policy-bot-premium',
      email: 'policy-bot-premium@example.com',
      user_type: HasUserType::USER_TYPES[:security_policy_bot],
      projects_limit: 0,
      organization_id: organization.id
    )
  end

  let!(:policy_bot_with_silver_project) do
    users_table.create!(
      username: 'policy-bot-silver',
      email: 'policy-bot-silver@example.com',
      user_type: HasUserType::USER_TYPES[:security_policy_bot],
      projects_limit: 0,
      organization_id: organization.id
    )
  end

  let!(:policy_bot_with_premium_trial_project) do
    users_table.create!(
      username: 'policy-bot-premium-trial',
      email: 'policy-bot-premium-trial@example.com',
      user_type: HasUserType::USER_TYPES[:security_policy_bot],
      projects_limit: 0,
      organization_id: organization.id
    )
  end

  let!(:policy_bot_with_free_project) do
    users_table.create!(
      username: 'policy-bot-free',
      email: 'policy-bot-free@example.com',
      user_type: HasUserType::USER_TYPES[:security_policy_bot],
      projects_limit: 0,
      organization_id: organization.id
    )
  end

  let!(:policy_bot_with_premium_subgroup_project) do
    users_table.create!(
      username: 'policy-bot-premium-subgroup',
      email: 'policy-bot-premium-subgroup@example.com',
      user_type: HasUserType::USER_TYPES[:security_policy_bot],
      projects_limit: 0,
      organization_id: organization.id
    )
  end

  let!(:regular_user) do
    users_table.create!(
      username: 'regular-user',
      email: 'regular@example.com',
      user_type: HasUserType::USER_TYPES[:human],
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  before do
    members_table.create!(
      user_id: policy_bot_with_ultimate_project.id,
      source_id: ultimate_project.id,
      source_type: 'Project',
      type: 'ProjectMember',
      access_level: Gitlab::Access::GUEST,
      notification_level: NotificationSetting.levels[:global],
      member_namespace_id: ultimate_project.namespace_id
    )

    members_table.create!(
      user_id: policy_bot_with_premium_project.id,
      source_id: premium_project.id,
      source_type: 'Project',
      type: 'ProjectMember',
      access_level: Gitlab::Access::GUEST,
      notification_level: NotificationSetting.levels[:global],
      member_namespace_id: premium_project.namespace_id
    )

    members_table.create!(
      user_id: policy_bot_with_silver_project.id,
      source_id: silver_project.id,
      source_type: 'Project',
      type: 'ProjectMember',
      access_level: Gitlab::Access::GUEST,
      notification_level: NotificationSetting.levels[:global],
      member_namespace_id: silver_project.namespace_id
    )

    members_table.create!(
      user_id: policy_bot_with_premium_trial_project.id,
      source_id: premium_trial_project.id,
      source_type: 'Project',
      type: 'ProjectMember',
      access_level: Gitlab::Access::GUEST,
      notification_level: NotificationSetting.levels[:global],
      member_namespace_id: premium_trial_project.namespace_id
    )

    members_table.create!(
      user_id: policy_bot_with_free_project.id,
      source_id: free_project.id,
      source_type: 'Project',
      type: 'ProjectMember',
      access_level: Gitlab::Access::GUEST,
      notification_level: NotificationSetting.levels[:global],
      member_namespace_id: free_project.namespace_id
    )

    members_table.create!(
      user_id: policy_bot_with_premium_subgroup_project.id,
      source_id: premium_subgroup_project.id,
      source_type: 'Project',
      type: 'ProjectMember',
      access_level: Gitlab::Access::GUEST,
      notification_level: NotificationSetting.levels[:global],
      member_namespace_id: premium_subgroup_project.namespace_id
    )
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: users_table.minimum(:id),
      end_id: users_table.maximum(:id),
      batch_table: :users,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'deletes security policy bots in premium projects' do
    expect { perform_migration }
      .to change { users_table.where(id: policy_bot_with_premium_project.id).count }.from(1).to(0)
  end

  it 'deletes security policy bots in silver projects (legacy premium)' do
    expect { perform_migration }
      .to change { users_table.where(id: policy_bot_with_silver_project.id).count }.from(1).to(0)
  end

  it 'deletes security policy bots in premium trial projects' do
    expect { perform_migration }
      .to change { users_table.where(id: policy_bot_with_premium_trial_project.id).count }.from(1).to(0)
  end

  it 'deletes security policy bots in projects under premium subgroups' do
    expect { perform_migration }
      .to change { users_table.where(id: policy_bot_with_premium_subgroup_project.id).count }.from(1).to(0)
  end

  it 'keeps security policy bots in ultimate projects' do
    expect { perform_migration }
      .not_to change { users_table.where(id: policy_bot_with_ultimate_project.id).count }
  end

  it 'keeps security policy bots in free projects' do
    expect { perform_migration }
      .not_to change { users_table.where(id: policy_bot_with_free_project.id).count }
  end

  it 'does not delete regular users' do
    expect { perform_migration }
      .not_to change { users_table.where(id: regular_user.id).count }
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
