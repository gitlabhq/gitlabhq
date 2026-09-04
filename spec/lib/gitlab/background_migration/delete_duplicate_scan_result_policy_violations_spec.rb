# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteDuplicateScanResultPolicyViolations,
  feature_category: :security_policy_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:policy_configurations) { table(:security_orchestration_policy_configurations) }
  let(:security_policies) { table(:security_policies) }
  let(:approval_policy_rules) { table(:approval_policy_rules) }
  let(:scan_result_policies) { table(:scan_result_policies) }
  let(:violations) { table(:scan_result_policy_violations) }
  let(:violation_details) { table(:scan_result_policy_violation_details) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:group) { namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id) }

  let(:project) do
    projects.create!(name: 'project', path: 'project', organization_id: organization.id,
      project_namespace_id: group.id, namespace_id: group.id)
  end

  let(:policy_configuration) do
    policy_configurations.create!(namespace_id: group.id, security_policy_management_project_id: project.id)
  end

  let(:security_policy) do
    security_policies.create!(
      security_orchestration_policy_configuration_id: policy_configuration.id,
      security_policy_management_project_id: project.id,
      policy_index: 0,
      type: 0, # approval_policy
      name: 'Policy',
      checksum: SecureRandom.hex(32)
    )
  end

  let(:rule) { create_approval_policy_rule(rule_index: 0) }
  let(:other_rule) { create_approval_policy_rule(rule_index: 1) }

  let(:merge_request) { create_merge_request }
  let(:other_merge_request) { create_merge_request }

  let(:migration_args) do
    {
      start_cursor: [0],
      end_cursor: [violations.maximum(:id)],
      batch_table: :scan_result_policy_violations,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  describe '#perform' do
    it 'deletes all but the newest duplicate per approval policy rule and merge request' do
      create_violation(rule: rule, merge_request: merge_request)
      create_violation(rule: rule, merge_request: merge_request)
      newest = create_violation(rule: rule, merge_request: merge_request)

      perform_migration

      expect(violations.pluck(:id)).to contain_exactly(newest.id)
    end

    it 'deletes duplicates in earlier sub-batches when the newest row is in a later sub-batch' do
      create_violation(rule: rule, merge_request: merge_request)
      newest = create_violation(rule: rule, merge_request: merge_request)

      perform_migration(sub_batch_size: 1)

      expect(violations.pluck(:id)).to contain_exactly(newest.id)
    end

    it 'cascades deletion to the duplicate rows violation details' do
      older = create_violation(rule: rule, merge_request: merge_request)
      newest = create_violation(rule: rule, merge_request: merge_request)
      create_violation_detail(violation: older)
      newest_detail = create_violation_detail(violation: newest)

      perform_migration

      expect(violation_details.pluck(:id)).to contain_exactly(newest_detail.id)
    end

    it 'keeps single violations per approval policy rule and merge request' do
      violation = create_violation(rule: rule, merge_request: merge_request)
      other_violation = create_violation(rule: other_rule, merge_request: merge_request)
      violation_on_other_mr = create_violation(rule: rule, merge_request: other_merge_request)

      perform_migration

      expect(violations.pluck(:id)).to contain_exactly(
        violation.id, other_violation.id, violation_on_other_mr.id
      )
    end

    it 'keeps rows without an approval policy rule even when they share a merge request' do
      legacy_violation = create_legacy_violation(merge_request: merge_request)
      other_legacy_violation = create_legacy_violation(merge_request: merge_request)

      perform_migration

      expect(violations.pluck(:id)).to contain_exactly(legacy_violation.id, other_legacy_violation.id)
    end
  end

  def perform_migration(sub_batch_size: 100)
    described_class.new(**migration_args.merge(sub_batch_size: sub_batch_size)).perform
  end

  def create_approval_policy_rule(rule_index:)
    approval_policy_rules.create!(
      security_policy_id: security_policy.id,
      security_policy_management_project_id: project.id,
      rule_index: rule_index,
      type: 0 # scan_finding
    )
  end

  def create_merge_request
    merge_requests.create!(
      target_project_id: project.id,
      target_branch: 'main',
      source_branch: "feature-#{SecureRandom.hex(4)}"
    )
  end

  def create_violation(rule:, merge_request:)
    violations.create!(
      approval_policy_rule_id: rule.id,
      merge_request_id: merge_request.id,
      project_id: project.id
    )
  end

  # Rows from before the approval_policy_rule_id backfill only reference
  # scan_result_policies (Security::ScanResultPolicyRead).
  def create_legacy_violation(merge_request:)
    scan_result_policy = scan_result_policies.create!(
      security_orchestration_policy_configuration_id: policy_configuration.id,
      project_id: project.id,
      orchestration_policy_idx: 0
    )

    violations.create!(
      scan_result_policy_id: scan_result_policy.id,
      merge_request_id: merge_request.id,
      project_id: project.id
    )
  end

  def create_violation_detail(violation:)
    violation_details.create!(
      scan_result_policy_violation_id: violation.id,
      project_id: project.id,
      policy_rule_type: 0
    )
  end
end
