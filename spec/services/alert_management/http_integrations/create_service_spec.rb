# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::HttpIntegrations::CreateService do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be_with_reload(:project) { create(:project) }

  let(:current_user) { user_with_permissions }
  let(:params) { {} }

  let(:service) { described_class.new(project, current_user, params) }

  before_all do
    project.add_maintainer(user_with_permissions)
  end

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

      it_behaves_like 'error response', 'You have insufficient permissions to create an HTTP integration for this project'
    end

    context 'when current_user does not have permission to create integrations' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to create an HTTP integration for this project'
    end

    context 'when an integration already exists' do
      let_it_be(:existing_integration) { create(:alert_management_http_integration, project: project) }

      it_behaves_like 'error response', 'Multiple HTTP integrations are not supported for this project'
    end

    context 'when an error occurs during update' do
      it_behaves_like 'error response', "Name can't be blank"
    end

    context 'with valid params' do
      let(:params) { { name: 'New HTTP Integration', active: true } }

      it 'successfully creates an integration' do
        expect(response).to be_success

        integration = response.payload[:integration]
        expect(integration).to be_a(::AlertManagement::HttpIntegration)
        expect(integration.name).to eq('New HTTP Integration')
        expect(integration).to be_active
        expect(integration.token).to be_present
        expect(integration.endpoint_identifier).to be_present
      end
    end
  end
end
