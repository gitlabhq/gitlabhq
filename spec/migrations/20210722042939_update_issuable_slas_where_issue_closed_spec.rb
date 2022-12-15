# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateIssuableSlasWhereIssueClosed, :migration, feature_category: :team_planning do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:issuable_slas) { table(:issuable_slas) }
  let(:issue_params) { { title: 'title', project_id: project.id } }
  let(:issue_closed_state) { 2 }

  let!(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:issue_open) { issues.create!(issue_params) }
  let!(:issue_closed) { issues.create!(issue_params.merge(state_id: issue_closed_state)) }

  let!(:issuable_sla_open_issue) { issuable_slas.create!(issue_id: issue_open.id, due_at: Time.now) }
  let!(:issuable_sla_closed_issue) { issuable_slas.create!(issue_id: issue_closed.id, due_at: Time.now) }

  it 'sets the issuable_closed attribute to false' do
    expect(issuable_sla_open_issue.issuable_closed).to eq(false)
    expect(issuable_sla_closed_issue.issuable_closed).to eq(false)

    migrate!

    expect(issuable_sla_open_issue.reload.issuable_closed).to eq(false)
    expect(issuable_sla_closed_issue.reload.issuable_closed).to eq(true)
  end
end
