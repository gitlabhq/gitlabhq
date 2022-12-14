# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddDefaultProjectApprovalRulesVulnAllowed, feature_category: :source_code_management do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace') }
  let(:project) { projects.create!(name: 'project', path: 'project', namespace_id: namespace.id) }
  let(:approval_project_rules) { table(:approval_project_rules) }

  it 'updates records when vulnerabilities_allowed is nil' do
    records_to_migrate = 10

    records_to_migrate.times do |i|
      approval_project_rules.create!(name: "rule #{i}", project_id: project.id)
    end

    expect { migrate! }
      .to change { approval_project_rules.where(vulnerabilities_allowed: nil).count }
        .from(records_to_migrate)
        .to(0)
  end

  it 'defaults vulnerabilities_allowed to 0' do
    approval_project_rule = approval_project_rules.create!(name: "new rule", project_id: project.id)

    expect(approval_project_rule.vulnerabilities_allowed).to be_nil

    migrate!

    expect(approval_project_rule.reload.vulnerabilities_allowed).to eq(0)
  end
end
