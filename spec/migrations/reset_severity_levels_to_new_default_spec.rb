# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe ResetSeverityLevelsToNewDefault do
  let(:approval_project_rules) { table(:approval_project_rules) }
  let(:projects) { table(:projects)}
  let(:namespaces) { table(:namespaces)}
  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace')}
  let(:project) { projects.create!(name: 'project', path: 'project', namespace_id: namespace.id)}
  let(:approval_project_rule) { approval_project_rules.create!(name: 'rule', project_id: project.id, severity_levels: severity_levels) }

  context 'without having all severity levels selected' do
    let(:severity_levels) { ['high'] }

    it 'does not change severity_levels' do
      expect(approval_project_rule.severity_levels).to eq(severity_levels)
      expect { migrate! }.not_to change { approval_project_rule.reload.severity_levels }
    end
  end

  context 'with all scanners selected' do
    let(:severity_levels) { ::Enums::Vulnerability::SEVERITY_LEVELS.keys }
    let(:default_levels) { %w(unknown high critical) }

    it 'changes severity_levels to the default value' do
      expect(approval_project_rule.severity_levels).to eq(severity_levels)
      expect { migrate! }.to change {approval_project_rule.reload.severity_levels}.from(severity_levels).to(default_levels)
    end
  end
end
