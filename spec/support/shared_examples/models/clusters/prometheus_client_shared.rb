# frozen_string_literal: true

# Input
#  - factory: [:clusters_applications_prometheus, :clusters_integrations_prometheus]
RSpec.shared_examples '#prometheus_client shared' do
  shared_examples 'exception caught for prometheus client' do
    before do
      allow(kube_client).to receive(:proxy_url).and_raise(exception)
    end

    it 'returns nil' do
      expect(subject.prometheus_client).to be_nil
    end
  end

  context 'cluster is nil' do
    it 'returns nil' do
      expect(subject.cluster).to be_nil
      expect(subject.prometheus_client).to be_nil
    end
  end

  context "cluster doesn't have kubeclient" do
    let(:cluster) { create(:cluster) }

    subject { create(factory, cluster: cluster) }

    it 'returns nil' do
      expect(subject.prometheus_client).to be_nil
    end
  end

  context 'cluster has kubeclient' do
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:kubernetes_url) { subject.cluster.platform_kubernetes.api_url }
    let(:kube_client) { subject.cluster.kubeclient.core_client }

    subject { create(factory, cluster: cluster) }

    before do
      subject.cluster.platform_kubernetes.namespace = 'a-namespace'
      stub_kubeclient_discover(cluster.platform_kubernetes.api_url)

      create(:cluster_kubernetes_namespace,
             cluster: cluster,
             cluster_project: cluster.cluster_project,
             project: cluster.cluster_project.project)
    end

    it 'creates proxy prometheus_client' do
      expect(subject.prometheus_client).to be_instance_of(Gitlab::PrometheusClient)
    end

    it 'merges proxy_url, options and headers from kube client with prometheus_client options' do
      expect(Gitlab::PrometheusClient)
        .to(receive(:new))
        .with(a_valid_url, kube_client.rest_client.options.merge({
        headers: kube_client.headers,
        timeout: PrometheusAdapter::DEFAULT_PROMETHEUS_REQUEST_TIMEOUT_SEC
      }))
      subject.prometheus_client
    end

    context 'when cluster is not reachable' do
      it_behaves_like 'exception caught for prometheus client' do
        let(:exception) { Kubeclient::HttpError.new(401, 'Unauthorized', nil) }
      end
    end

    context 'when there is a socket error while contacting cluster' do
      it_behaves_like 'exception caught for prometheus client' do
        let(:exception) { Errno::ECONNREFUSED }
      end

      it_behaves_like 'exception caught for prometheus client' do
        let(:exception) { Errno::ECONNRESET }
      end
    end

    context 'when the network is unreachable' do
      it_behaves_like 'exception caught for prometheus client' do
        let(:exception) { Errno::ENETUNREACH }
      end
    end
  end
end
