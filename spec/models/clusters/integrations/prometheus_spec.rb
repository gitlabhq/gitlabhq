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
