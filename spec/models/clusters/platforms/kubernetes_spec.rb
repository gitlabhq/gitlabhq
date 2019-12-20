# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Platforms::Kubernetes do
  include KubernetesHelpers

  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to be_kind_of(Gitlab::Kubernetes) }
  it { is_expected.to respond_to :ca_pem }

  it { is_expected.to validate_exclusion_of(:namespace).in_array(%w(gitlab-managed-apps)) }
  it { is_expected.to validate_presence_of(:api_url) }
  it { is_expected.to validate_presence_of(:token) }

  it { is_expected.to delegate_method(:enabled?).to(:cluster) }
  it { is_expected.to delegate_method(:provided_by_user?).to(:cluster) }

  it_behaves_like 'having unique enum values'

  describe 'before_validation' do
    let(:kubernetes) { create(:cluster_platform_kubernetes, :configured, namespace: namespace) }

    context 'when namespace includes upper case' do
      let(:namespace) { 'ABC' }

      it 'converts to lower case' do
        expect(kubernetes.namespace).to eq('abc')
      end
    end

    context 'when namespace is blank' do
      let(:namespace) { '' }

      it 'nullifies the namespace' do
        expect(kubernetes.namespace).to be_nil
      end
    end
  end

  describe 'validation' do
    subject { kubernetes.valid? }

    context 'when validates namespace' do
      let(:kubernetes) { build(:cluster_platform_kubernetes, :configured, namespace: namespace) }

      context 'when namespace is nil' do
        let(:namespace) { nil }

        it { is_expected.to be_truthy }
      end

      context 'when namespace is longer than 63' do
        let(:namespace) { 'a' * 64 }

        it { is_expected.to be_falsey }
      end

      context 'when namespace includes invalid character' do
        let(:namespace) { '!!!!!!' }

        it { is_expected.to be_falsey }
      end

      context 'when namespace is vaild' do
        let(:namespace) { 'namespace-123' }

        it { is_expected.to be_truthy }
      end

      context 'for group cluster' do
        let(:namespace) { 'namespace-123' }
        let(:cluster) { build(:cluster, :group, :provided_by_user) }
        let(:kubernetes) { cluster.platform_kubernetes }

        before do
          kubernetes.namespace = namespace
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when validates api_url' do
      let(:kubernetes) { build(:cluster_platform_kubernetes, :configured) }

      before do
        kubernetes.api_url = api_url
      end

      context 'when api_url is invalid url' do
        let(:api_url) { '!!!!!!' }

        it { expect(kubernetes.save).to be_falsey }
      end

      context 'when api_url is nil' do
        let(:api_url) { nil }

        it { expect(kubernetes.save).to be_falsey }
      end

      context 'when api_url is valid url' do
        let(:api_url) { 'https://111.111.111.111' }

        it { expect(kubernetes.save).to be_truthy }
      end

      context 'when api_url is localhost' do
        let(:api_url) { 'http://localhost:22' }

        it { expect(kubernetes.save).to be_falsey }

        context 'Application settings allows local requests' do
          before do
            allow(ApplicationSetting)
              .to receive(:current)
              .and_return(ApplicationSetting.build_from_defaults(allow_local_requests_from_web_hooks_and_services: true))
          end

          it { expect(kubernetes.save).to be_truthy }
        end
      end
    end

    context 'when validates token' do
      let(:kubernetes) { build(:cluster_platform_kubernetes, :configured) }

      before do
        kubernetes.token = token
      end

      context 'when token is nil' do
        let(:token) { nil }

        it { expect(kubernetes.save).to be_falsey }
      end
    end

    context 'ca_cert' do
      let(:kubernetes) { build(:cluster_platform_kubernetes, ca_pem: ca_pem) }

      context 'with a valid certificate' do
        let(:ca_pem) { File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')) }

        it { is_expected.to be_truthy }
      end

      context 'with an invalid certificate' do
        let(:ca_pem) { "invalid" }

        it { is_expected.to be_falsey }

        context 'but the certificate is not being updated' do
          before do
            allow(kubernetes).to receive(:ca_cert_changed?).and_return(false)
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'with no certificate' do
        let(:ca_pem) { "" }

        it { is_expected.to be_truthy }
      end
    end

    describe 'when using reserved namespaces' do
      subject { build(:cluster_platform_kubernetes, namespace: namespace) }

      context 'when no namespace is manually assigned' do
        let(:namespace) { nil }

        it { is_expected.to be_valid }
      end

      context 'when no reserved namespace is assigned' do
        let(:namespace) { 'my-namespace' }

        it { is_expected.to be_valid }
      end

      context 'when reserved namespace is assigned' do
        let(:namespace) { 'gitlab-managed-apps' }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe '#kubeclient' do
    let(:cluster) { create(:cluster, :project) }
    let(:kubernetes) { build(:cluster_platform_kubernetes, :configured, namespace: 'a-namespace', cluster: cluster) }

    subject { kubernetes.kubeclient }

    before do
      create(:cluster_kubernetes_namespace,
             cluster: kubernetes.cluster,
             cluster_project: kubernetes.cluster.cluster_project,
             project: kubernetes.cluster.cluster_project.project)
    end

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::KubeClient) }
  end

  describe '#rbac?' do
    let(:kubernetes) { build(:cluster_platform_kubernetes, :configured) }

    subject { kubernetes.rbac? }

    it { is_expected.to be_truthy }
  end

  describe '#predefined_variables' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, :group, platform_kubernetes: platform) }
    let(:platform) { create(:cluster_platform_kubernetes) }
    let(:persisted_namespace) { create(:cluster_kubernetes_namespace, project: project, cluster: cluster) }

    let(:environment_name) { 'env/production' }
    let(:environment_slug) { Gitlab::Slug::Environment.new(environment_name).generate }

    subject { platform.predefined_variables(project: project, environment_name: environment_name) }

    before do
      allow(Clusters::KubernetesNamespaceFinder).to receive(:new)
        .with(cluster, project: project, environment_name: environment_name)
        .and_return(double(execute: persisted_namespace))
    end

    it { is_expected.to include(key: 'KUBE_URL', value: platform.api_url, public: true) }

    context 'platform has a CA certificate' do
      let(:ca_pem) { File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')) }
      let(:platform) { create(:cluster_platform_kubernetes, ca_cert: ca_pem) }

      it { is_expected.to include(key: 'KUBE_CA_PEM', value: ca_pem, public: true) }
      it { is_expected.to include(key: 'KUBE_CA_PEM_FILE', value: ca_pem, public: true, file: true) }
    end

    context 'cluster is managed by project' do
      before do
        allow(Gitlab::Kubernetes::DefaultNamespace).to receive(:new)
          .with(cluster, project: project).and_return(double(from_environment_name: namespace))

        allow(platform).to receive(:kubeconfig).with(namespace).and_return('kubeconfig')
      end

      let(:cluster) { create(:cluster, :group, platform_kubernetes: platform, management_project: project) }
      let(:namespace) { 'kubernetes-namespace' }
      let(:kubeconfig) { 'kubeconfig' }

      it { is_expected.to include(key: 'KUBE_TOKEN', value: platform.token, public: false, masked: true) }
      it { is_expected.to include(key: 'KUBE_NAMESPACE', value: namespace) }
      it { is_expected.to include(key: 'KUBECONFIG', value: kubeconfig, public: false, file: true) }
    end

    context 'kubernetes namespace exists' do
      let(:variable) { Hash(key: :fake_key, value: 'fake_value') }
      let(:namespace_variables) { Gitlab::Ci::Variables::Collection.new([variable]) }

      before do
        expect(persisted_namespace).to receive(:predefined_variables).and_return(namespace_variables)
      end

      it { is_expected.to include(variable) }
    end

    context 'kubernetes namespace does not exist' do
      let(:persisted_namespace) { nil }
      let(:namespace) { 'kubernetes-namespace' }
      let(:kubeconfig) { 'kubeconfig' }

      before do
        allow(Gitlab::Kubernetes::DefaultNamespace).to receive(:new)
          .with(cluster, project: project).and_return(double(from_environment_name: namespace))
        allow(platform).to receive(:kubeconfig).with(namespace).and_return(kubeconfig)
      end

      it { is_expected.not_to include(key: 'KUBE_TOKEN', value: platform.token, public: false, masked: true) }
      it { is_expected.not_to include(key: 'KUBE_NAMESPACE', value: namespace) }
      it { is_expected.not_to include(key: 'KUBECONFIG', value: kubeconfig, public: false, file: true) }

      context 'cluster is unmanaged' do
        let(:cluster) { create(:cluster, :group, :not_managed, platform_kubernetes: platform) }

        it { is_expected.to include(key: 'KUBE_TOKEN', value: platform.token, public: false, masked: true) }
        it { is_expected.to include(key: 'KUBE_NAMESPACE', value: namespace) }
        it { is_expected.to include(key: 'KUBECONFIG', value: kubeconfig, public: false, file: true) }

        context 'custom namespace is provided' do
          let(:custom_namespace) { 'custom-namespace' }

          subject do
            platform.predefined_variables(
              project: project,
              environment_name: environment_name,
              kubernetes_namespace: custom_namespace
            )
          end

          before do
            allow(platform).to receive(:kubeconfig).with(custom_namespace).and_return(kubeconfig)
          end

          it { is_expected.to include(key: 'KUBE_TOKEN', value: platform.token, public: false, masked: true) }
          it { is_expected.to include(key: 'KUBE_NAMESPACE', value: custom_namespace) }
          it { is_expected.to include(key: 'KUBECONFIG', value: kubeconfig, public: false, file: true) }
        end
      end
    end

    context 'cluster variables' do
      let(:variable) { Hash(key: :fake_key, value: 'fake_value') }
      let(:cluster_variables) { Gitlab::Ci::Variables::Collection.new([variable]) }

      before do
        expect(cluster).to receive(:predefined_variables).and_return(cluster_variables)
      end

      it { is_expected.to include(variable) }
    end
  end

  describe '#terminals' do
    subject { service.terminals(environment, pods: pods) }

    let!(:cluster) { create(:cluster, :project, platform_kubernetes: service) }
    let(:project) { cluster.project }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:environment) { build(:environment, project: project, name: "env", slug: "env-000000") }
    let(:pods) { [{ "bad" => "pod" }] }

    context 'with invalid pods' do
      it 'returns no terminals' do
        is_expected.to be_empty
      end
    end

    context 'with valid pods' do
      let(:pod) { kube_pod(environment_slug: environment.slug, namespace: cluster.kubernetes_namespace_for(environment), project_slug: project.full_path_slug) }
      let(:pod_with_no_terminal) { kube_pod(environment_slug: environment.slug, project_slug: project.full_path_slug, status: "Pending") }
      let(:terminals) { kube_terminals(service, pod) }
      let(:pods) { [pod, pod, pod_with_no_terminal, kube_pod(environment_slug: "should-be-filtered-out")] }

      it 'returns terminals' do
        is_expected.to eq(terminals + terminals)
      end

      it 'uses max session time from settings' do
        stub_application_setting(terminal_max_session_time: 600)

        times = subject.map { |terminal| terminal[:max_session_time] }
        expect(times).to eq [600, 600, 600, 600]
      end
    end
  end

  describe '#calculate_reactive_cache_for' do
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:pod) { kube_pod }
    let(:namespace) { pod["metadata"]["namespace"] }
    let(:environment) { instance_double(Environment, deployment_namespace: namespace) }

    subject { service.calculate_reactive_cache_for(environment) }

    context 'when the kubernetes integration is disabled' do
      before do
        allow(service).to receive(:enabled?).and_return(false)
      end

      it { is_expected.to be_nil }
    end

    context 'when kubernetes responds with valid pods and deployments' do
      before do
        stub_kubeclient_pods(namespace)
        stub_kubeclient_deployments(namespace)
      end

      it { is_expected.to include(pods: [pod]) }
    end

    context 'when kubernetes responds with 500s' do
      before do
        stub_kubeclient_pods(namespace, status: 500)
        stub_kubeclient_deployments(namespace, status: 500)
      end

      it { expect { subject }.to raise_error(Kubeclient::HttpError) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_pods(namespace, status: 404)
        stub_kubeclient_deployments(namespace, status: 404)
      end

      it { is_expected.to include(pods: []) }
    end
  end
end
