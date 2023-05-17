# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Integrations::CreateService, '#execute', feature_category: :deployment_management do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

  let(:service) do
    described_class.new(container: project, cluster: cluster, current_user: project.first_owner, params: params)
  end

  shared_examples_for 'a cluster integration' do |application_type|
    let(:integration) { cluster.public_send("integration_#{application_type}") }

    context 'when enabled param is true' do
      let(:params) do
        { application_type: application_type, enabled: true }
      end

      it 'creates a new enabled integration' do
        expect(service.execute).to be_success

        expect(integration).to be_present
        expect(integration).to be_persisted
        expect(integration).to be_enabled
      end
    end

    context 'when enabled param is false' do
      let(:params) do
        { application_type: application_type, enabled: false }
      end

      it 'creates a new disabled integration' do
        expect(service.execute).to be_success

        expect(integration).to be_present
        expect(integration).to be_persisted
        expect(integration).not_to be_enabled
      end
    end

    context 'when integration already exists' do
      before do
        create(:"clusters_integrations_#{application_type}", cluster: cluster, enabled: false)
      end

      let(:params) do
        { application_type: application_type, enabled: true }
      end

      it 'updates the integration' do
        expect(integration).not_to be_enabled

        expect(service.execute).to be_success

        expect(integration.reload).to be_enabled
      end
    end
  end

  it_behaves_like 'a cluster integration', 'prometheus'

  context 'when application_type is invalid' do
    let(:params) do
      { application_type: 'something_else', enabled: true }
    end

    it 'errors' do
      expect { service.execute }.to raise_error(ArgumentError)
    end
  end

  context 'when user is unauthorized' do
    let(:params) do
      { application_type: 'prometheus', enabled: true }
    end

    let(:service) do
      unauthorized_user = create(:user)

      described_class.new(container: project, cluster: cluster, current_user: unauthorized_user, params: params)
    end

    it 'returns error and does not create a new integration record' do
      expect(service.execute).to be_error

      expect(cluster.integration_prometheus).to be_nil
    end
  end
end
