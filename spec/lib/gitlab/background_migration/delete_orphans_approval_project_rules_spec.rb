# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphansApprovalProjectRules do
  describe '#perform' do
    let(:batch_table) { :approval_project_rules }
    let(:batch_column) { :id }
    let(:sub_batch_size) { 1 }
    let(:pause_ms) { 0 }
    let(:connection) { ApplicationRecord.connection }

    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:approval_project_rules) { table(:approval_project_rules) }
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

    let!(:project_rule) do
      approval_project_rules.create!(
        name: 'rule',
        project_id: project.id,
        report_type: 4,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration.id)
    end

    let!(:project_rule_other_report_type) do
      approval_project_rules.create!(
        name: 'rule 2',
        project_id: project.id,
        report_type: 1,
        security_orchestration_policy_configuration_id: security_orchestration_policy_configuration.id)
    end

    let!(:project_rule_last) do
      approval_project_rules.create!(name: 'rule 3', project_id: project.id, report_type: 4)
    end

    subject do
      described_class.new(
        start_id: project_rule.id,
        end_id: project_rule_last.id,
        batch_table: batch_table,
        batch_column: batch_column,
        sub_batch_size: sub_batch_size,
        pause_ms: pause_ms,
        connection: connection
      ).perform
    end

    it 'delete only approval rules without association with the security project and report_type equals to 4' do
      expect { subject }.to change { approval_project_rules.count }.from(3).to(2)
    end
  end
end
