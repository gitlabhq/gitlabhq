# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegrations::DestroyService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user_with_permissions) }

  let!(:integration) { create(:alert_management_http_integration, project: project) }
  let(:current_user) { user_with_permissions }
  let(:params) { {} }
  let(:service) { described_class.new(integration, current_user) }

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

      it_behaves_like 'error response', 'You have insufficient permissions to remove this HTTP integration'
    end

    context 'when current_user does not have permission to create integrations' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to remove this HTTP integration'
    end

    context 'when an error occurs during removal' do
      before do
        allow(integration).to receive(:destroy).and_return(false)
        integration.errors.add(:name, 'cannot be removed')
      end

      it_behaves_like 'error response', 'Name cannot be removed'
    end

    context 'when destroying a legacy Prometheus integration' do
      let_it_be(:existing_integration) { create(:alert_management_prometheus_integration, :legacy, project: project) }
      let!(:integration) { existing_integration }

      it_behaves_like 'error response', 'Legacy Prometheus integrations cannot currently be removed'
    end

    it 'successfully returns the integration' do
      expect(response).to be_success

      integration_result = response.payload[:integration]
      expect(integration_result).to be_a(::AlertManagement::HttpIntegration)
      expect(integration_result.name).to eq(integration.name)
      expect(integration_result.active).to eq(integration.active)
      expect(integration_result.token).to eq(integration.token)
      expect(integration_result.endpoint_identifier).to eq(integration.endpoint_identifier)

      expect { integration.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
