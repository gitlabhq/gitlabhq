# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlags::DestroyService, feature_category: :feature_flags do
  include FeatureFlagHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:user) { developer }
  let!(:feature_flag) { create(:operations_feature_flag, project: project) }

  describe '#execute' do
    subject { described_class.new(project, user, params).execute(feature_flag) }

    let(:audit_event_details) { AuditEvent.last.details }
    let(:audit_event_message) { audit_event_details[:custom_message] }
    let(:params) { {} }

    it 'returns status success' do
      expect(subject[:status]).to eq(:success)
    end

    it 'destroys feature flag' do
      expect { subject }.to change { Operations::FeatureFlag.count }.by(-1)
    end

    it 'creates audit log', :with_license do
      expect { subject }.to change { AuditEvent.count }.by(1)
      expect(audit_event_message).to eq("Deleted feature flag #{feature_flag.name}.")
    end

    it_behaves_like 'update feature flag client'

    context 'when user is reporter' do
      let(:user) { reporter }

      it 'returns error status' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq('Access Denied')
      end
    end

    context 'when feature flag can not be destroyed' do
      before do
        allow(feature_flag).to receive(:destroy).and_return(false)
      end

      it 'returns status error' do
        expect(subject[:status]).to eq(:error)
      end

      it 'does not create audit log' do
        expect { subject }.not_to change { AuditEvent.count }
      end

      it_behaves_like 'does not update feature flag client'
    end
  end
end
