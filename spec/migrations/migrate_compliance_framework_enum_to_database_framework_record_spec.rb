# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateComplianceFrameworkEnumToDatabaseFrameworkRecord, schema: 20201005092753 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_compliance_framework_settings) { table(:project_compliance_framework_settings) }
  let(:compliance_management_frameworks) { table(:compliance_management_frameworks) }

  let(:gdpr_framework) { 1 }
  let(:sox_framework) { 5 }

  let!(:root_group) { namespaces.create!(type: 'Group', name: 'a', path: 'a') }
  let!(:sub_group) { namespaces.create!(type: 'Group', name: 'b', path: 'b', parent_id: root_group.id) }
  let!(:sub_sub_group) { namespaces.create!(type: 'Group', name: 'c', path: 'c', parent_id: sub_group.id) }

  let!(:namespace) { namespaces.create!(name: 'd', path: 'd') }

  let!(:project_on_root_level) { projects.create!(namespace_id: root_group.id) }
  let!(:project_on_sub_sub_level_1) { projects.create!(namespace_id: sub_sub_group.id) }
  let!(:project_on_sub_sub_level_2) { projects.create!(namespace_id: sub_sub_group.id) }
  let!(:project_on_namespace) { projects.create!(namespace_id: namespace.id) }

  let!(:project_on_root_level_compliance_setting) { project_compliance_framework_settings.create!(project_id: project_on_root_level.id, framework: gdpr_framework) }
  let!(:project_on_sub_sub_level_compliance_setting_1) { project_compliance_framework_settings.create!(project_id: project_on_sub_sub_level_1.id, framework: sox_framework) }
  let!(:project_on_sub_sub_level_compliance_setting_2) { project_compliance_framework_settings.create!(project_id: project_on_sub_sub_level_2.id, framework: gdpr_framework) }
  let!(:project_on_namespace_level_compliance_setting) { project_compliance_framework_settings.create!(project_id: project_on_namespace.id, framework: gdpr_framework) }

  subject { described_class.new.up }

  it 'updates the project settings' do
    subject

    gdpr_framework = compliance_management_frameworks.find_by(namespace_id: root_group.id, name: 'GDPR')
    expect(project_on_root_level_compliance_setting.reload.framework_id).to eq(gdpr_framework.id)
    expect(project_on_sub_sub_level_compliance_setting_2.reload.framework_id).to eq(gdpr_framework.id)

    sox_framework = compliance_management_frameworks.find_by(namespace_id: root_group.id, name: 'SOX')
    expect(project_on_sub_sub_level_compliance_setting_1.reload.framework_id).to eq(sox_framework.id)

    gdpr_framework = compliance_management_frameworks.find_by(namespace_id: namespace.id, name: 'GDPR')
    expect(project_on_namespace_level_compliance_setting.reload.framework_id).to eq(gdpr_framework.id)
  end

  it 'adds two framework records' do
    subject

    expect(compliance_management_frameworks.count).to eq(3)
  end
end
