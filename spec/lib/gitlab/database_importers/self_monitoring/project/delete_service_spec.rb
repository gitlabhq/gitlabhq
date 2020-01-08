# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::DatabaseImporters::SelfMonitoring::Project::DeleteService do
  describe '#execute' do
    let(:result) { subject.execute }
    let(:application_setting) { Gitlab::CurrentSettings.current_application_settings }

    before do
      allow(ApplicationSetting).to receive(:current_without_cache) { application_setting }
    end

    context 'when project does not exist' do
      it 'returns error' do
        expect(result).to eq(
          status: :error,
          message: 'Self monitoring project does not exist',
          last_step: :validate_self_monitoring_project_exists
        )
      end
    end

    context 'with project destroyed but ID still present in application settings' do
      before do
        application_setting.instance_administration_project_id = 1
      end

      it 'deletes project ID from application settings' do
        subject.execute

        expect(application_setting.instance_administration_project_id).to be_nil
      end
    end

    context 'when self monitoring project exists' do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }

      before do
        application_setting.instance_administration_project = project
      end

      it 'destroys project' do
        subject.execute

        expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes project ID from application settings' do
        subject.execute

        expect(application_setting.instance_administration_project_id).to be_nil
      end
    end
  end
end
