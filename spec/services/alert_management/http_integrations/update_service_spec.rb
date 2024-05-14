# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegrations::UpdateService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user_with_permissions) }
  let_it_be_with_reload(:integration) { create(:alert_management_http_integration, :inactive, project: project, name: 'Old Name') }

  let(:current_user) { user_with_permissions }
  let(:params) { {} }

  let(:service) { described_class.new(integration, current_user, params) }

  describe '#execute' do
    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(response).to be_error
        expect(response.message).to eq(message)
      end
    end

    subject(:response) { service.execute }

    context 'when the current_user is anonymous' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have insufficient permissions to update this HTTP integration'
    end

    context 'when current_user does not have permission to create integrations' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to update this HTTP integration'
    end

    context 'when an error occurs during update' do
      let(:params) { { name: '' } }

      it_behaves_like 'error response', "Name can't be blank"
    end

    context 'with name param' do
      let(:params) { { name: 'New Name' } }

      it 'successfully updates the integration' do
        expect(response).to be_success
        expect(response.payload[:integration].name).to eq('New Name')
      end
    end

    context 'with active param' do
      let(:params) { { active: true } }

      it 'successfully updates the integration' do
        expect(response).to be_success
        expect(response.payload[:integration]).to be_active
      end
    end

    context 'with regenerate_token flag' do
      let(:params) { { regenerate_token: true } }

      it 'successfully updates the integration' do
        previous_token = integration.token

        expect(response).to be_success
        expect(response.payload[:integration].token).not_to eq(previous_token)
      end
    end
  end
end
