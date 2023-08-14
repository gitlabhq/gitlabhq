# frozen_string_literal: true

require "spec_helper"

RSpec.describe ServiceDesk::CustomEmailVerificationCleanupWorker, type: :worker, feature_category: :service_desk do
  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let!(:credential) { create(:service_desk_custom_email_credential, project: project) }
    let!(:settings) { create(:service_desk_setting, project: project, custom_email: 'user@example.com') }
    let!(:verification) { create(:service_desk_custom_email_verification, :overdue, project: project) }

    it 'calls the custom email verification update service' do
      expect_next_instance_of(ServiceDesk::CustomEmailVerifications::UpdateService) do |instance|
        expect(instance.project).to eq project
        expect(instance).to receive(:execute).once
      end

      described_class.new.perform
    end

    context 'with more than one verification being overdue' do
      let!(:other_credential) { create(:service_desk_custom_email_credential, project: other_project) }
      let!(:other_settings) do
        create(:service_desk_setting, project: other_project, custom_email: 'support@example.com')
      end

      let!(:other_verification) { create(:service_desk_custom_email_verification, :overdue, project: other_project) }

      it 'calls the custom email verification update service for each project' do
        project_id_call_order = []
        expect_next_instances_of(ServiceDesk::CustomEmailVerifications::UpdateService, 2) do |instance|
          project_id_call_order << instance.project.id
          expect(instance).to receive(:execute).once
        end

        described_class.new.perform

        # Also check for order as find_each oders by primary key (project_id) for batching
        expect(project_id_call_order).to eq [project.id, other_project.id]
      end
    end
  end
end
