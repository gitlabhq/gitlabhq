# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupSecurityOrchestrationPolicyRuleSchedulesWithNullUserId, feature_category: :security_policy_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:security_orchestration_policy_configurations) { table(:security_orchestration_policy_configurations) }
  let(:security_orchestration_policy_rule_schedules) { table(:security_orchestration_policy_rule_schedules) }

  let!(:organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
  let!(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let!(:policy_namespace) do
    namespaces.create!(name: 'policy-namespace', path: 'policy-namespace', organization_id: organization.id)
  end

  let!(:policy_project) do
    projects.create!(
      namespace_id: policy_namespace.id,
      project_namespace_id: policy_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:user) do
    users.create!(name: 'test', email: 'test@example.com', projects_limit: 5, organization_id: organization.id)
  end

  let!(:policy_configuration) do
    security_orchestration_policy_configurations.create!(
      project_id: project.id,
      security_policy_management_project_id: policy_project.id
    )
  end

  let!(:schedule_with_user) do
    security_orchestration_policy_rule_schedules.create!(
      security_orchestration_policy_configuration_id: policy_configuration.id,
      user_id: user.id,
      policy_index: 0,
      cron: '0 0 * * *',
      project_id: project.id
    )
  end

  let!(:schedule_without_user_1) do
    security_orchestration_policy_rule_schedules.create!(
      security_orchestration_policy_configuration_id: policy_configuration.id,
      user_id: nil,
      policy_index: 1,
      cron: '0 1 * * *',
      project_id: project.id
    )
  end

  let!(:schedule_without_user_2) do
    security_orchestration_policy_rule_schedules.create!(
      security_orchestration_policy_configuration_id: policy_configuration.id,
      user_id: nil,
      policy_index: 2,
      cron: '0 2 * * *',
      project_id: project.id
    )
  end

  describe '#down' do
    it 'removes records with NULL user_id' do
      migrate!
      schema_migrate_down!

      expect(security_orchestration_policy_rule_schedules.where(user_id: nil)).to be_empty
      expect(security_orchestration_policy_rule_schedules.where(user_id: user.id)).not_to be_empty
      expect(security_orchestration_policy_rule_schedules.count).to eq(1)
    end
  end
end
