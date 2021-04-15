# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Integrations::CreateService, '#execute' do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

  let(:params) do
    { application_type: 'prometheus', enabled: true }
  end

  let(:service) do
    described_class.new(container: project, cluster: cluster, current_user: project.owner, params: params)
  end

  it 'creates a new Prometheus instance' do
    expect(service.execute).to be_success

    expect(cluster.integration_prometheus).to be_present
    expect(cluster.integration_prometheus).to be_persisted
    expect(cluster.integration_prometheus).to be_enabled
  end

  context 'enabled param is false' do
    let(:params) do
      { application_type: 'prometheus', enabled: false }
    end

    it 'creates a new uninstalled Prometheus instance' do
      expect(service.execute).to be_success

      expect(cluster.integration_prometheus).to be_present
      expect(cluster.integration_prometheus).to be_persisted
      expect(cluster.integration_prometheus).not_to be_enabled
    end
  end

  context 'unauthorized user' do
    let(:service) do
      unauthorized_user = create(:user)

      described_class.new(container: project, cluster: cluster, current_user: unauthorized_user, params: params)
    end

    it 'does not create a new Prometheus instance' do
      expect(service.execute).to be_error

      expect(cluster.integration_prometheus).to be_nil
    end
  end

  context 'prometheus record exists' do
    before do
      create(:clusters_integrations_prometheus, cluster: cluster)
    end

    it 'updates the Prometheus instance' do
      expect(service.execute).to be_success

      expect(cluster.integration_prometheus).to be_present
      expect(cluster.integration_prometheus).to be_persisted
      expect(cluster.integration_prometheus).to be_enabled
    end

    context 'enabled param is false' do
      let(:params) do
        { application_type: 'prometheus', enabled: false }
      end

      it 'updates the Prometheus instance as uninstalled' do
        expect(service.execute).to be_success

        expect(cluster.integration_prometheus).to be_present
        expect(cluster.integration_prometheus).to be_persisted
        expect(cluster.integration_prometheus).not_to be_enabled
      end
    end
  end

  context 'for an un-supported application type' do
    let(:params) do
      { application_type: 'something_else', enabled: true }
    end

    it 'errors' do
      expect { service.execute}.to raise_error(ArgumentError)
    end
  end
end
