# frozen_string_literal: true

require 'spec_helper'
require_migration!('adjust_unique_index_alert_management_alerts')

RSpec.describe AdjustUniqueIndexAlertManagementAlerts, :migration do
  let(:migration) { described_class.new }
  let(:alerts) { AlertManagement::Alert }
  let(:project) { create_project }
  let(:other_project) { create_project }
  let(:resolved_state) { 2 }
  let(:triggered_state) { 1 }
  let!(:existing_alert) { create_alert(project, resolved_state, '1234', 1) }
  let!(:p2_alert) { create_alert(other_project, resolved_state, '1234', 1) }
  let!(:p2_alert_diff_fingerprint) { create_alert(other_project, resolved_state, '4567', 2) }

  it 'can reverse the migration' do
    expect(existing_alert.fingerprint).not_to eq(nil)
    expect(p2_alert.fingerprint).not_to eq(nil)
    expect(p2_alert_diff_fingerprint.fingerprint).not_to eq(nil)

    migrate!

    # Adding a second alert with the same fingerprint now that we can
    second_alert = create_alert(project, triggered_state, '1234', 2)
    expect(alerts.count).to eq(4)

    schema_migrate_down!

    # We keep the alerts, but the oldest ones fingerprint is removed
    expect(alerts.count).to eq(4)
    expect(second_alert.reload.fingerprint).not_to eq(nil)
    expect(p2_alert.fingerprint).not_to eq(nil)
    expect(p2_alert_diff_fingerprint.fingerprint).not_to eq(nil)
    expect(existing_alert.reload.fingerprint).to eq(nil)
  end

  def namespace
    @namespace ||= table(:namespaces).create!(name: 'foo', path: 'foo')
  end

  def create_project
    table(:projects).create!(namespace_id: namespace.id)
  end

  def create_alert(project, status, fingerprint, iid)
    params = {
      title: 'test',
      started_at: Time.current,
      iid: iid,
      project_id: project.id,
      status: status,
      fingerprint: fingerprint
    }
    table(:alert_management_alerts).create!(params)
  end
end
