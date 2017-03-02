require 'spec_helper'

describe KubernetesService, models: true, caching: true do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  let(:project) { create(:kubernetes_project) }
  let(:service) { project.kubernetes_service }

  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }
      it { is_expected.to validate_presence_of(:namespace) }
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
        }.each do |namespace, validity|
          it "should validate #{namespace} as #{validity ? 'valid' : 'invalid'}" do
            subject.namespace = namespace

            expect(subject.valid?).to eq(validity)
          end
        end
      end
    end

    context 'when service is inactive' do
      before { subject.active = false }
      it { is_expected.not_to validate_presence_of(:namespace) }
      it { is_expected.not_to validate_presence_of(:api_url) }
      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe '#initialize_properties' do
    context 'with a project' do
      it 'defaults to the project name' do
        expect(described_class.new(project: project).namespace).to eq(project.name)
      end
    end

    context 'without a project' do
      it 'leaves the namespace unset' do
        expect(described_class.new.namespace).to be_nil
      end
    end
  end

  describe '#test' do
    let(:discovery_url) { 'https://kubernetes.example.com/api/v1' }

    before do
      stub_kubeclient_discover
    end

    context 'with path prefix in api_url' do
      let(:discovery_url) { 'https://kubernetes.example.com/prefix/api/v1' }

      it 'tests with the prefix' do
        service.api_url = 'https://kubernetes.example.com/prefix'
        stub_kubeclient_discover

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
    before do
      subject.api_url = 'https://kube.domain.com'
      subject.token = 'token'
      subject.namespace = 'my-project'
      subject.ca_pem = 'CA PEM DATA'
    end

    it 'sets KUBE_URL' do
      expect(subject.predefined_variables).to include(
        { key: 'KUBE_URL', value: 'https://kube.domain.com', public: true }
      )
    end

    it 'sets KUBE_TOKEN' do
      expect(subject.predefined_variables).to include(
        { key: 'KUBE_TOKEN', value: 'token', public: false }
      )
    end

    it 'sets KUBE_NAMESPACE' do
      expect(subject.predefined_variables).to include(
        { key: 'KUBE_NAMESPACE', value: 'my-project', public: true }
      )
    end

    it 'sets KUBE_CA_PEM' do
      expect(subject.predefined_variables).to include(
        { key: 'KUBE_CA_PEM', value: 'CA PEM DATA', public: true }
      )
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

  describe '#rollout_status' do
    let(:environment) { build(:environment, project: project, name: "env", slug: "env-000000") }
    subject(:rollout_status) { service.rollout_status(environment) }

    context 'with valid deployments' do
      before do
        stub_reactive_cache(
          service,
          deployments: [kube_deployment(app: environment.slug), kube_deployment]
        )
      end

      it 'creates a matching RolloutStatus' do
        expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
        expect(rollout_status.deployments.map(&:labels)).to eq([{ 'app' => 'env-000000' }])
      end
    end
  end

  describe '#calculate_reactive_cache' do
    subject { service.calculate_reactive_cache }

    context 'when service is inactive' do
      before { service.active = false }

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

      it { expect { subject }.to raise_error(KubeException) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_pods(status: 404)
        stub_kubeclient_deployments(status: 404)
      end

      it { is_expected.to eq(pods: [], deployments: []) }
    end
  end
end
