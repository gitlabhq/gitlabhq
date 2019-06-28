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
    context 'when namespace includes upper case' do
      let(:kubernetes) { create(:cluster_platform_kubernetes, :configured, namespace: namespace) }
      let(:namespace) { 'ABC' }

      it 'converts to lower case' do
        expect(kubernetes.namespace).to eq('abc')
      end
    end
  end

  describe 'validation' do
    subject { kubernetes.valid? }

    context 'when validates namespace' do
      let(:kubernetes) { build(:cluster_platform_kubernetes, :configured, namespace: namespace) }

      context 'when namespace is blank' do
        let(:namespace) { '' }

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
              .and_return(ApplicationSetting.build_from_defaults(allow_local_requests_from_hooks_and_services: true))
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

  describe '#kubernetes_namespace_for' do
    let(:cluster) { create(:cluster, :project) }
    let(:project) { cluster.project }

    let(:platform) do
      create(:cluster_platform_kubernetes,
             cluster: cluster,
             namespace: namespace)
    end

    subject { platform.kubernetes_namespace_for(project) }

    context 'with a namespace assigned' do
      let(:namespace) { 'namespace-123' }

      it { is_expected.to eq(namespace) }

      context 'kubernetes namespace is present but has no service account token' do
        let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster: cluster) }

        it { is_expected.to eq(namespace) }
      end
    end

    context 'with no namespace assigned' do
      let(:namespace) { nil }

      context 'when kubernetes namespace is present' do
        let(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, :with_token, cluster: cluster) }

        before do
          kubernetes_namespace
        end

        it { is_expected.to eq(kubernetes_namespace.namespace) }

        context 'kubernetes namespace has no service account token' do
          before do
            kubernetes_namespace.update!(namespace: 'old-namespace', service_account_token: nil)
          end

          it { is_expected.to eq("#{project.path}-#{project.id}") }
        end
      end

      context 'when kubernetes namespace is not present' do
        it { is_expected.to eq("#{project.path}-#{project.id}") }
      end
    end
  end

  describe '#predefined_variables' do
    let!(:cluster) { create(:cluster, :project, platform_kubernetes: kubernetes) }
    let(:kubernetes) { create(:cluster_platform_kubernetes, api_url: api_url, ca_cert: ca_pem) }
    let(:api_url) { 'https://kube.domain.com' }
    let(:ca_pem) { File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')) }

    subject { kubernetes.predefined_variables(project: cluster.project) }

    shared_examples 'setting variables' do
      it 'sets the variables' do
        expect(subject).to include(
          { key: 'KUBE_URL', value: api_url, public: true },
          { key: 'KUBE_CA_PEM', value: ca_pem, public: true },
          { key: 'KUBE_CA_PEM_FILE', value: ca_pem, public: true, file: true }
        )
      end
    end

    context 'kubernetes namespace is created with no service account token' do
      let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster: cluster) }

      it_behaves_like 'setting variables'

      it 'does not set KUBE_TOKEN' do
        expect(subject).not_to include(
          { key: 'KUBE_TOKEN', value: kubernetes.token, public: false, masked: true }
        )
      end
    end

    context 'kubernetes namespace is created with service account token' do
      let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, :with_token, cluster: cluster) }

      it_behaves_like 'setting variables'

      it 'sets KUBE_TOKEN' do
        expect(subject).to include(
          { key: 'KUBE_TOKEN', value: kubernetes_namespace.service_account_token, public: false, masked: true }
        )
      end

      context 'the cluster has been set to unmanaged after the namespace was created' do
        before do
          cluster.update!(managed: false)
        end

        it_behaves_like 'setting variables'

        it 'sets KUBE_TOKEN from the platform' do
          expect(subject).to include(
            { key: 'KUBE_TOKEN', value: kubernetes.token, public: false, masked: true }
          )
        end

        context 'the platform has a custom namespace set' do
          before do
            kubernetes.update!(namespace: 'custom-namespace')
          end

          it 'sets KUBE_NAMESPACE from the platform' do
            expect(subject).to include(
              { key: 'KUBE_NAMESPACE', value: kubernetes.namespace, public: true, masked: false }
            )
          end
        end

        context 'there is no namespace specified on the platform' do
          let(:project) { cluster.project }

          before do
            kubernetes.update!(namespace: nil)
          end

          it 'sets KUBE_NAMESPACE to a default for the project' do
            expect(subject).to include(
              { key: 'KUBE_NAMESPACE', value: "#{project.path}-#{project.id}", public: true, masked: false }
            )
          end
        end
      end
    end

    context 'group level cluster' do
      let!(:cluster) { create(:cluster, :group, platform_kubernetes: kubernetes) }

      let(:project) { create(:project, group: cluster.group) }

      subject { kubernetes.predefined_variables(project: project) }

      context 'no kubernetes namespace for the project' do
        it_behaves_like 'setting variables'

        it 'does not return KUBE_TOKEN' do
          expect(subject).not_to include(
            { key: 'KUBE_TOKEN', value: kubernetes.token, public: false }
          )
        end

        context 'the cluster is not managed' do
          let!(:cluster) { create(:cluster, :group, :not_managed, platform_kubernetes: kubernetes) }

          it_behaves_like 'setting variables'

          it 'sets KUBE_TOKEN' do
            expect(subject).to include(
              { key: 'KUBE_TOKEN', value: kubernetes.token, public: false, masked: true }
            )
          end
        end
      end

      context 'kubernetes namespace exists for the project' do
        let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, :with_token, cluster: cluster, project: project) }

        it_behaves_like 'setting variables'

        it 'sets KUBE_TOKEN' do
          expect(subject).to include(
            { key: 'KUBE_TOKEN', value: kubernetes_namespace.service_account_token, public: false, masked: true }
          )
        end
      end
    end

    context 'with a domain' do
      let!(:cluster) do
        create(:cluster, :provided_by_gcp, :with_domain,
               platform_kubernetes: kubernetes)
      end

      it 'sets KUBE_INGRESS_BASE_DOMAIN' do
        expect(subject).to include(
          { key: 'KUBE_INGRESS_BASE_DOMAIN', value: cluster.domain, public: true }
        )
      end
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
      let(:pod) { kube_pod(environment_slug: environment.slug, namespace: cluster.kubernetes_namespace_for(project), project_slug: project.full_path_slug) }
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
