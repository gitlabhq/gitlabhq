# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UnsetEscalationPoliciesForAlertIncidents, feature_category: :incident_management do
  let(:namespaces)          { table(:namespaces) }
  let(:projects)            { table(:projects) }
  let(:issues)              { table(:issues) }
  let(:alerts)              { table(:alert_management_alerts) }
  let(:escalation_policies) { table(:incident_management_escalation_policies) }
  let(:escalation_statuses) { table(:incident_management_issuable_escalation_statuses) }
  let(:current_time)        { Time.current.change(usec: 0) }

  let!(:namespace)         { namespaces.create!(name: 'namespace', path: 'namespace') }
  let!(:project_namespace) { namespaces.create!(name: 'project', path: 'project', type: 'project') }
  let!(:project)           { projects.create!(namespace_id: namespace.id, project_namespace_id: project_namespace.id) }
  let!(:policy)            { escalation_policies.create!(project_id: project.id, name: 'escalation policy') }

  # Escalation status with policy from alert; Policy & escalation start time should be nullified
  let!(:issue_1)             { create_issue }
  let!(:escalation_status_1) { create_status(issue_1, policy, current_time) }
  let!(:alert_1)             { create_alert(1, issue_1) }

  # Escalation status without policy, but with alert; Should be ignored
  let!(:issue_2)             { create_issue }
  let!(:escalation_status_2) { create_status(issue_2, nil, current_time) }
  let!(:alert_2)             { create_alert(2, issue_2) }

  # Escalation status without alert, but with policy; Should be ignored
  let!(:issue_3)             { create_issue }
  let!(:escalation_status_3) { create_status(issue_3, policy, current_time) }

  # Alert without issue; Should be ignored
  let!(:alert_3) { create_alert(3) }

  it 'removes the escalation policy if the incident corresponds to an alert' do
    expect { migrate! }
      .to change { escalation_status_1.reload.policy_id }.from(policy.id).to(nil)
      .and change { escalation_status_1.escalations_started_at }.from(current_time).to(nil)
      .and not_change { policy_attrs(escalation_status_2) }
      .and not_change { policy_attrs(escalation_status_3) }
  end

  private

  def create_issue
    issues.create!(project_id: project.id, namespace_id: project.project_namespace_id)
  end

  def create_status(issue, policy = nil, escalations_started_at = nil)
    escalation_statuses.create!(
      issue_id: issue.id,
      policy_id: policy&.id,
      escalations_started_at: escalations_started_at
    )
  end

  def create_alert(iid, issue = nil)
    alerts.create!(
      project_id: project.id,
      started_at: current_time,
      title: "alert #{iid}",
      iid: iid.to_s,
      issue_id: issue&.id
    )
  end

  def policy_attrs(escalation_status)
    escalation_status.reload.slice(:policy_id, :escalations_started_at)
  end
end
