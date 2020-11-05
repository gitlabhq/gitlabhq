# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::ElasticStack do
  include KubernetesHelpers

  include_examples 'cluster application core specs', :clusters_applications_elastic_stack
  include_examples 'cluster application status specs', :clusters_applications_elastic_stack
  include_examples 'cluster application version specs', :clusters_applications_elastic_stack
  include_examples 'cluster application helm specs', :clusters_applications_elastic_stack

  describe '#install_command' do
    let!(:elastic_stack) { create(:clusters_applications_elastic_stack) }

    subject { elastic_stack.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::V3::InstallCommand) }

    it 'is initialized with elastic stack arguments' do
      expect(subject.name).to eq('elastic-stack')
      expect(subject.chart).to eq('elastic-stack/elastic-stack')
      expect(subject.version).to eq('3.0.0')
      expect(subject.repository).to eq('https://charts.gitlab.io')
      expect(subject).to be_rbac
      expect(subject.files).to eq(elastic_stack.files)
      expect(subject.preinstall).to be_empty
    end

    context 'within values.yaml' do
      let(:values_yaml_content) {subject.files[:"values.yaml"]}

      it 'contains the disabled index lifecycle management' do
        expect(values_yaml_content).to include "setup.ilm.enabled: false"
      end

      it 'contains daily indices with respective template' do
        expect(values_yaml_content).to include "index: \"filebeat-%{[agent.version]}-%{+yyyy.MM.dd}\""
        expect(values_yaml_content).to include "setup.template.name: 'filebeat'"
        expect(values_yaml_content).to include "setup.template.pattern: 'filebeat-*'"
      end
    end

    context 'on a non rbac enabled cluster' do
      before do
        elastic_stack.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'on versions older than 2' do
      before do
        elastic_stack.status = elastic_stack.status_states[:updating]
        elastic_stack.version = "1.9.0"
      end

      it 'includes a preinstall script' do
        expect(subject.preinstall).not_to be_empty
        expect(subject.preinstall.first).to include("helm uninstall")
      end
    end

    context 'on versions older than 3' do
      before do
        elastic_stack.status = elastic_stack.status_states[:updating]
        elastic_stack.version = "2.9.0"
      end

      it 'includes a preinstall script' do
        expect(subject.preinstall).not_to be_empty
        expect(subject.preinstall.first).to include("helm uninstall")
      end
    end

    context 'application failed to install previously' do
      let(:elastic_stack) { create(:clusters_applications_elastic_stack, :errored, version: '0.0.1') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('3.0.0')
      end
    end
  end

  describe '#chart_above_v2?' do
    let(:elastic_stack) { create(:clusters_applications_elastic_stack, version: version) }

    subject { elastic_stack.chart_above_v2? }

    context 'on v1.9.0' do
      let(:version) { '1.9.0' }

      it { is_expected.to be_falsy }
    end

    context 'on v2.0.0' do
      let(:version) { '2.0.0' }

      it { is_expected.to be_truthy }
    end
  end

  describe '#chart_above_v3?' do
    let(:elastic_stack) { create(:clusters_applications_elastic_stack, version: version) }

    subject { elastic_stack.chart_above_v3? }

    context 'on v1.9.0' do
      let(:version) { '1.9.0' }

      it { is_expected.to be_falsy }
    end

    context 'on v3.0.0' do
      let(:version) { '3.0.0' }

      it { is_expected.to be_truthy }
    end
  end

  describe '#uninstall_command' do
    let!(:elastic_stack) { create(:clusters_applications_elastic_stack) }

    subject { elastic_stack.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::V3::DeleteCommand) }

    it 'is initialized with elastic stack arguments' do
      expect(subject.name).to eq('elastic-stack')
      expect(subject).to be_rbac
      expect(subject.files).to eq(elastic_stack.files)
    end

    it 'specifies a post delete command to remove custom resource definitions' do
      expect(subject.postdelete).to eq([
        'kubectl delete pvc --selector app\\=elastic-stack-elasticsearch-master --namespace gitlab-managed-apps'
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
