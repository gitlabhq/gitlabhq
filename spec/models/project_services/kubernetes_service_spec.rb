require 'spec_helper'

describe KubernetesService, :use_clean_rails_memory_store_caching do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  let(:project) { create(:kubernetes_project) }
  let(:service) { project.deployment_platform }

  describe 'Associations' do
    it { is_expected.to belong_to :project }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.not_to validate_presence_of(:namespace) }
      it { is_expected.to validate_presence_of(:api_url) }
      it { is_expected.to validate_presence_of(:token) }

      context 'namespace format' do
        before do
          subject.project = project
          subject.api_url = "http://example.com"
          subject.token = "test"
        end

        {
          'foo'  => true,
          '1foo' => true,
          'foo1' => true,
          'foo-bar' => true,
          '-foo' => false,
          'foo-' => false,
          'a' * 63 => true,
          'a' * 64 => false,
          'a.b' => false,
          'a*b' => false,
          'FOO' => true
        }.each do |namespace, validity|
          it "validates #{namespace} as #{validity ? 'valid' : 'invalid'}" do
            subject.namespace = namespace

            expect(subject.valid?).to eq(validity)
          end
        end
      end
    end

    context 'when service is inactive' do
      before do
        subject.project = project
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:api_url) }
      it { is_expected.not_to validate_presence_of(:token) }
    end

    context 'with a deprecated service' do
      let(:kubernetes_service) { create(:kubernetes_service) }

      before do
        kubernetes_service.update_attribute(:active, false)
        kubernetes_service.properties[:namespace] = "foo"
      end

      it 'should not update attributes' do
        expect(kubernetes_service.save).to be_falsy
      end

      it 'should include an error with a deprecation message' do
        kubernetes_service.valid?
        expect(kubernetes_service.errors[:base].first).to match(/Kubernetes service integration has been deprecated/)
      end
    end

    context 'with a non-deprecated service' do
      let(:kubernetes_service) { create(:kubernetes_service) }

      it 'should update attributes' do
        kubernetes_service.properties[:namespace] = 'foo'
        expect(kubernetes_service.save).to be_truthy
      end
    end

    context 'with an active and deprecated service' do
      let(:kubernetes_service) { create(:kubernetes_service) }

      before do
        kubernetes_service.active = false
        kubernetes_service.properties[:namespace] = 'foo'
        kubernetes_service.save
      end

      it 'should deactive the service' do
        expect(kubernetes_service.active?).to be_falsy
      end

      it 'should not include a deprecation message as error' do
        expect(kubernetes_service.errors.messages.count).to eq(0)
      end

      it 'should update attributes' do
        expect(kubernetes_service.properties[:namespace]).to eq("foo")
      end
    end

    context 'with a template service' do
      let(:kubernetes_service) { create(:kubernetes_service, template: true, active: false) }

      before do
        kubernetes_service.properties[:namespace] = 'foo'
      end

      it 'should update attributes' do
        expect(kubernetes_service.save).to be_truthy
        expect(kubernetes_service.properties[:namespace]).to eq('foo')
      end
    end
  end

  describe '#initialize_properties' do
    context 'without a project' do
      it 'leaves the namespace unset' do
        expect(described_class.new.namespace).to be_nil
      end
    end
  end

  describe '#fields' do
    let(:kube_namespace) do
      subject.fields.find { |h| h[:name] == 'namespace' }
    end

    context 'as template' do
      before do
        subject.template = true
      end

      it 'sets the namespace to the default' do
        expect(kube_namespace).not_to be_nil
        expect(kube_namespace[:placeholder]).to eq(subject.class::TEMPLATE_PLACEHOLDER)
      end
    end

    context 'with associated project' do
      before do
        subject.project = project
      end

      it 'sets the namespace to the default' do
        expect(kube_namespace).not_to be_nil
        expect(kube_namespace[:placeholder]).to match(/\A#{Gitlab::PathRegex::PATH_REGEX_STR}-\d+\z/)
      end
    end
  end

  describe '#actual_namespace' do
    subject { service.actual_namespace }

    shared_examples 'a correctly formatted namespace' do
      it 'returns a valid Kubernetes namespace name' do
        expect(subject).to match(Gitlab::Regex.kubernetes_namespace_regex)
        expect(subject).to eq(expected_namespace)
      end
    end

    it_behaves_like 'a correctly formatted namespace' do
      let(:expected_namespace) { service.send(:default_namespace) }
    end

    context 'when the project path contains forbidden characters' do
      before do
        project.path = '-a_Strange.Path--forSure'
      end

      it_behaves_like 'a correctly formatted namespace' do
        let(:expected_namespace) { "a-strange-path--forsure-#{project.id}" }
      end
    end

    context 'when namespace is specified' do
      before do
        service.namespace = 'my-namespace'
      end

      it_behaves_like 'a correctly formatted namespace' do
        let(:expected_namespace) { 'my-namespace' }
      end
    end

    context 'when service is not assigned to project' do
      before do
        service.project = nil
      end

      it 'does not return namespace' do
        is_expected.to be_nil
      end
    end
  end

  describe '#test' do
    let(:discovery_url) { 'https://kubernetes.example.com/api/v1' }

    before do
      stub_kubeclient_discover(service.api_url)
    end

    context 'with path prefix in api_url' do
      let(:discovery_url) { 'https://kubernetes.example.com/prefix/api/v1' }

      it 'tests with the prefix' do
        service.api_url = 'https://kubernetes.example.com/prefix'
        stub_kubeclient_discover(service.api_url)

        expect(service.test[:success]).to be_truthy
        expect(WebMock).to have_requested(:get, discovery_url).once
      end
    end

    context 'with custom CA certificate' do
      it 'is added to the certificate store' do
        service.ca_pem = "CA PEM DATA"

        cert = double("certificate")
        expect(OpenSSL::X509::Certificate).to receive(:new).with(service.ca_pem).and_return(cert)
        expect_any_instance_of(OpenSSL::X509::Store).to receive(:add_cert).with(cert)

        expect(service.test[:success]).to be_truthy
        expect(WebMock).to have_requested(:get, discovery_url).once
      end
    end

    context 'success' do
      it 'reads the discovery endpoint' do
        expect(service.test[:success]).to be_truthy
        expect(WebMock).to have_requested(:get, discovery_url).once
      end
    end

    context 'failure' do
      it 'fails to read the discovery endpoint' do
        WebMock.stub_request(:get, service.api_url + '/api/v1').to_return(status: 404)

        expect(service.test[:success]).to be_falsy
        expect(WebMock).to have_requested(:get, discovery_url).once
      end
    end
  end

  describe '#predefined_variables' do
    let(:kubeconfig) do
      config_file = expand_fixture_path('config/kubeconfig.yml')
      config = YAML.load(File.read(config_file))
      config.dig('users', 0, 'user')['token'] = 'token'
      config.dig('contexts', 0, 'context')['namespace'] = namespace
      config.dig('clusters', 0, 'cluster')['certificate-authority-data'] =
        Base64.strict_encode64('CA PEM DATA')

      YAML.dump(config)
    end

    before do
      subject.api_url = 'https://kube.domain.com'
      subject.token = 'token'
      subject.ca_pem = 'CA PEM DATA'
      subject.project = project
    end

    shared_examples 'setting variables' do
      it 'sets the variables' do
        expect(subject.predefined_variables).to include(
          { key: 'KUBE_URL', value: 'https://kube.domain.com', public: true },
          { key: 'KUBE_TOKEN', value: 'token', public: false },
          { key: 'KUBE_NAMESPACE', value: namespace, public: true },
          { key: 'KUBECONFIG', value: kubeconfig, public: false, file: true },
          { key: 'KUBE_CA_PEM', value: 'CA PEM DATA', public: true },
          { key: 'KUBE_CA_PEM_FILE', value: 'CA PEM DATA', public: true, file: true }
        )
      end
    end

    context 'namespace is provided' do
      let(:namespace) { 'my-project' }

      before do
        subject.namespace = namespace
      end

      it_behaves_like 'setting variables'
    end

    context 'no namespace provided' do
      let(:namespace) { subject.actual_namespace }

      it_behaves_like 'setting variables'

      it 'sets the KUBE_NAMESPACE' do
        kube_namespace = subject.predefined_variables.find { |h| h[:key] == 'KUBE_NAMESPACE' }

        expect(kube_namespace).not_to be_nil
        expect(kube_namespace[:value]).to match(/\A#{Gitlab::PathRegex::PATH_REGEX_STR}-\d+\z/)
      end
    end
  end

  describe '#terminals' do
    let(:environment) { build(:environment, project: project, name: "env", slug: "env-000000") }

    subject { service.terminals(environment) }

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

    context 'when service is inactive' do
      before do
        service.active = false
      end

      it { is_expected.to be_nil }
    end

    context 'when kubernetes responds with valid pods and deployments' do
      before do
        stub_kubeclient_pods
        stub_kubeclient_deployments
      end

      it { is_expected.to eq(pods: [kube_pod], deployments: [kube_deployment]) }
    end

    context 'when kubernetes responds with 500s' do
      before do
        stub_kubeclient_pods(status: 500)
        stub_kubeclient_deployments(status: 500)
      end

      it { expect { subject }.to raise_error(Kubeclient::HttpError) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_pods(status: 404)
        stub_kubeclient_deployments(status: 404)
      end

      it { is_expected.to eq(pods: [], deployments: []) }
    end
  end

  describe "#deprecated?" do
    let(:kubernetes_service) { create(:kubernetes_service) }

    context 'with an active kubernetes service' do
      it 'should return false' do
        expect(kubernetes_service.deprecated?).to be_falsy
      end
    end

    context 'with a inactive kubernetes service' do
      it 'should return true' do
        kubernetes_service.update_attribute(:active, false)
        expect(kubernetes_service.deprecated?).to be_truthy
      end
    end
  end

  describe "#deprecation_message" do
    let(:kubernetes_service) { create(:kubernetes_service) }

    it 'should indicate the service is deprecated' do
      expect(kubernetes_service.deprecation_message).to match(/Kubernetes service integration has been deprecated/)
    end

    context 'if the services is active' do
      it 'should return a message' do
        expect(kubernetes_service.deprecation_message).to match(/Your Kubernetes cluster information on this page is still editable/)
      end
    end

    context 'if the service is not active' do
      it 'should return a message' do
        kubernetes_service.update_attribute(:active, false)
        expect(kubernetes_service.deprecation_message).to match(/Fields on this page are now uneditable/)
      end
    end
  end

  describe "#deprecated?" do
    let(:kubernetes_service) { create(:kubernetes_service) }

    context 'with an active kubernetes service' do
      it 'should return false' do
        expect(kubernetes_service.deprecated?).to be_falsy
      end
    end

    context 'with a inactive kubernetes service' do
      it 'should return true' do
        kubernetes_service.update_attribute(:active, false)
        expect(kubernetes_service.deprecated?).to be_truthy
      end
    end
  end

  describe "#deprecation_message" do
    let(:kubernetes_service) { create(:kubernetes_service) }

    it 'should indicate the service is deprecated' do
      expect(kubernetes_service.deprecation_message).to match(/Kubernetes service integration has been deprecated/)
    end

    context 'if the services is active' do
      it 'should return a message' do
        expect(kubernetes_service.deprecation_message).to match(/Your Kubernetes cluster information on this page is still editable/)
      end
    end

    context 'if the service is not active' do
      it 'should return a message' do
        kubernetes_service.update_attribute(:active, false)
        expect(kubernetes_service.deprecation_message).to match(/Fields on this page are now uneditable/)
      end
    end
  end
end
