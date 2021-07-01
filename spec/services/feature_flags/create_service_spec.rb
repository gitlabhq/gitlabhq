# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlags::CreateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let(:user) { developer }

  before_all do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

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
    end

    context 'when feature flag is saved correctly' do
      let(:params) do
        {
          name: 'feature_flag',
          description: 'description',
          scopes_attributes: [{ environment_scope: '*', active: true },
                              { environment_scope: 'production', active: false }]
        }
      end

      it 'returns status success' do
        expect(subject[:status]).to eq(:success)
      end

      it 'creates feature flag' do
        expect { subject }.to change { Operations::FeatureFlag.count }.by(1)
      end

      it 'syncs the feature flag to Jira' do
        expect(::JiraConnect::SyncFeatureFlagsWorker).to receive(:perform_async).with(Integer, Integer)

        subject
      end

      it 'creates audit event' do
        expected_message = 'Created feature flag feature_flag '\
                           'with description "description". '\
                           'Created rule * and set it as active '\
                           'with strategies [{"name"=&gt;"default", "parameters"=&gt;{}}]. '\
                           'Created rule production and set it as inactive '\
                           'with strategies [{"name"=&gt;"default", "parameters"=&gt;{}}].'

        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details[:custom_message]).to eq(expected_message)
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
