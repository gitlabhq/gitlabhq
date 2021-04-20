# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe PopulateDismissalInformationForVulnerabilities do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:vulnerabilities) { table(:vulnerabilities) }

  let(:existing_dismissed_at) { Time.now }
  let(:states) { { detected: 1, dismissed: 2, resolved: 3, confirmed: 4 } }
  let!(:namespace) { namespaces.create!(name: "foo", path: "bar") }
  let!(:user_1) { users.create!(name: 'John Doe', email: 'john_doe+1@example.com', projects_limit: 5) }
  let!(:user_2) { users.create!(name: 'John Doe', email: 'john_doe+2@example.com', projects_limit: 5) }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:vulnerability_params) do
    {
      project_id: project.id,
      author_id: user_1.id,
      title: 'Vulnerability',
      severity: 5,
      confidence: 5,
      report_type: 5
    }
  end

  let!(:detected_vulnerability) { vulnerabilities.create!(**vulnerability_params, state: states[:detected]) }
  let!(:resolved_vulnerability) { vulnerabilities.create!(**vulnerability_params, state: states[:resolved]) }
  let!(:confirmed_vulnerability) { vulnerabilities.create!(**vulnerability_params, state: states[:confirmed]) }

  let!(:dismissed_vulnerability_1) { vulnerabilities.create!(**vulnerability_params, state: states[:dismissed], updated_by_id: user_2.id) }
  let!(:dismissed_vulnerability_2) { vulnerabilities.create!(**vulnerability_params, state: states[:dismissed], last_edited_by_id: user_2.id) }
  let!(:dismissed_vulnerability_3) { vulnerabilities.create!(**vulnerability_params, state: states[:dismissed], dismissed_at: existing_dismissed_at, author_id: user_2.id) }
  let!(:dismissed_vulnerability_4) { vulnerabilities.create!(**vulnerability_params, state: states[:dismissed], dismissed_by_id: user_1.id, author_id: user_2.id) }
  let!(:dismissed_vulnerability_5) { vulnerabilities.create!(**vulnerability_params, state: states[:dismissed], dismissed_at: existing_dismissed_at, dismissed_by_id: user_1.id, updated_by_id: user_2.id) }

  around do |example|
    freeze_time { example.run }
  end

  it 'updates the dismissal information for vulnerabilities' do
    expect { migrate! }.to change { dismissed_vulnerability_1.reload.dismissed_at }.from(nil).to(dismissed_vulnerability_1.updated_at)
                       .and change { dismissed_vulnerability_1.reload.dismissed_by_id }.from(nil).to(user_2.id)
                       .and change { dismissed_vulnerability_2.reload.dismissed_at }.from(nil).to(dismissed_vulnerability_2.updated_at)
                       .and change { dismissed_vulnerability_2.reload.dismissed_by_id }.from(nil).to(user_2.id)
                       .and change { dismissed_vulnerability_3.reload.dismissed_by_id }.from(nil).to(user_2.id)
                       .and change { dismissed_vulnerability_4.reload.dismissed_at }.from(nil).to(dismissed_vulnerability_4.updated_at)
                       .and not_change { dismissed_vulnerability_3.reload.dismissed_at }.from(existing_dismissed_at)
                       .and not_change { dismissed_vulnerability_4.reload.dismissed_by_id }.from(user_1.id)
                       .and not_change { dismissed_vulnerability_5.reload.dismissed_at }.from(existing_dismissed_at)
                       .and not_change { dismissed_vulnerability_5.reload.dismissed_by_id }.from(user_1.id)
                       .and not_change { detected_vulnerability.reload.dismissed_at }.from(nil)
                       .and not_change { detected_vulnerability.reload.dismissed_by_id }.from(nil)
                       .and not_change { resolved_vulnerability.reload.dismissed_at }.from(nil)
                       .and not_change { resolved_vulnerability.reload.dismissed_by_id }.from(nil)
                       .and not_change { confirmed_vulnerability.reload.dismissed_at }.from(nil)
                       .and not_change { confirmed_vulnerability.reload.dismissed_by_id }.from(nil)
  end
end
