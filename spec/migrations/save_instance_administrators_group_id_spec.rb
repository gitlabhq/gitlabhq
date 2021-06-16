# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SaveInstanceAdministratorsGroupId do
  let(:application_settings_table) { table(:application_settings) }

  let(:instance_administrators_group) do
    table(:namespaces).create!(
      id: 1,
      name: 'GitLab Instance Administrators',
      path: 'gitlab-instance-administrators-random',
      type: 'Group'
    )
  end

  let(:self_monitoring_project) do
    table(:projects).create!(
      id: 2,
      name: 'Self Monitoring',
      path: 'self_monitoring',
      namespace_id: instance_administrators_group.id
    )
  end

  context 'when project ID is saved but group ID is not' do
    let(:application_settings) do
      application_settings_table.create!(instance_administration_project_id: self_monitoring_project.id)
    end

    it 'saves instance administrators group ID' do
      expect(application_settings.instance_administration_project_id).to eq(self_monitoring_project.id)
      expect(application_settings.instance_administrators_group_id).to be_nil

      migrate!

      expect(application_settings.reload.instance_administrators_group_id).to eq(instance_administrators_group.id)
      expect(application_settings.instance_administration_project_id).to eq(self_monitoring_project.id)
    end
  end

  context 'when group ID is saved but project ID is not' do
    let(:application_settings) do
      application_settings_table.create!(instance_administrators_group_id: instance_administrators_group.id)
    end

    it 'does not make changes' do
      expect(application_settings.instance_administrators_group_id).to eq(instance_administrators_group.id)
      expect(application_settings.instance_administration_project_id).to be_nil

      migrate!

      expect(application_settings.reload.instance_administrators_group_id).to eq(instance_administrators_group.id)
      expect(application_settings.instance_administration_project_id).to be_nil
    end
  end

  context 'when group ID and project ID are both saved' do
    let(:application_settings) do
      application_settings_table.create!(
        instance_administrators_group_id: instance_administrators_group.id,
        instance_administration_project_id: self_monitoring_project.id
      )
    end

    it 'does not make changes' do
      expect(application_settings.instance_administrators_group_id).to eq(instance_administrators_group.id)
      expect(application_settings.instance_administration_project_id).to eq(self_monitoring_project.id)

      migrate!

      expect(application_settings.reload.instance_administrators_group_id).to eq(instance_administrators_group.id)
      expect(application_settings.instance_administration_project_id).to eq(self_monitoring_project.id)
    end
  end

  context 'when neither group ID nor project ID is saved' do
    let(:application_settings) do
      application_settings_table.create!
    end

    it 'does not make changes' do
      expect(application_settings.instance_administrators_group_id).to be_nil
      expect(application_settings.instance_administration_project_id).to be_nil

      migrate!

      expect(application_settings.reload.instance_administrators_group_id).to be_nil
      expect(application_settings.instance_administration_project_id).to be_nil
    end
  end

  context 'when application_settings table has no rows' do
    it 'does not fail' do
      migrate!
    end
  end
end
