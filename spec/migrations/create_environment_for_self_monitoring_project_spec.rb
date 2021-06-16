# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateEnvironmentForSelfMonitoringProject do
  let(:application_settings_table) { table(:application_settings) }

  let(:environments) { table(:environments) }

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

  context 'when the self monitoring project ID is not set' do
    it 'does not make changes' do
      expect(environments.find_by(project_id: self_monitoring_project.id)).to be_nil

      migrate!

      expect(environments.find_by(project_id: self_monitoring_project.id)).to be_nil
    end
  end

  context 'when the self monitoring project ID is set' do
    before do
      application_settings_table.create!(instance_administration_project_id: self_monitoring_project.id)
    end

    context 'when the environment already exists' do
      let!(:environment) do
        environments.create!(project_id: self_monitoring_project.id, name: 'production', slug: 'production')
      end

      it 'does not make changes' do
        expect(environments.find_by(project_id: self_monitoring_project.id)).to eq(environment)

        migrate!

        expect(environments.find_by(project_id: self_monitoring_project.id)).to eq(environment)
      end
    end

    context 'when the environment does not exist' do
      it 'creates the environment' do
        expect(environments.find_by(project_id: self_monitoring_project.id)).to be_nil

        migrate!

        expect(environments.find_by(project_id: self_monitoring_project.id)).to be
      end
    end
  end
end
