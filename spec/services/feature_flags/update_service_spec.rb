# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlags::UpdateService, :with_license, feature_category: :feature_flags do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:user) { developer }
  let(:feature_flag) { create(:operations_feature_flag, project: project, active: true) }

  describe '#execute' do
    subject { described_class.new(project, user, params).execute(feature_flag) }

    let(:params) { { name: 'new_name' } }
    let(:audit_event_details) { AuditEvent.last.details }
    let(:audit_event_message) { audit_event_details[:custom_message] }

    it 'returns success status' do
      expect(subject[:status]).to eq(:success)
    end

    context 'when Jira Connect subscription does not exist' do
      it 'does not sync the feature flag to Jira' do
        expect(::JiraConnect::SyncFeatureFlagsWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'when Jira Connect subscription exists' do
      before do
        create(:jira_connect_subscription, namespace: project.namespace)
      end

      it 'syncs the feature flag to Jira' do
        expect(::JiraConnect::SyncFeatureFlagsWorker).to receive(:perform_async).with(Integer, Integer)

        subject
      end
    end

    it 'creates audit event with correct message' do
      name_was = feature_flag.name

      expect { subject }.to change { AuditEvent.count }.by(1)
      expect(audit_event_message).to(
        eq("Updated feature flag new_name. "\
           "Updated name from \"#{name_was}\" "\
           "to \"new_name\".")
      )
    end

    it_behaves_like 'update feature flag client'

    context 'with invalid params' do
      let(:params) { { name: nil } }

      it 'returns error status' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:http_status]).to eq(:bad_request)
      end

      it 'returns error messages' do
        expect(subject[:message]).to include("Name can't be blank")
      end

      it 'does not create audit event' do
        expect { subject }.not_to change { AuditEvent.count }
      end

      it 'does not sync the feature flag to Jira' do
        expect(::JiraConnect::SyncFeatureFlagsWorker).not_to receive(:perform_async)

        subject
      end

      it_behaves_like 'does not update feature flag client'
    end

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns error status' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq('Access Denied')
      end
    end

    context 'when nothing is changed' do
      let(:params) { {} }

      it 'returns success status' do
        expect(subject[:status]).to eq(:success)
      end

      it 'does not create audit event' do
        expect { subject }.not_to change { AuditEvent.count }
      end
    end

    context 'description is being changed' do
      let(:params) { { description: 'new description' } }

      it 'creates audit event with changed description' do
        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(audit_event_message).to(
          include("Updated description from \"\" "\
                  "to \"new description\".")
        )
      end
    end

    context 'when flag active state is changed' do
      let(:params) do
        {
          active: false
        }
      end

      it 'creates audit event about changing active state' do
        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(audit_event_message).to(
          include('Updated active from "true" to "false".')
        )
      end

      it 'executes hooks' do
        hook = create(:project_hook, :all_events_enabled, project: project)
        expect(WebHookWorker).to receive(:perform_async).with(hook.id, an_instance_of(Hash), 'feature_flag_hooks', an_instance_of(Hash))

        subject
      end
    end
  end
end
