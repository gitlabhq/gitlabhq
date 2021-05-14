# frozen_string_literal: true

# Input
#  - factory: [:clusters_applications_elastic_stack, :clusters_integrations_elastic_stack]
RSpec.shared_examples 'cluster-based #elasticsearch_client' do |factory|
  describe '#elasticsearch_client' do
    context 'cluster is nil' do
      subject { build(factory, cluster: nil) }

      it 'returns nil' do
        expect(subject.cluster).to be_nil
        expect(subject.elasticsearch_client).to be_nil
      end
    end

    context "cluster doesn't have kubeclient" do
      let(:cluster) { create(:cluster) }

      subject { create(factory, cluster: cluster) }

      it 'returns nil' do
        expect(subject.elasticsearch_client).to be_nil
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

      it 'creates proxy elasticsearch_client' do
        expect(subject.elasticsearch_client).to be_instance_of(Elasticsearch::Transport::Client)
      end

      it 'copies proxy_url, options and headers from kube client to elasticsearch_client' do
        expect(Elasticsearch::Client)
          .to(receive(:new))
          .with(url: a_valid_url)
          .and_call_original

        client = subject.elasticsearch_client
        faraday_connection = client.transport.connections.first.connection

        expect(faraday_connection.headers["Authorization"]).to eq(kube_client.headers[:Authorization])
        expect(faraday_connection.ssl.cert_store).to be_instance_of(OpenSSL::X509::Store)
        expect(faraday_connection.ssl.verify).to eq(1)
        expect(faraday_connection.options.timeout).to be_nil
      end

      context 'when cluster is not reachable' do
        before do
          allow(kube_client).to receive(:proxy_url).and_raise(Kubeclient::HttpError.new(401, 'Unauthorized', nil))
        end

        it 'returns nil' do
          expect(subject.elasticsearch_client).to be_nil
        end
      end

      context 'when timeout is provided' do
        it 'sets timeout in elasticsearch_client' do
          client = subject.elasticsearch_client(timeout: 123)
          faraday_connection = client.transport.connections.first.connection

          expect(faraday_connection.options.timeout).to eq(123)
        end
      end
    end
  end
end
