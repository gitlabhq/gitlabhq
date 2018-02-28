require 'spec_helper'

describe PrometheusService, :use_clean_rails_memory_store_caching do
  include PrometheusHelpers
  include ReactiveCachingHelpers

  let(:project) { create(:prometheus_project) }
  let(:service) { project.prometheus_service }
  let(:environment_query) { Gitlab::Prometheus::Queries::EnvironmentQuery }

  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe 'Validations' do
    context 'when manual_configuration is enabled' do
      before do
        subject.manual_configuration = true
      end

      it { is_expected.to validate_presence_of(:api_url) }
    end

    context 'when manual configuration is disabled' do
      before do
        subject.manual_configuration = false
      end

      it { is_expected.not_to validate_presence_of(:api_url) }
    end
  end

  describe '#test' do
    before do
      service.manual_configuration = true
    end

    let!(:req_stub) { stub_prometheus_request(prometheus_query_url('1'), body: prometheus_value_body('vector')) }

    context 'success' do
      it 'reads the discovery endpoint' do
        expect(service.test[:result]).to eq('Checked API endpoint')
        expect(service.test[:success]).to be_truthy
        expect(req_stub).to have_been_requested.twice
      end
    end

    context 'failure' do
      let!(:req_stub) { stub_prometheus_request(prometheus_query_url('1'), status: 404) }

      it 'fails to read the discovery endpoint' do
        expect(service.test[:success]).to be_falsy
        expect(req_stub).to have_been_requested
      end
    end
  end

  describe '#environment_metrics' do
    let(:environment) { build_stubbed(:environment, slug: 'env-slug') }

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'with valid data' do
      subject { service.environment_metrics(environment) }

      before do
        stub_reactive_cache(service, prometheus_data, environment_query, environment.id)
      end

      it 'returns reactive data' do
        is_expected.to eq(prometheus_metrics_data)
      end
    end
  end

  describe '#matched_metrics' do
    let(:matched_metrics_query) { Gitlab::Prometheus::Queries::MatchedMetricsQuery }
    let(:client) { double(:client, label_values: nil) }

    context 'with valid data' do
      subject { service.matched_metrics }

      before do
        allow(service).to receive(:client).and_return(client)
        synchronous_reactive_cache(service)
      end

      it 'returns reactive data' do
        expect(subject[:success]).to be_truthy
        expect(subject[:data]).to eq([])
      end
    end
  end

  describe '#deployment_metrics' do
    let(:deployment) { build_stubbed(:deployment) }
    let(:deployment_query) { Gitlab::Prometheus::Queries::DeploymentQuery }

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'with valid data' do
      subject { service.deployment_metrics(deployment) }
      let(:fake_deployment_time) { 10 }

      before do
        stub_reactive_cache(service, prometheus_data, deployment_query, deployment.environment.id, deployment.id)
      end

      it 'returns reactive data' do
        expect(deployment).to receive(:created_at).and_return(fake_deployment_time)

        expect(subject).to eq(prometheus_metrics_data.merge(deployment_time: fake_deployment_time))
      end
    end
  end

  describe '#calculate_reactive_cache' do
    let(:environment) { create(:environment, slug: 'env-slug') }
    before do
      service.manual_configuration = true
      service.active = true
    end

    subject do
      service.calculate_reactive_cache(environment_query.name, environment.id)
    end

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'when service is inactive' do
      before do
        service.active = false
      end

      it { is_expected.to be_nil }
    end

    context 'when Prometheus responds with valid data' do
      before do
        stub_all_prometheus_requests(environment.slug)
      end

      it { expect(subject.to_json).to eq(prometheus_data.to_json) }
      it { expect(subject.to_json).to eq(prometheus_data.to_json) }
    end

    [404, 500].each do |status|
      context "when Prometheus responds with #{status}" do
        before do
          stub_all_prometheus_requests(environment.slug, status: status, body: "QUERY FAILED!")
        end

        it { is_expected.to eq(success: false, result: %(#{status} - "QUERY FAILED!")) }
      end
    end
  end

  describe '#client' do
    context 'manual configuration is enabled' do
      let(:api_url) { 'http://some_url' }
      before do
        subject.manual_configuration = true
        subject.api_url = api_url
      end

      it 'returns simple rest client from api_url' do
        expect(subject.client).to be_instance_of(Gitlab::PrometheusClient)
        expect(subject.client.rest_client.url).to eq(api_url)
      end
    end

    context 'manual configuration is disabled' do
      let!(:cluster_for_all) { create(:cluster, environment_scope: '*', projects: [project]) }
      let!(:cluster_for_dev) { create(:cluster, environment_scope: 'dev', projects: [project]) }

      let!(:prometheus_for_dev) { create(:clusters_applications_prometheus, :installed, cluster: cluster_for_dev) }
      let(:proxy_client) { double('proxy_client') }

      before do
        service.manual_configuration = false
      end

      context 'with cluster for all environments with prometheus installed' do
        let!(:prometheus_for_all) { create(:clusters_applications_prometheus, :installed, cluster: cluster_for_all) }

        context 'without environment supplied' do
          it 'returns client handling all environments' do
            expect(service).to receive(:client_from_cluster).with(cluster_for_all).and_return(proxy_client).twice

            expect(service.client).to be_instance_of(Gitlab::PrometheusClient)
            expect(service.client.rest_client).to eq(proxy_client)
          end
        end

        context 'with dev environment supplied' do
          let!(:environment) { create(:environment, project: project, name: 'dev') }

          it 'returns dev cluster client' do
            expect(service).to receive(:client_from_cluster).with(cluster_for_dev).and_return(proxy_client).twice

            expect(service.client(environment.id)).to be_instance_of(Gitlab::PrometheusClient)
            expect(service.client(environment.id).rest_client).to eq(proxy_client)
          end
        end

        context 'with prod environment supplied' do
          let!(:environment) { create(:environment, project: project, name: 'prod') }

          it 'returns dev cluster client' do
            expect(service).to receive(:client_from_cluster).with(cluster_for_all).and_return(proxy_client).twice

            expect(service.client(environment.id)).to be_instance_of(Gitlab::PrometheusClient)
            expect(service.client(environment.id).rest_client).to eq(proxy_client)
          end
        end
      end

      context 'with cluster for all environments without prometheus installed' do
        context 'without environment supplied' do
          it 'raises PrometheusClient::Error because cluster was not found' do
            expect { service.client }.to raise_error(Gitlab::PrometheusClient::Error, /couldn't find cluster with Prometheus installed/)
          end
        end

        context 'with dev environment supplied' do
          let!(:environment) { create(:environment, project: project, name: 'dev') }

          it 'returns dev cluster client' do
            expect(service).to receive(:client_from_cluster).with(cluster_for_dev).and_return(proxy_client).twice

            expect(service.client(environment.id)).to be_instance_of(Gitlab::PrometheusClient)
            expect(service.client(environment.id).rest_client).to eq(proxy_client)
          end
        end

        context 'with prod environment supplied' do
          let!(:environment) { create(:environment, project: project, name: 'prod') }

          it 'raises PrometheusClient::Error because cluster was not found' do
            expect { service.client }.to raise_error(Gitlab::PrometheusClient::Error, /couldn't find cluster with Prometheus installed/)
          end
        end
      end
    end
  end

  describe '#prometheus_installed?' do
    context 'clusters with installed prometheus' do
      let!(:cluster) { create(:cluster, projects: [project]) }
      let!(:prometheus) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

      it 'returns true' do
        expect(service.prometheus_installed?).to be(true)
      end
    end

    context 'clusters without prometheus installed' do
      let(:cluster) { create(:cluster, projects: [project]) }
      let!(:prometheus) { create(:clusters_applications_prometheus, cluster: cluster) }

      it 'returns false' do
        expect(service.prometheus_installed?).to be(false)
      end
    end

    context 'clusters without prometheus' do
      let(:cluster) { create(:cluster, projects: [project]) }

      it 'returns false' do
        expect(service.prometheus_installed?).to be(false)
      end
    end

    context 'no clusters' do
      it 'returns false' do
        expect(service.prometheus_installed?).to be(false)
      end
    end
  end

  describe '#synchronize_service_state! before_save callback' do
    context 'no clusters with prometheus are installed' do
      context 'when service is inactive' do
        before do
          service.active = false
        end

        it 'activates service when manual_configuration is enabled' do
          expect { service.update!(manual_configuration: true) }.to change { service.active }.from(false).to(true)
        end

        it 'keeps service inactive when manual_configuration is disabled' do
          expect { service.update!(manual_configuration: false) }.not_to change { service.active }.from(false)
        end
      end

      context 'when service is active' do
        before do
          service.active = true
        end

        it 'keeps the service active when manual_configuration is enabled' do
          expect { service.update!(manual_configuration: true) }.not_to change { service.active }.from(true)
        end

        it 'inactivates the service when manual_configuration is disabled' do
          expect { service.update!(manual_configuration: false) }.to change { service.active }.from(true).to(false)
        end
      end
    end

    context 'with prometheus installed in the cluster' do
      before do
        allow(service).to receive(:prometheus_installed?).and_return(true)
      end

      context 'when service is inactive' do
        before do
          service.active = false
        end

        it 'activates service when manual_configuration is enabled' do
          expect { service.update!(manual_configuration: true) }.to change { service.active }.from(false).to(true)
        end

        it 'activates service when manual_configuration is disabled' do
          expect { service.update!(manual_configuration: false) }.to change { service.active }.from(false).to(true)
        end
      end

      context 'when service is active' do
        before do
          service.active = true
        end

        it 'keeps service active when manual_configuration is enabled' do
          expect { service.update!(manual_configuration: true) }.not_to change { service.active }.from(true)
        end

        it 'keeps service active when manual_configuration is disabled' do
          expect { service.update!(manual_configuration: false) }.not_to change { service.active }.from(true)
        end
      end
    end
  end
end
