require 'rails_helper'

describe Clusters::Applications::Prometheus do
  include KubernetesHelpers

  include_examples 'cluster application core specs', :clusters_applications_prometheus
  include_examples 'cluster application status specs', :clusters_applications_prometheus
  include_examples 'cluster application helm specs', :clusters_applications_prometheus

  describe '.installed' do
    subject { described_class.installed }

    let!(:cluster) { create(:clusters_applications_prometheus, :installed) }

    before do
      create(:clusters_applications_prometheus, :errored)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '#make_installing!' do
    before do
      application.make_installing!
    end

    context 'application install previously errored with older version' do
      let(:application) { create(:clusters_applications_prometheus, :scheduled, version: '6.7.2') }

      it 'updates the application version' do
        expect(application.reload.version).to eq('6.7.3')
      end
    end
  end

  describe 'transition to installed' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, :with_installed_helm, projects: [project]) }
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

  describe '#ready' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }

    it 'returns true when installed' do
      application = build(:clusters_applications_prometheus, :installed, cluster: cluster)

      expect(application).to be_ready
    end

    it 'returns false when not_installable' do
      application = build(:clusters_applications_prometheus, :not_installable, cluster: cluster)

      expect(application).not_to be_ready
    end

    it 'returns false when installable' do
      application = build(:clusters_applications_prometheus, :installable, cluster: cluster)

      expect(application).not_to be_ready
    end

    it 'returns false when scheduled' do
      application = build(:clusters_applications_prometheus, :scheduled, cluster: cluster)

      expect(application).not_to be_ready
    end

    it 'returns false when installing' do
      application = build(:clusters_applications_prometheus, :installing, cluster: cluster)

      expect(application).not_to be_ready
    end

    it 'returns false when errored' do
      application = build(:clusters_applications_prometheus, :errored, cluster: cluster)

      expect(application).not_to be_ready
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
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:kubernetes_url) { subject.cluster.platform_kubernetes.api_url }
      let(:kube_client) { subject.cluster.kubeclient.core_client }

      subject { create(:clusters_applications_prometheus, cluster: cluster) }

      before do
        subject.cluster.platform_kubernetes.namespace = 'a-namespace'
        stub_kubeclient_discover(cluster.platform_kubernetes.api_url)

        create(:cluster_kubernetes_namespace,
               cluster: cluster,
               cluster_project: cluster.cluster_project,
               project: cluster.cluster_project.project)
      end

      it 'creates proxy prometheus rest client' do
        expect(subject.prometheus_client).to be_instance_of(RestClient::Resource)
      end

      it 'creates proper url' do
        expect(subject.prometheus_client.url).to eq("#{kubernetes_url}/api/v1/namespaces/gitlab-managed-apps/services/prometheus-prometheus-server:80/proxy")
      end

      it 'copies options and headers from kube client to proxy client' do
        expect(subject.prometheus_client.options).to eq(kube_client.rest_client.options.merge(headers: kube_client.headers))
      end

      context 'when cluster is not reachable' do
        before do
          allow(kube_client).to receive(:proxy_url).and_raise(Kubeclient::HttpError.new(401, 'Unauthorized', nil))
        end

        it 'returns nil' do
          expect(subject.prometheus_client).to be_nil
        end
      end
    end
  end

  describe '#install_command' do
    let(:prometheus) { create(:clusters_applications_prometheus) }

    subject { prometheus.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with 3 arguments' do
      expect(subject.name).to eq('prometheus')
      expect(subject.chart).to eq('stable/prometheus')
      expect(subject.version).to eq('6.7.3')
      expect(subject).not_to be_rbac
      expect(subject.files).to eq(prometheus.files)
    end

    it 'should not install knative metrics' do
      expect(subject.postinstall).to be_nil
    end

    context 'on a rbac enabled cluster' do
      before do
        prometheus.cluster.platform_kubernetes.rbac!
      end

      it { is_expected.to be_rbac }
    end

    context 'application failed to install previously' do
      let(:prometheus) { create(:clusters_applications_prometheus, :errored, version: '2.0.0') }

      it 'should be initialized with the locked version' do
        expect(subject.version).to eq('6.7.3')
      end
    end

    context 'with knative installed' do
      let(:knative) { create(:clusters_applications_knative, :installed ) }
      let(:prometheus) { create(:clusters_applications_prometheus, cluster: knative.cluster) }

      subject { prometheus.install_command }

      it 'should install metrics' do
        expect(subject.postinstall).to include("kubectl apply -f #{Clusters::Applications::Knative::METRICS_CONFIG}")
      end
    end
  end

  describe '#files' do
    let(:application) { create(:clusters_applications_prometheus) }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'should include prometheus valid values' do
      expect(values).to include('alertmanager')
      expect(values).to include('kubeStateMetrics')
      expect(values).to include('nodeExporter')
      expect(values).to include('pushgateway')
      expect(values).to include('serverFiles')
    end
  end
end
