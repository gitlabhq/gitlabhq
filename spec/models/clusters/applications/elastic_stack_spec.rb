# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::ElasticStack do
  include KubernetesHelpers

  include_examples 'cluster application core specs', :clusters_applications_elastic_stack
  include_examples 'cluster application status specs', :clusters_applications_elastic_stack
  include_examples 'cluster application version specs', :clusters_applications_elastic_stack
  include_examples 'cluster application helm specs', :clusters_applications_elastic_stack

  describe '#install_command' do
    let!(:elastic_stack) { create(:clusters_applications_elastic_stack) }

    subject { elastic_stack.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'is initialized with elastic stack arguments' do
      expect(subject.name).to eq('elastic-stack')
      expect(subject.chart).to eq('stable/elastic-stack')
      expect(subject.version).to eq('1.8.0')
      expect(subject).to be_rbac
      expect(subject.files).to eq(elastic_stack.files)
    end

    context 'on a non rbac enabled cluster' do
      before do
        elastic_stack.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'application failed to install previously' do
      let(:elastic_stack) { create(:clusters_applications_elastic_stack, :errored, version: '0.0.1') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('1.8.0')
      end
    end
  end

  describe '#uninstall_command' do
    let!(:elastic_stack) { create(:clusters_applications_elastic_stack) }

    subject { elastic_stack.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::DeleteCommand) }

    it 'is initialized with elastic stack arguments' do
      expect(subject.name).to eq('elastic-stack')
      expect(subject).to be_rbac
      expect(subject.files).to eq(elastic_stack.files)
    end

    it 'specifies a post delete command to remove custom resource definitions' do
      expect(subject.postdelete).to eq([
        'kubectl delete pvc --selector release\\=elastic-stack'
      ])
    end
  end

  describe '#elasticsearch_client' do
    context 'cluster is nil' do
      it 'returns nil' do
        expect(subject.cluster).to be_nil
        expect(subject.elasticsearch_client).to be_nil
      end
    end

    context "cluster doesn't have kubeclient" do
      let(:cluster) { create(:cluster) }

      subject { create(:clusters_applications_elastic_stack, cluster: cluster) }

      it 'returns nil' do
        expect(subject.elasticsearch_client).to be_nil
      end
    end

    context 'cluster has kubeclient' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:kubernetes_url) { subject.cluster.platform_kubernetes.api_url }
      let(:kube_client) { subject.cluster.kubeclient.core_client }

      subject { create(:clusters_applications_elastic_stack, cluster: cluster) }

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
      end

      context 'when cluster is not reachable' do
        before do
          allow(kube_client).to receive(:proxy_url).and_raise(Kubeclient::HttpError.new(401, 'Unauthorized', nil))
        end

        it 'returns nil' do
          expect(subject.elasticsearch_client).to be_nil
        end
      end
    end
  end
end
