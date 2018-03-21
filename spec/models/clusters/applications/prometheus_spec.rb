require 'rails_helper'

describe Clusters::Applications::Prometheus do
  include_examples 'cluster application core specs', :clusters_applications_prometheus
  include_examples 'cluster application status specs', :cluster_application_prometheus

  describe 'transition to installed' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }
    let(:prometheus_service) { double('prometheus_service') }

    subject { create(:clusters_applications_prometheus, :installing, cluster: cluster) }

    before do
      allow(project).to receive(:find_or_initialize_service).with('prometheus').and_return prometheus_service
    end

    it 'ensures Prometheus service is activated' do
      expect(prometheus_service).to receive(:update).with(active: true)

      subject.make_installed
    end
  end

  describe '#prometheus_client' do
    context 'cluster is nil' do
      it 'returns nil' do
        expect(subject.cluster).to be_nil
        expect(subject.prometheus_client).to be_nil
      end
    end

    context "cluster doesn't have kubeclient" do
      let(:cluster) { create(:cluster) }
      subject { create(:clusters_applications_prometheus, cluster: cluster) }

      it 'returns nil' do
        expect(subject.prometheus_client).to be_nil
      end
    end

    context 'cluster has kubeclient' do
      let(:kubernetes_url) { 'http://example.com' }
      let(:k8s_discover_response) do
        {
          resources: [
            {
              name: 'service',
              kind: 'Service'
            }
          ]
        }
      end

      let(:kube_client) { Kubeclient::Client.new(kubernetes_url) }

      let(:cluster) { create(:cluster) }
      subject { create(:clusters_applications_prometheus, cluster: cluster) }

      before do
        allow(kube_client.rest_client).to receive(:get).and_return(k8s_discover_response.to_json)
        allow(subject.cluster).to receive(:kubeclient).and_return(kube_client)
      end

      it 'creates proxy prometheus rest client' do
        expect(subject.prometheus_client).to be_instance_of(RestClient::Resource)
      end

      it 'creates proper url' do
        expect(subject.prometheus_client.url).to eq('http://example.com/api/v1/proxy/namespaces/gitlab-managed-apps/service/prometheus-prometheus-server:80')
      end

      it 'copies options and headers from kube client to proxy client' do
        expect(subject.prometheus_client.options).to eq(kube_client.rest_client.options.merge(headers: kube_client.headers))
      end
    end
  end

  describe '#install_command' do
    let(:kubeclient) { double('kubernetes client') }
    let(:prometheus) { create(:clusters_applications_prometheus) }

    subject { prometheus.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with 3 arguments' do
      expect(subject.name).to eq('prometheus')
      expect(subject.chart).to eq('stable/prometheus')
      expect(subject.values).to eq(prometheus.values)
    end
  end

  describe '#values' do
    let(:prometheus) { create(:clusters_applications_prometheus) }

    subject { prometheus.values }

    it 'should include prometheus valid values' do
      is_expected.to include('alertmanager')
      is_expected.to include('kubeStateMetrics')
      is_expected.to include('nodeExporter')
      is_expected.to include('pushgateway')
      is_expected.to include('serverFiles')
    end
  end
end
