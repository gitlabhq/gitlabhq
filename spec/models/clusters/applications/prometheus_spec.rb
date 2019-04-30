# frozen_string_literal: true

require 'rails_helper'

describe Clusters::Applications::Prometheus do
  include KubernetesHelpers

  include_examples 'cluster application core specs', :clusters_applications_prometheus
  include_examples 'cluster application status specs', :clusters_applications_prometheus
  include_examples 'cluster application version specs', :clusters_applications_prometheus
  include_examples 'cluster application helm specs', :clusters_applications_prometheus
  include_examples 'cluster application initial status specs'

  describe 'after_destroy' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, :with_installed_helm, projects: [project]) }
    let!(:application) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }
    let!(:prometheus_service) { project.create_prometheus_service(active: true) }

    it 'deactivates prometheus_service after destroy' do
      expect do
        application.destroy!

        prometheus_service.reload
      end.to change(prometheus_service, :active).from(true).to(false)
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
      expect(prometheus_service).to receive(:update!).with(active: true)

      subject.make_installed
    end
  end

  describe '#can_uninstall?' do
    let(:prometheus) { create(:clusters_applications_prometheus) }

    subject { prometheus.can_uninstall? }

    it { is_expected.to be_truthy }
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

    it 'is initialized with 3 arguments' do
      expect(subject.name).to eq('prometheus')
      expect(subject.chart).to eq('stable/prometheus')
      expect(subject.version).to eq('6.7.3')
      expect(subject).to be_rbac
      expect(subject.files).to eq(prometheus.files)
    end

    context 'on a non rbac enabled cluster' do
      before do
        prometheus.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'application failed to install previously' do
      let(:prometheus) { create(:clusters_applications_prometheus, :errored, version: '2.0.0') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('6.7.3')
      end
    end

    it 'does not install knative metrics' do
      expect(subject.postinstall).to be_nil
    end

    context 'with knative installed' do
      let(:knative) { create(:clusters_applications_knative, :updated ) }
      let(:prometheus) { create(:clusters_applications_prometheus, cluster: knative.cluster) }

      subject { prometheus.install_command }

      it 'installs knative metrics' do
        expect(subject.postinstall).to include("kubectl apply -f #{Clusters::Applications::Knative::METRICS_CONFIG}")
      end
    end
  end

  describe '#uninstall_command' do
    let(:prometheus) { create(:clusters_applications_prometheus) }

    subject { prometheus.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::DeleteCommand) }

    it 'has the application name' do
      expect(subject.name).to eq('prometheus')
    end

    it 'has files' do
      expect(subject.files).to eq(prometheus.files)
    end

    it 'is rbac' do
      expect(subject).to be_rbac
    end

    context 'on a non rbac enabled cluster' do
      before do
        prometheus.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end
  end

  describe '#upgrade_command' do
    let(:prometheus) { build(:clusters_applications_prometheus) }
    let(:values) { prometheus.values }

    it 'returns an instance of Gitlab::Kubernetes::Helm::InstallCommand' do
      expect(prometheus.upgrade_command(values)).to be_an_instance_of(::Gitlab::Kubernetes::Helm::InstallCommand)
    end

    it 'is initialized with 3 arguments' do
      command = prometheus.upgrade_command(values)

      expect(command.name).to eq('prometheus')
      expect(command.chart).to eq('stable/prometheus')
      expect(command.version).to eq('6.7.3')
      expect(command.files).to eq(prometheus.files)
    end
  end

  describe '#update_in_progress?' do
    context 'when app is updating' do
      it 'returns true' do
        cluster = create(:cluster)
        prometheus_app = build(:clusters_applications_prometheus, :updating, cluster: cluster)

        expect(prometheus_app.update_in_progress?).to be true
      end
    end
  end

  describe '#update_errored?' do
    context 'when app errored' do
      it 'returns true' do
        cluster = create(:cluster)
        prometheus_app = build(:clusters_applications_prometheus, :update_errored, cluster: cluster)

        expect(prometheus_app.update_errored?).to be true
      end
    end
  end

  describe '#files' do
    let(:application) { create(:clusters_applications_prometheus) }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'includes prometheus valid values' do
      expect(values).to include('alertmanager')
      expect(values).to include('kubeStateMetrics')
      expect(values).to include('nodeExporter')
      expect(values).to include('pushgateway')
      expect(values).to include('serverFiles')
    end
  end

  describe '#files_with_replaced_values' do
    let(:application) { build(:clusters_applications_prometheus) }
    let(:files) { application.files }

    subject { application.files_with_replaced_values({ hello: :world }) }

    it 'does not modify #files' do
      expect(subject[:'values.yaml']).not_to eq(files)
      expect(files[:'values.yaml']).to eq(application.values)
    end

    it 'returns values.yaml with replaced values' do
      expect(subject[:'values.yaml']).to eq({ hello: :world })
    end

    it 'includes cert files' do
      expect(subject[:'ca.pem']).to be_present
      expect(subject[:'ca.pem']).to eq(application.cluster.application_helm.ca_cert)

      expect(subject[:'cert.pem']).to be_present
      expect(subject[:'key.pem']).to be_present

      cert = OpenSSL::X509::Certificate.new(subject[:'cert.pem'])
      expect(cert.not_after).to be < 60.minutes.from_now
    end

    context 'when the helm application does not have a ca_cert' do
      before do
        application.cluster.application_helm.ca_cert = nil
      end

      it 'does not include cert files' do
        expect(subject[:'ca.pem']).not_to be_present
        expect(subject[:'cert.pem']).not_to be_present
        expect(subject[:'key.pem']).not_to be_present
      end
    end
  end
end
