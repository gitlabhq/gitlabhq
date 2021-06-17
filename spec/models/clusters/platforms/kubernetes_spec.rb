# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Platforms::Kubernetes do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to be_kind_of(Gitlab::Kubernetes) }
  it { is_expected.to respond_to :ca_pem }

  it { is_expected.to validate_exclusion_of(:namespace).in_array(%w(gitlab-managed-apps)) }
  it { is_expected.to validate_presence_of(:api_url) }
  it { is_expected.to validate_presence_of(:token) }

  it { is_expected.to delegate_method(:enabled?).to(:cluster) }
  it { is_expected.to delegate_method(:provided_by_user?).to(:cluster) }

  it { is_expected.to nullify_if_blank(:namespace) }

  it_behaves_like 'having unique enum values'

  describe 'before_validation' do
    let(:kubernetes) { create(:cluster_platform_kubernetes, :configured, namespace: namespace) }

    context 'when namespace includes upper case' do
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

    context 'ca_pem is a single certificate' do
      let(:ca_pem) { File.read(Rails.root.join('spec/fixtures/clusters/ca_certificate.pem')) }
      let(:kubernetes) do
        build(:cluster_platform_kubernetes,
              :configured,
              namespace: 'a-namespace',
              cluster: cluster,
              ca_pem: ca_pem)
      end

      it 'adds it to cert_store' do
        cert = OpenSSL::X509::Certificate.new(ca_pem)
        cert_store = kubernetes.kubeclient.kubeclient_options[:ssl_options][:cert_store]

        expect(cert_store.verify(cert)).to be true
      end
    end

    context 'ca_pem is a chain' do
      let(:cert_chain) { File.read(Rails.root.join('spec/fixtures/clusters/chain_certificates.pem')) }
      let(:kubernetes) do
        build(:cluster_platform_kubernetes,
              :configured,
              namespace: 'a-namespace',
              cluster: cluster,
              ca_pem: cert_chain)
      end

      it 'includes chain of certificates' do
        cert1_file = File.read(Rails.root.join('spec/fixtures/clusters/root_certificate.pem'))
        cert1 = OpenSSL::X509::Certificate.new(cert1_file)

        cert2_file = File.read(Rails.root.join('spec/fixtures/clusters/intermediate_certificate.pem'))
        cert2 = OpenSSL::X509::Certificate.new(cert2_file)

        cert3_file = File.read(Rails.root.join('spec/fixtures/clusters/ca_certificate.pem'))
        cert3 = OpenSSL::X509::Certificate.new(cert3_file)

        cert_store = kubernetes.kubeclient.kubeclient_options[:ssl_options][:cert_store]

        expect(cert_store.verify(cert1)).to be true
        expect(cert_store.verify(cert2)).to be true
        expect(cert_store.verify(cert3)).to be true
      end
    end
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
    let(:cluster) { create(:cluster, :project, platform_kubernetes: service) }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:namespace) { 'project-namespace' }
    let(:environment) { instance_double(Environment, deployment_namespace: namespace, project: cluster.project) }
    let(:expected_pod_cached_data) do
      kube_pod.tap { |kp| kp['metadata'].delete('namespace') }
    end

    subject { service.calculate_reactive_cache_for(environment) }

    context 'when kubernetes responds with valid deployments' do
      before do
        stub_kubeclient_pods(namespace)
        stub_kubeclient_deployments(namespace)
        stub_kubeclient_ingresses(namespace)
      end

      shared_examples 'successful deployment request' do
        it { is_expected.to include(pods: [expected_pod_cached_data], deployments: [kube_deployment], ingresses: [kube_ingress]) }
      end

      context 'on a project level cluster' do
        let(:cluster) { create(:cluster, :project, platform_kubernetes: service) }

        include_examples 'successful deployment request'
      end

      context 'on a group level cluster' do
        let(:cluster) { create(:cluster, :group, platform_kubernetes: service) }

        include_examples 'successful deployment request'
      end

      context 'on an instance level cluster' do
        let(:cluster) { create(:cluster, :instance, platform_kubernetes: service) }

        include_examples 'successful deployment request'
      end
    end

    context 'when the kubernetes integration is disabled' do
      before do
        allow(service).to receive(:enabled?).and_return(false)
      end

      it { is_expected.to be_nil }
    end

    context 'when kubernetes responds with 500s' do
      before do
        stub_kubeclient_pods(namespace, status: 500)
        stub_kubeclient_deployments(namespace, status: 500)
        stub_kubeclient_ingresses(namespace, status: 500)
      end

      it { expect { subject }.to raise_error(Kubeclient::HttpError) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_pods(namespace, status: 404)
        stub_kubeclient_deployments(namespace, status: 404)
        stub_kubeclient_ingresses(namespace, status: 404)
      end

      it { is_expected.to eq(pods: [], deployments: [], ingresses: []) }
    end
  end

  describe '#rollout_status' do
    let(:deployments) { [] }
    let(:pods) { [] }
    let(:ingresses) { [] }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let!(:cluster) { create(:cluster, :project, enabled: true, platform_kubernetes: service) }
    let(:project) { cluster.project }
    let(:environment) { build(:environment, project: project, name: "env", slug: "env-000000") }
    let(:cache_data) { Hash(deployments: deployments, pods: pods, ingresses: ingresses) }

    subject(:rollout_status) { service.rollout_status(environment, cache_data) }

    context 'legacy deployments based on app label' do
      let(:legacy_deployment) do
        kube_deployment(name: 'legacy-deployment').tap do |deployment|
          deployment['metadata']['annotations'].delete('app.gitlab.com/env')
          deployment['metadata']['annotations'].delete('app.gitlab.com/app')
          deployment['metadata']['labels']['app'] = environment.slug
        end
      end

      let(:legacy_pod) do
        kube_pod(name: 'legacy-pod').tap do |pod|
          pod['metadata']['annotations'].delete('app.gitlab.com/env')
          pod['metadata']['annotations'].delete('app.gitlab.com/app')
          pod['metadata']['labels']['app'] = environment.slug
        end
      end

      context 'only legacy deployments' do
        let(:deployments) { [legacy_deployment] }
        let(:pods) { [legacy_pod] }

        it 'contains nothing' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)

          expect(rollout_status.deployments).to eq([])
        end
      end

      context 'deployment with no pods' do
        let(:deployment) { kube_deployment(name: 'some-deployment', environment_slug: environment.slug, project_slug: project.full_path_slug) }
        let(:deployments) { [deployment] }
        let(:pods) { [] }

        it 'returns a valid status with matching deployments' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
          expect(rollout_status.deployments.map(&:name)).to contain_exactly('some-deployment')
        end
      end

      context 'new deployment based on annotations' do
        let(:matched_deployment) { kube_deployment(name: 'matched-deployment', environment_slug: environment.slug, project_slug: project.full_path_slug) }
        let(:matched_pod) { kube_pod(environment_slug: environment.slug, project_slug: project.full_path_slug) }
        let(:deployments) { [matched_deployment, legacy_deployment] }
        let(:pods) { [matched_pod, legacy_pod] }

        it 'contains only matching deployments' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)

          expect(rollout_status.deployments.map(&:name)).to contain_exactly('matched-deployment')
        end
      end
    end

    context 'with no deployments but there are pods' do
      let(:deployments) do
        []
      end

      let(:pods) do
        [
          kube_pod(name: 'pod-1', environment_slug: environment.slug, project_slug: project.full_path_slug),
          kube_pod(name: 'pod-2', environment_slug: environment.slug, project_slug: project.full_path_slug)
        ]
      end

      it 'returns an empty array' do
        expect(rollout_status.instances).to eq([])
      end
    end

    context 'with valid deployments' do
      let(:matched_deployment) { kube_deployment(environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 2) }
      let(:unmatched_deployment) { kube_deployment }
      let(:matched_pod) { kube_pod(environment_slug: environment.slug, project_slug: project.full_path_slug, status: 'Pending') }
      let(:unmatched_pod) { kube_pod(environment_slug: environment.slug + '-test', project_slug: project.full_path_slug) }
      let(:deployments) { [matched_deployment, unmatched_deployment] }
      let(:pods) { [matched_pod, unmatched_pod] }

      it 'creates a matching RolloutStatus' do
        expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
        expect(rollout_status.deployments.map(&:annotations)).to eq([
          { 'app.gitlab.com/app' => project.full_path_slug, 'app.gitlab.com/env' => 'env-000000' }
        ])
        expect(rollout_status.instances).to eq([{ pod_name: "kube-pod",
                                                 stable: true,
                                                 status: "pending",
                                                 tooltip: "kube-pod (Pending)",
                                                 track: "stable" },
                                                { pod_name: "Not provided",
                                                 stable: true,
                                                 status: "pending",
                                                 tooltip: "Not provided (Pending)",
                                                 track: "stable" }])
      end

      context 'with canary ingress' do
        let(:ingresses) { [kube_ingress(track: :canary)] }

        it 'has canary ingress' do
          expect(rollout_status).to be_canary_ingress_exists
          expect(rollout_status.canary_ingress.canary_weight).to eq(50)
        end
      end
    end

    context 'with empty list of deployments' do
      it 'creates a matching RolloutStatus' do
        expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
        expect(rollout_status).to be_not_found
      end
    end

    context 'when the pod track does not match the deployment track' do
      let(:deployments) do
        [
          kube_deployment(name: 'deployment-a', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 1, track: 'weekly')
        ]
      end

      let(:pods) do
        [
          kube_pod(name: 'pod-a-1', environment_slug: environment.slug, project_slug: project.full_path_slug, track: 'weekly'),
          kube_pod(name: 'pod-a-2', environment_slug: environment.slug, project_slug: project.full_path_slug, track: 'daily')
        ]
      end

      it 'does not return the pod' do
        expect(rollout_status.instances.map { |p| p[:pod_name] }).to eq(['pod-a-1'])
      end
    end

    context 'when the pod track is not stable' do
      let(:deployments) do
        [
          kube_deployment(name: 'deployment-a', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 1, track: 'something')
        ]
      end

      let(:pods) do
        [
          kube_pod(name: 'pod-a-1', environment_slug: environment.slug, project_slug: project.full_path_slug, track: 'something')
        ]
      end

      it 'the pod is not stable' do
        expect(rollout_status.instances.map { |p| p.slice(:stable, :track) }).to eq([{ stable: false, track: 'something' }])
      end
    end

    context 'when the pod track is stable' do
      let(:deployments) do
        [
          kube_deployment(name: 'deployment-a', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 1, track: 'stable')
        ]
      end

      let(:pods) do
        [
          kube_pod(name: 'pod-a-1', environment_slug: environment.slug, project_slug: project.full_path_slug, track: 'stable')
        ]
      end

      it 'the pod is stable' do
        expect(rollout_status.instances.map { |p| p.slice(:stable, :track) }).to eq([{ stable: true, track: 'stable' }])
      end
    end

    context 'when the pod track is not provided' do
      let(:deployments) do
        [
          kube_deployment(name: 'deployment-a', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 1)
        ]
      end

      let(:pods) do
        [
          kube_pod(name: 'pod-a-1', environment_slug: environment.slug, project_slug: project.full_path_slug)
        ]
      end

      it 'the pod is stable' do
        expect(rollout_status.instances.map { |p| p.slice(:stable, :track) }).to eq([{ stable: true, track: 'stable' }])
      end
    end

    context 'when the number of matching pods does not match the number of replicas' do
      let(:deployments) do
        [
          kube_deployment(name: 'deployment-a', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 3)
        ]
      end

      let(:pods) do
        [
          kube_pod(name: 'pod-a-1', environment_slug: environment.slug, project_slug: project.full_path_slug)
        ]
      end

      it 'returns a pending pod for each missing replica' do
        expect(rollout_status.instances.map { |p| p.slice(:pod_name, :status) }).to eq([
          { pod_name: 'pod-a-1', status: 'running' },
          { pod_name: 'Not provided', status: 'pending' },
          { pod_name: 'Not provided', status: 'pending' }
        ])
      end
    end

    context 'when pending pods are returned for missing replicas' do
      let(:deployments) do
        [
          kube_deployment(name: 'deployment-a', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 2, track: 'canary'),
          kube_deployment(name: 'deployment-b', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 2, track: 'stable')
        ]
      end

      let(:pods) do
        [
          kube_pod(name: 'pod-a-1', environment_slug: environment.slug, project_slug: project.full_path_slug, track: 'canary')
        ]
      end

      it 'returns the correct track for the pending pods' do
        expect(rollout_status.instances.map { |p| p.slice(:pod_name, :status, :track) }).to eq([
          { pod_name: 'pod-a-1', status: 'running', track: 'canary' },
          { pod_name: 'Not provided', status: 'pending', track: 'canary' },
          { pod_name: 'Not provided', status: 'pending', track: 'stable' },
          { pod_name: 'Not provided', status: 'pending', track: 'stable' }
        ])
      end
    end

    context 'when two deployments with the same track are missing instances' do
      let(:deployments) do
        [
          kube_deployment(name: 'deployment-a', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 1, track: 'mytrack'),
          kube_deployment(name: 'deployment-b', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 1, track: 'mytrack')
        ]
      end

      let(:pods) do
        []
      end

      it 'returns the correct number of pending pods' do
        expect(rollout_status.instances.map { |p| p.slice(:pod_name, :status, :track) }).to eq([
          { pod_name: 'Not provided', status: 'pending', track: 'mytrack' },
          { pod_name: 'Not provided', status: 'pending', track: 'mytrack' }
        ])
      end
    end

    context 'with multiple matching deployments' do
      let(:deployments) do
        [
          kube_deployment(name: 'deployment-a', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 2),
          kube_deployment(name: 'deployment-b', environment_slug: environment.slug, project_slug: project.full_path_slug, replicas: 2)
        ]
      end

      let(:pods) do
        [
          kube_pod(name: 'pod-a-1', environment_slug: environment.slug, project_slug: project.full_path_slug),
          kube_pod(name: 'pod-a-2', environment_slug: environment.slug, project_slug: project.full_path_slug),
          kube_pod(name: 'pod-b-1', environment_slug: environment.slug, project_slug: project.full_path_slug),
          kube_pod(name: 'pod-b-2', environment_slug: environment.slug, project_slug: project.full_path_slug)
        ]
      end

      it 'returns each pod once' do
        expect(rollout_status.instances.map { |p| p[:pod_name] }).to eq(['pod-a-1', 'pod-a-2', 'pod-b-1', 'pod-b-2'])
      end
    end
  end

  describe '#ingresses' do
    subject { service.ingresses(namespace) }

    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:namespace) { 'project-namespace' }

    context 'when there is an ingress in the namespace' do
      before do
        stub_kubeclient_ingresses(namespace)
      end

      it 'returns an ingress' do
        expect(subject.count).to eq(1)
        expect(subject.first).to be_kind_of(::Gitlab::Kubernetes::Ingress)
        expect(subject.first.name).to eq('production-auto-deploy')
      end
    end

    context 'when there are no ingresss in the namespace' do
      before do
        allow(service.kubeclient).to receive(:get_ingresses) { raise Kubeclient::ResourceNotFoundError.new(404, 'Not found', nil) }
      end

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end
  end

  describe '#patch_ingress' do
    subject { service.patch_ingress(namespace, ingress, data) }

    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:namespace) { 'project-namespace' }
    let(:ingress) { Gitlab::Kubernetes::Ingress.new(kube_ingress) }
    let(:data) { { metadata: { annotations: { name: 'test' } } } }

    context 'when there is an ingress in the namespace' do
      before do
        stub_kubeclient_ingresses(namespace, method: :patch, resource_path: "/#{ingress.name}")
      end

      it 'returns an ingress' do
        expect(subject[:items][0][:metadata][:name]).to eq('production-auto-deploy')
      end
    end

    context 'when there are no ingresss in the namespace' do
      before do
        allow(service.kubeclient).to receive(:patch_ingress) { raise Kubeclient::ResourceNotFoundError.new(404, 'Not found', nil) }
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Kubeclient::ResourceNotFoundError)
      end
    end
  end
end
