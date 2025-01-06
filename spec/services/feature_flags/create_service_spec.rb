# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlags::CreateService, feature_category: :feature_flags do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:user) { developer }

  describe '#execute' do
    subject do
      described_class.new(project, user, params).execute
    end

    let(:feature_flag) { subject[:feature_flag] }

    context 'when feature flag can not be created' do
      let(:params) { {} }

      it 'returns status error' do
        expect(subject[:status]).to eq(:error)
      end

      it 'returns validation errors' do
        expect(subject[:message]).to include("Name can't be blank")
      end

      it 'does not create audit log' do
        expect { subject }.not_to change { AuditEvent.count }
      end

      it 'does not sync the feature flag to Jira' do
        expect(::JiraConnect::SyncFeatureFlagsWorker).not_to receive(:perform_async)

        subject
      end

      it_behaves_like 'does not update feature flag client'
    end

    context 'when feature flag is saved correctly' do
      let(:audit_event_details) { AuditEvent.last.details }
      let(:audit_event_message) { audit_event_details[:custom_message] }
      let(:params) do
        {
          name: 'feature_flag',
          description: 'description',
          version: 'new_version_flag',
          strategies_attributes: [{ name: 'default', scopes_attributes: [{ environment_scope: '*' }], parameters: {} },
            { name: 'default', parameters: {}, scopes_attributes: [{ environment_scope: 'production' }] }]
        }
      end

      it 'returns status success' do
        expect(subject[:status]).to eq(:success)
      end

      it 'creates feature flag' do
        expect { subject }.to change { Operations::FeatureFlag.count }.by(1)
      end

      it_behaves_like 'update feature flag client'

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

      it 'creates audit event', :with_license, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/509493' do
        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(audit_event_message).to start_with('Created feature flag feature_flag with description "description".')
        expect(audit_event_message).to include('Created strategy "default" with scopes "*".')
        expect(audit_event_message).to include('Created strategy "default" with scopes "production".')
      end

      context 'when user is reporter' do
        let(:user) { reporter }

        it 'returns error status' do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to eq('Access Denied')
        end
      end
    end
  end
end
