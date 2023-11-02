# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphansApprovalMergeRequestRules do
  describe '#perform' do
    let(:batch_table) { :approval_merge_request_rules }
    let(:batch_column) { :id }
    let(:sub_batch_size) { 1 }
    let(:pause_ms) { 0 }
    let(:connection) { ApplicationRecord.connection }

    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:approval_merge_request_rules) { table(:approval_merge_request_rules) }
    let(:security_orchestration_policy_configurations) { table(:security_orchestration_policy_configurations) }
    let(:namespace) { namespaces.create!(name: 'name', path: 'path') }
    let(:project) do
      projects
        .create!(name: "project", path: "project", namespace_id: namespace.id, project_namespace_id: namespace.id)
    end

    let(:namespace_2) { namespaces.create!(name: 'name_2', path: 'path_2') }
    let(:security_project) do
      projects.create!(
        name: "security_project",
        path: "security_project",
        namespace_id: namespace_2.id,
        project_namespace_id: namespace_2.id
      )
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

    it 'delete only approval rules without association with the security project and report_type equals to 4' do
      expect { subject }.to change { approval_merge_request_rules.count }.from(3).to(2)
    end
  end
end
