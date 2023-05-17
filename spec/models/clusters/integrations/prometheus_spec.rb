# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Integrations::Prometheus do
  include KubernetesHelpers
  include StubRequests

  describe 'associations' do
    it { is_expected.to belong_to(:cluster).class_name('Clusters::Cluster') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:cluster) }
    it { is_expected.not_to allow_value(nil).for(:enabled) }
  end

  describe 'default values' do
    subject(:integration) { build(:clusters_integrations_prometheus) }

    before do
      allow(SecureRandom).to receive(:hex).and_return('randomtoken')
    end

    it { expect(integration.alert_manager_token).to eq('randomtoken') }
  end

  describe 'after_destroy' do
    subject(:integration) { create(:clusters_integrations_prometheus, cluster: cluster, enabled: true) }

    let(:cluster) { create(:cluster) }

    it 'deactivates prometheus_integration' do
      expect(Clusters::Applications::DeactivateIntegrationWorker)
        .to receive(:perform_async).with(cluster.id, 'prometheus')

      integration.destroy!
    end
  end

  describe 'after_save' do
    subject(:integration) { create(:clusters_integrations_prometheus, cluster: cluster, enabled: enabled) }

    let(:cluster) { create(:cluster) }
    let(:enabled) { true }

    context 'when no change to enabled status' do
      it 'does not touch project integrations' do
        integration # ensure integration exists before we set the expectations

        expect(Clusters::Applications::DeactivateIntegrationWorker)
          .not_to receive(:perform_async)

        expect(Clusters::Applications::ActivateIntegrationWorker)
          .not_to receive(:perform_async)

        integration.update!(enabled: enabled)
      end
    end

    context 'when enabling' do
      let(:enabled) { false }

      it 'activates prometheus_integration' do
        expect(Clusters::Applications::ActivateIntegrationWorker)
          .to receive(:perform_async).with(cluster.id, 'prometheus')

        integration.update!(enabled: true)
      end
    end

    context 'when disabling' do
      let(:enabled) { true }

      it 'activates prometheus_integration' do
        expect(Clusters::Applications::DeactivateIntegrationWorker)
          .to receive(:perform_async).with(cluster.id, 'prometheus')

        integration.update!(enabled: false)
      end
    end
  end

  describe '#prometheus_client' do
    include_examples '#prometheus_client shared' do
      let(:factory) { :clusters_integrations_prometheus }
    end
  end

  describe '#configured?' do
    let(:prometheus) { create(:clusters_integrations_prometheus, cluster: cluster) }

    subject { prometheus.configured? }

    context 'when a kubenetes client is present' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }

      it { is_expected.to be_truthy }

      context 'when it is disabled' do
        let(:prometheus) { create(:clusters_integrations_prometheus, :disabled, cluster: cluster) }

        it { is_expected.to be_falsey }
      end

      context 'when the kubernetes URL is blocked' do
        before do
          blocked_ip = '127.0.0.1' # localhost addresses are blocked by default

          stub_all_dns(cluster.platform.api_url, ip_address: blocked_ip)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when a kubenetes client is not present' do
      let(:cluster) { create(:cluster) }

      it { is_expected.to be_falsy }
    end
  end
end
