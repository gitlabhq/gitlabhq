# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteOrphanedRunningScanResultPolicyViolations, feature_category: :security_policy_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:violations) { table(:scan_result_policy_violations) }
  let(:policy_configurations) { table(:security_orchestration_policy_configurations) }
  let(:scan_result_policies) { table(:scan_result_policies) }
  let(:security_policies) { table(:security_policies) }
  let(:approval_policy_rules) { table(:approval_policy_rules) }

  let(:organization) { organizations.create!(name: 'Default', path: 'default') }

  let(:namespace) do
    namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let(:project_namespace) do
    namespaces.create!(name: 'project', path: 'project', type: 'Project', organization_id: organization.id)
  end

  let(:policy_project_namespace) do
    namespaces.create!(name: 'policies', path: 'policies', type: 'Project', organization_id: organization.id)
  end

  let(:project) do
    projects.create!(name: 'project', path: 'project', namespace_id: namespace.id,
      project_namespace_id: project_namespace.id, organization_id: organization.id)
  end

  let(:policy_project) do
    projects.create!(name: 'policies', path: 'policies', namespace_id: namespace.id,
      project_namespace_id: policy_project_namespace.id, organization_id: organization.id)
  end

  let(:merge_request) do
    merge_requests.create!(source_branch: 'feature', target_branch: 'main', target_project_id: project.id)
  end

  let(:configuration) do
    policy_configurations.create!(security_policy_management_project_id: policy_project.id,
      project_id: project.id)
  end

  let(:security_policy) do
    security_policies.create!(security_orchestration_policy_configuration_id: configuration.id,
      security_policy_management_project_id: policy_project.id, policy_index: 0, type: 0,
      name: 'policy', checksum: '0' * 64)
  end

  let(:approval_policy_rule) do
    approval_policy_rules.create!(security_policy_id: security_policy.id,
      security_policy_management_project_id: policy_project.id, rule_index: 0, type: 0)
  end

  let!(:orphaned) { create_violation(scan_result_policy_id: create_scan_result_policy(0)) }

  let!(:recently_updated) do
    create_violation(scan_result_policy_id: create_scan_result_policy(1), updated_at: 2.hours.ago)
  end

  let!(:with_approval_policy_rule) do
    create_violation(scan_result_policy_id: create_scan_result_policy(2),
      approval_policy_rule_id: approval_policy_rule.id)
  end

  let!(:with_violation_data) do
    create_violation(scan_result_policy_id: create_scan_result_policy(3),
      violation_data: { violations: { scan_finding: {} } })
  end

  let!(:already_resolved) { create_violation(scan_result_policy_id: create_scan_result_policy(4), status: 1) }

  it 'deletes only the orphaned running violations', :aggregate_failures do
    expect { migrate! }.to change { violations.count }.by(-1)

    expect(violations.exists?(orphaned.id)).to be(false)
    expect(violations.exists?(recently_updated.id)).to be(true)
    expect(violations.exists?(with_approval_policy_rule.id)).to be(true)
    expect(violations.exists?(with_violation_data.id)).to be(true)
    expect(violations.exists?(already_resolved.id)).to be(true)
  end

  def create_scan_result_policy(idx)
    scan_result_policies.create!(security_orchestration_policy_configuration_id: configuration.id,
      orchestration_policy_idx: idx, project_id: project.id).id
  end

  def create_violation(scan_result_policy_id:, **attrs)
    violations.create!(
      { merge_request_id: merge_request.id, project_id: project.id,
        scan_result_policy_id: scan_result_policy_id, approval_policy_rule_id: nil,
        status: 0, violation_data: nil, created_at: 3.days.ago, updated_at: 3.days.ago }.merge(attrs)
    )
  end
end
