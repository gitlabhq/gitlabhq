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
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:api_url) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:api_url) }
    end
  end

  describe '#test' do
    let!(:req_stub) { stub_prometheus_request(prometheus_query_url('1'), body: prometheus_value_body('vector')) }

    context 'success' do
      it 'reads the discovery endpoint' do
        expect(service.test[:success]).to be_truthy
        expect(req_stub).to have_been_requested
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
        stub_reactive_cache(service, prometheus_data, deployment_query, deployment.id)
      end

      it 'returns reactive data' do
        expect(deployment).to receive(:created_at).and_return(fake_deployment_time)

        expect(subject).to eq(prometheus_metrics_data.merge(deployment_time: fake_deployment_time))
      end
    end
  end

  describe '#calculate_reactive_cache' do
    let(:environment) { create(:environment, slug: 'env-slug') }

    around do |example|
      Timecop.freeze { example.run }
    end

    subject do
      service.calculate_reactive_cache(environment_query.to_s, environment.id)
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
end
