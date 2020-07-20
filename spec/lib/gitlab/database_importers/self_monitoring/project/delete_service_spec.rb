# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::SelfMonitoring::Project::DeleteService do
  describe '#execute' do
    let!(:application_setting) { create(:application_setting) }
    let(:result) { subject.execute }

    context 'when project does not exist' do
      it 'returns error' do
        expect(result).to eq(
          status: :error,
          message: 'Self monitoring project does not exist',
          last_step: :validate_self_monitoring_project_exists
        )
      end
    end

    context 'when self monitoring project exists' do
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }

      let(:application_setting) do
        create(
          :application_setting,
          self_monitoring_project_id: project.id,
          instance_administrators_group_id: group.id
        )
      end

      it 'destroys project' do
        subject.execute

        expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes project ID from application settings' do
        subject.execute

        expect(application_setting.reload.self_monitoring_project_id).to be_nil
      end

      it 'does not delete group' do
        subject.execute

        expect(application_setting.instance_administrators_group).to eq(group)
      end
    end
  end
end
