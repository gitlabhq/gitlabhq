# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphansApprovalMergeRequestRules2, feature_category: :security_policy_management do
  describe '#perform' do
    let(:batch_table) { :approval_merge_request_rules }
    let(:batch_column) { :id }
    let(:sub_batch_size) { 1 }
    let(:pause_ms) { 0 }
    let(:connection) { ApplicationRecord.connection }

    let(:organizations) { table(:organizations) }
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:approval_project_rules) { table(:approval_project_rules) }
    let(:approval_merge_request_rules) { table(:approval_merge_request_rules) }
    let(:approval_merge_request_rule_sources) { table(:approval_merge_request_rule_sources) }
    let(:security_orchestration_policy_configurations) { table(:security_orchestration_policy_configurations) }

    let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
    let(:namespace) { namespaces.create!(name: 'name', path: 'path', organization_id: organization.id) }
    let(:project) do
      projects.create!(name: "project", path: "project", namespace_id: namespace.id,
        project_namespace_id: namespace.id, organization_id: organization.id)
    end

    let(:namespace_2) { namespaces.create!(name: 'name_2', path: 'path_2', organization_id: organization.id) }
    let(:security_project) do
      projects
        .create!(name: "security_project", path: "security_project", namespace_id: namespace_2.id,
          project_namespace_id: namespace_2.id, organization_id: organization.id)
    end

    let!(:security_orchestration_policy_configuration) do
      security_orchestration_policy_configurations
        .create!(project_id: project.id, security_policy_management_project_id: security_project.id)
    end

    let(:merge_request) do
      table(:merge_requests).create!(target_project_id: project.id, target_branch: 'main', source_branch: 'feature')
    end

    let!(:approval_rule) do
      approval_merge_request_rules.create!(
        name: 'rule',
        merge_request_id: merge_request.id,
        report_type: 4,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration.id)
    end

    let!(:approval_rule_other_report_type) do
      approval_merge_request_rules.create!(
        name: 'rule 2',
        merge_request_id: merge_request.id,
        report_type: 1,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration.id)
    end

    let!(:approval_rule_license_scanning) do
      approval_merge_request_rules.create!(
        name: 'rule 4',
        merge_request_id: merge_request.id,
        report_type: 2,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration.id)
    end

    let!(:approval_rule_license_scanning_without_policy_id) do
      approval_merge_request_rules.create!(name: 'rule 5', merge_request_id: merge_request.id, report_type: 2)
    end

    let!(:approval_rule_last) do
      approval_merge_request_rules.create!(name: 'rule 3', merge_request_id: merge_request.id, report_type: 4)
    end

    subject do
      described_class.new(
        start_id: approval_rule.id,
        end_id: approval_rule_last.id,
        batch_table: batch_table,
        batch_column: batch_column,
        sub_batch_size: sub_batch_size,
        pause_ms: pause_ms,
        connection: connection
      ).perform
    end

    it 'delete only approval rules without association with the security project and report_type equals to 4 or 2' do
      expect { subject }.to change { approval_merge_request_rules.all }.to(
        contain_exactly(approval_rule,
          approval_rule_other_report_type,
          approval_rule_license_scanning))
    end

    context 'with rule sources' do # rubocop: disable RSpec/MultipleMemoizedHelpers
      let(:project_approval_rule_1) { approval_project_rules.create!(project_id: project.id, name: '1') }
      let(:project_approval_rule_2) { approval_project_rules.create!(project_id: project.id, name: '2') }

      let!(:rule_source_1) do
        approval_merge_request_rule_sources.create!(
          approval_merge_request_rule_id: approval_rule_license_scanning_without_policy_id.id,
          approval_project_rule_id: project_approval_rule_1.id)
      end

      let!(:rule_source_2) do
        approval_merge_request_rule_sources.create!(
          approval_merge_request_rule_id: approval_rule_other_report_type.id,
          approval_project_rule_id: project_approval_rule_2.id)
      end

      it 'deletes referenced sources' do
        # rubocop: disable CodeReuse/ActiveRecord
        expect { subject }.to change { approval_merge_request_rule_sources.exists?(rule_source_1.id) }.to(false)
        # rubocop: enable CodeReuse/ActiveRecord
      end

      it 'does not delete unreferenced sources' do
        # rubocop: disable CodeReuse/ActiveRecord
        expect { subject }.not_to change { approval_merge_request_rule_sources.exists?(rule_source_2.id) }
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
