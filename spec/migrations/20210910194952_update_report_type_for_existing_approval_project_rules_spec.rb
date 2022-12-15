# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateReportTypeForExistingApprovalProjectRules, :migration, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  let(:group) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:project) { table(:projects).create!(namespace_id: group.id) }
  let(:approval_project_rule) { table(:approval_project_rules).create!(name: rule_name, rule_type: rule_type, project_id: project.id) }
  let(:rule_type) { 2 }
  let(:rule_name) { 'Vulnerability-Check' }

  context 'with rule_type set to :report_approver' do
    where(:rule_name, :report_type) do
      [
        ['Vulnerability-Check', 1],
        ['License-Check', 2],
        ['Coverage-Check', 3]
      ]
    end

    with_them do
      context "with names associated with report type" do
        it 'updates report_type' do
          expect { migrate! }.to change { approval_project_rule.reload.report_type }.from(nil).to(report_type)
        end
      end
    end
  end

  context 'with rule_type set to another value (e.g., :regular)' do
    let(:rule_type) { 0 }

    it 'does not update report_type' do
      expect { migrate! }.not_to change { approval_project_rule.reload.report_type }
    end
  end

  context 'with the rule name set to another value (e.g., Test Rule)' do
    let(:rule_name) { 'Test Rule' }

    it 'does not update report_type' do
      expect { migrate! }.not_to change { approval_project_rule.reload.report_type }
    end
  end
end
