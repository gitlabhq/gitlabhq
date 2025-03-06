# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIncidentManagementPendingIssueEscalationsNamespaceId, feature_category: :incident_management do
  let(:connection) { ApplicationRecord.connection }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let(:start_cursor) { [0, 2.months.ago.to_s] }
  let(:end_cursor) { [issues.maximum(:id), Time.current.to_s] }

  let(:migration) do
    described_class.new(
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      batch_table: :incident_management_pending_issue_escalations,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    )
  end

  shared_context 'for database tables' do
    let(:namespaces) { table(:namespaces) }
    let(:organizations) { table(:organizations) }
    let(:issues) { table(:issues) { |t| t.primary_key = :id } }
    let(:incident_management_pending_issue_escalations) do
      table(:incident_management_pending_issue_escalations) { |t| t.primary_key = :id }
    end

    let(:projects) { table(:projects) }
    let(:incident_management_escalation_policies) { table(:incident_management_escalation_policies) }
    let(:incident_management_escalation_rules) { table(:incident_management_escalation_rules) }
    let(:incident_management_oncall_schedules) { table(:incident_management_oncall_schedules) }
  end

  shared_context 'for namespaces' do
    let(:namespace1) { namespaces.create!(name: 'namespace 1', path: 'namespace1', organization_id: organization.id) }
    let(:namespace2) { namespaces.create!(name: 'namespace 2', path: 'namespace2', organization_id: organization.id) }
    let(:namespace3) { namespaces.create!(name: 'namespace 3', path: 'namespace3', organization_id: organization.id) }
    let(:namespace4) { namespaces.create!(name: 'namespace 4', path: 'namespace4', organization_id: organization.id) }
    let(:namespace5) { namespaces.create!(name: 'namespace 5', path: 'namespace5', organization_id: organization.id) }
  end

  shared_context 'for projects' do
    let(:project1) do
      projects.create!(
        namespace_id: namespace1.id,
        project_namespace_id: namespace1.id,
        organization_id: organization.id
      )
    end

    let(:project2) do
      projects.create!(
        namespace_id: namespace2.id,
        project_namespace_id: namespace2.id,
        organization_id: organization.id
      )
    end

    let(:project3) do
      projects.create!(
        namespace_id: namespace3.id,
        project_namespace_id: namespace3.id,
        organization_id: organization.id
      )
    end

    let(:project4) do
      projects.create!(
        namespace_id: namespace4.id,
        project_namespace_id: namespace4.id,
        organization_id: organization.id
      )
    end

    let(:policy) { incident_management_escalation_policies.create!(project_id: project1.id, name: 'Test Policy') }
    let(:oncall_schedule) do
      incident_management_oncall_schedules.create!(project_id: project1.id, iid: 1, name: 'Test Oncall')
    end

    let(:rule) do
      incident_management_escalation_rules.create!(policy_id: policy.id, status: 1, elapsed_time_seconds: 800,
        oncall_schedule_id: oncall_schedule.id)
    end
  end

  shared_context 'for issues and escalations' do
    let!(:work_item_type_id) { table(:work_item_types).where(base_type: 1).first.id }

    let!(:issue1) do
      issues.create!(
        namespace_id: namespace1.id,
        project_id: project1.id,
        created_at: 5.days.ago,
        closed_at: 3.days.ago,
        work_item_type_id: work_item_type_id
      )
    end

    let!(:issue2) do
      issues.create!(
        namespace_id: namespace2.id,
        project_id: project2.id,
        created_at: 4.days.ago,
        closed_at: 3.days.ago,
        work_item_type_id: work_item_type_id
      )
    end

    let!(:issue3) do
      issues.create!(
        namespace_id: namespace3.id,
        project_id: project3.id,
        created_at: 3.days.ago,
        closed_at: 2.days.ago,
        work_item_type_id: work_item_type_id
      )
    end

    let!(:issue4) do
      issues.create!(
        namespace_id: namespace4.id,
        project_id: project4.id,
        created_at: 2.days.ago,
        closed_at: 2.days.ago,
        work_item_type_id: work_item_type_id
      )
    end

    let!(:incident_management_pending_issue_escalations_1) do
      incident_management_pending_issue_escalations.create!(
        issue_id: issue1.id, process_at: 3.minutes.from_now, rule_id: rule.id, namespace_id: nil)
    end

    let!(:incident_management_pending_issue_escalations_2) do
      incident_management_pending_issue_escalations.create!(
        issue_id: issue2.id, process_at: 5.minutes.from_now, rule_id: rule.id, namespace_id: nil)
    end

    let!(:incident_management_pending_issue_escalations_3) do
      incident_management_pending_issue_escalations.create!(
        issue_id: issue3.id, process_at: 7.minutes.from_now, rule_id: rule.id, namespace_id: nil)
    end

    let!(:incident_management_pending_issue_escalations_4) do
      incident_management_pending_issue_escalations.create!(
        issue_id: issue4.id, process_at: 10.minutes.from_now, rule_id: rule.id, namespace_id: namespace5.id)
    end
  end

  include_context 'for database tables'
  include_context 'for namespaces'
  include_context 'for projects'
  include_context 'for issues and escalations'

  describe '#perform' do
    it 'backfills incident_management_pending_issue_escalations.namespace_id correctly for relevant records' do
      migration.perform

      expect(incident_management_pending_issue_escalations_1.reload.namespace_id).to eq(issue1.namespace_id)
      expect(incident_management_pending_issue_escalations_2.reload.namespace_id).to eq(issue2.namespace_id)
      expect(incident_management_pending_issue_escalations_3.reload.namespace_id).to eq(issue3.namespace_id)
    end

    it 'does not update incident_management_pending_issue_escalations with pre-existing namespace_id' do
      expect { migration.perform }
        .not_to change { incident_management_pending_issue_escalations_4.reload.namespace_id }
    end
  end
end
