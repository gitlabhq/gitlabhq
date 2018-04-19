require 'spec_helper'

describe Clusters::Platforms::Kubernetes, :use_clean_rails_memory_store_caching do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to be_kind_of(Gitlab::Kubernetes) }
  it { is_expected.to be_kind_of(ReactiveCaching) }
  it { is_expected.to respond_to :ca_pem }

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
  end

  describe '#actual_namespace' do
    subject { kubernetes.actual_namespace }

    let!(:cluster) { create(:cluster, :project, platform_kubernetes: kubernetes) }
    let(:project) { cluster.project }
    let(:kubernetes) { create(:cluster_platform_kubernetes, :configured, namespace: namespace) }

    context 'when namespace is present' do
      let(:namespace) { 'namespace-123' }

      it { is_expected.to eq(namespace) }
    end

    context 'when namespace is not present' do
      let(:namespace) { nil }

      it { is_expected.to eq("#{project.path}-#{project.id}") }
    end
  end

  describe '#default_namespace' do
    subject { kubernetes.send(:default_namespace) }

    let(:kubernetes) { create(:cluster_platform_kubernetes, :configured) }

    context 'when cluster belongs to a project' do
      let!(:cluster) { create(:cluster, :project, platform_kubernetes: kubernetes) }
      let(:project) { cluster.project }

      it { is_expected.to eq("#{project.path}-#{project.id}") }
    end

    context 'when cluster belongs to nothing' do
      let!(:cluster) { create(:cluster, platform_kubernetes: kubernetes) }

      it { is_expected.to be_nil }
    end
  end

  describe '#predefined_variables' do
    let!(:cluster) { create(:cluster, :project, platform_kubernetes: kubernetes) }
    let(:kubernetes) { create(:cluster_platform_kubernetes, api_url: api_url, ca_cert: ca_pem, token: token) }
    let(:api_url) { 'https://kube.domain.com' }
    let(:ca_pem) { 'CA PEM DATA' }
    let(:token) { 'token' }

    let(:kubeconfig) do
      config_file = expand_fixture_path('config/kubeconfig.yml')
      config = YAML.load(File.read(config_file))
      config.dig('users', 0, 'user')['token'] = token
      config.dig('contexts', 0, 'context')['namespace'] = namespace
      config.dig('clusters', 0, 'cluster')['certificate-authority-data'] =
        Base64.strict_encode64(ca_pem)

      YAML.dump(config)
    end

    shared_examples 'setting variables' do
      it 'sets the variables' do
        expect(kubernetes.predefined_variables).to include(
          { key: 'KUBE_URL', value: api_url, public: true },
          { key: 'KUBE_TOKEN', value: token, public: false },
          { key: 'KUBE_NAMESPACE', value: namespace, public: true },
          { key: 'KUBECONFIG', value: kubeconfig, public: false, file: true },
          { key: 'KUBE_CA_PEM', value: ca_pem, public: true },
          { key: 'KUBE_CA_PEM_FILE', value: ca_pem, public: true, file: true }
        )
      end
    end

    context 'namespace is provided' do
      let(:namespace) { 'my-project' }

      before do
        kubernetes.namespace = namespace
      end

      it_behaves_like 'setting variables'
    end

    context 'no namespace provided' do
      let(:namespace) { kubernetes.actual_namespace }

      it_behaves_like 'setting variables'

      it 'sets the KUBE_NAMESPACE' do
        kube_namespace = kubernetes.predefined_variables.find { |h| h[:key] == 'KUBE_NAMESPACE' }

        expect(kube_namespace).not_to be_nil
        expect(kube_namespace[:value]).to match(/\A#{Gitlab::PathRegex::PATH_REGEX_STR}-\d+\z/)
      end
    end
  end

  describe '#terminals' do
    subject { service.terminals(environment) }

    let!(:cluster) { create(:cluster, :project, platform_kubernetes: service) }
    let(:project) { cluster.project }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:environment) { build(:environment, project: project, name: "env", slug: "env-000000") }

    context 'with invalid pods' do
      it 'returns no terminals' do
        stub_reactive_cache(service, pods: [{ "bad" => "pod" }])

        is_expected.to be_empty
      end
    end

    context 'with valid pods' do
      let(:pod) { kube_pod(app: environment.slug) }
      let(:terminals) { kube_terminals(service, pod) }

      before do
        stub_reactive_cache(
          service,
          pods: [pod, pod, kube_pod(app: "should-be-filtered-out")]
        )
      end

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

  describe '#calculate_reactive_cache' do
    subject { service.calculate_reactive_cache }

    let!(:cluster) { create(:cluster, :project, enabled: enabled, platform_kubernetes: service) }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:enabled) { true }

    context 'when cluster is disabled' do
      let(:enabled) { false }

      it { is_expected.to be_nil }
    end

    context 'when kubernetes responds with valid pods' do
      before do
        stub_kubeclient_pods
      end

      it { is_expected.to eq(pods: [kube_pod]) }
    end

    context 'when kubernetes responds with 500s' do
      before do
        stub_kubeclient_pods(status: 500)
      end

      it { expect { subject }.to raise_error(Kubeclient::HttpError) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_pods(status: 404)
      end

      it { is_expected.to eq(pods: []) }
    end
  end
end
