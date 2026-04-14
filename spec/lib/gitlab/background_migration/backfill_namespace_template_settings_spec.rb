# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNamespaceTemplateSettings, feature_category: :groups_and_projects do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:namespace_template_settings) { table(:namespace_template_settings) }

  let!(:organization) { organizations.create!(name: 'Org 1', path: 'org-1') }

  let!(:group_with_file_template) do
    namespaces.create!(
      name: 'Group with file template',
      path: 'group-file-template',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:template_project) do
    project_namespace = namespaces.create!(
      name: 'template-project',
      path: 'template-project',
      type: 'Project',
      organization_id: organization.id,
      parent_id: group_with_file_template.id
    )

    projects.create!(
      name: 'Template Project',
      path: 'template-project',
      namespace_id: group_with_file_template.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:group_with_custom_templates) do
    namespaces.create!(
      name: 'Group with custom templates',
      path: 'group-custom-templates',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:subgroup) do
    namespaces.create!(
      name: 'Subgroup',
      path: 'subgroup',
      type: 'Group',
      organization_id: organization.id,
      parent_id: group_with_custom_templates.id
    )
  end

  let!(:group_with_both) do
    namespaces.create!(
      name: 'Group with both',
      path: 'group-both',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let!(:group_without_templates) do
    namespaces.create!(
      name: 'Group without templates',
      path: 'group-none',
      type: 'Group',
      organization_id: organization.id
    )
  end

  before do
    group_with_file_template.update!(file_template_project_id: template_project.id)
    group_with_custom_templates.update!(custom_project_templates_group_id: subgroup.id)
    group_with_both.update!(
      file_template_project_id: template_project.id,
      custom_project_templates_group_id: subgroup.id
    )
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: namespaces.minimum(:id),
      end_id: namespaces.maximum(:id),
      batch_table: :namespaces,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'backfills namespace_template_settings for namespaces with template columns set', :aggregate_failures do
    perform_migration

    setting = namespace_template_settings.find_by(namespace_id: group_with_file_template.id)
    expect(setting).to be_present
    expect(setting.file_template_project_id).to eq(template_project.id)
    expect(setting.custom_project_templates_group_id).to be_nil

    setting = namespace_template_settings.find_by(namespace_id: group_with_custom_templates.id)
    expect(setting).to be_present
    expect(setting.file_template_project_id).to be_nil
    expect(setting.custom_project_templates_group_id).to eq(subgroup.id)

    setting = namespace_template_settings.find_by(namespace_id: group_with_both.id)
    expect(setting).to be_present
    expect(setting.file_template_project_id).to eq(template_project.id)
    expect(setting.custom_project_templates_group_id).to eq(subgroup.id)
  end

  it 'does not create rows for namespaces without template columns' do
    perform_migration

    expect(namespace_template_settings.find_by(namespace_id: group_without_templates.id)).to be_nil
  end

  it 'does not overwrite existing dual-written values' do
    namespace_template_settings.create!(
      namespace_id: group_with_both.id,
      file_template_project_id: template_project.id,
      custom_project_templates_group_id: nil,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )

    perform_migration

    setting = namespace_template_settings.find_by(namespace_id: group_with_both.id)
    expect(setting.file_template_project_id).to eq(template_project.id)
    expect(setting.custom_project_templates_group_id).to be_nil
    expect(setting.updated_at).to be_within(1.second).of(1.day.ago)
  end

  it 'does not update existing row with nil values even when namespace has values set' do
    namespace_template_settings.create!(
      namespace_id: group_with_both.id,
      file_template_project_id: nil,
      custom_project_templates_group_id: nil,
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )

    perform_migration

    setting = namespace_template_settings.find_by(namespace_id: group_with_both.id)
    expect(setting.file_template_project_id).to be_nil
    expect(setting.custom_project_templates_group_id).to be_nil
    expect(setting.updated_at).to be_within(1.second).of(1.day.ago)
  end
end
