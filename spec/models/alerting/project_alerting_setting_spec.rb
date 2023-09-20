# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alerting::ProjectAlertingSetting, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }

  subject { create(:project_alerting_setting, project: project) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe '#token' do
    context 'when set' do
      let(:token) { SecureRandom.hex }

      subject do
        create(:project_alerting_setting, project: project, token: token)
      end

      it 'reads the token' do
        expect(subject.token).to eq(token)
        expect(subject.encrypted_token).not_to be_nil
        expect(subject.encrypted_token_iv).not_to be_nil
      end
    end

    context 'when not set' do
      before do
        subject.token = nil
      end

      it 'generates a token before validation' do
        expect(subject).to be_valid
        expect(subject.token).to match(/\A\h{32}\z/)
      end
    end
  end

  describe '#sync_http_integration after_save callback' do
    let_it_be_with_reload(:setting) { create(:project_alerting_setting, :with_http_integration, project: project) }
    let_it_be_with_reload(:http_integration) { setting.project.alert_management_http_integrations.last! }
    let_it_be(:new_token) { 'new_token' }

    context 'with corresponding HTTP integration' do
      let_it_be(:original_token) { http_integration.token }

      it 'syncs the attribute' do
        expect { setting.update!(token: new_token) }
          .to change { http_integration.reload.token }
          .from(original_token).to(new_token)
      end
    end

    context 'without corresponding HTTP integration' do
      before do
        http_integration.update_columns(endpoint_identifier: 'legacy')
      end

      it 'does not sync the attribute or execute extra queries' do
        expect { setting.update!(token: new_token) }
          .not_to change { http_integration.reload.token }
      end
    end
  end
end
