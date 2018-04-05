require 'spec_helper'

describe PrometheusAdapter, :use_clean_rails_memory_store_caching do
  include PrometheusHelpers
  include ReactiveCachingHelpers

  class TestClass
    include PrometheusAdapter
  end

  let(:project) { create(:prometheus_project) }
  let(:service) { project.prometheus_service }

  let(:described_class) { TestClass }
  let(:environment_query) { Gitlab::Prometheus::Queries::EnvironmentQuery }

  describe '#query' do
    describe 'environment' do
      let(:environment) { build_stubbed(:environment, slug: 'env-slug') }

      around do |example|
        Timecop.freeze { example.run }
      end

      context 'with valid data' do
        subject { service.query(:environment, environment) }

        before do
          stub_reactive_cache(service, prometheus_data, environment_query, environment.id)
        end

        it 'returns reactive data' do
          is_expected.to eq(prometheus_metrics_data)
        end
      end
    end

    describe 'matched_metrics' do
      let(:matched_metrics_query) { Gitlab::Prometheus::Queries::MatchedMetricQuery }
      let(:prometheus_client_wrapper) { double(:prometheus_client_wrapper, label_values: nil) }

      context 'with valid data' do
        subject { service.query(:matched_metrics) }

        before do
          allow(service).to receive(:prometheus_client_wrapper).and_return(prometheus_client_wrapper)
          synchronous_reactive_cache(service)
        end

        it 'returns reactive data' do
          expect(subject[:success]).to be_truthy
          expect(subject[:data]).to eq([])
        end
      end
    end

    describe 'deployment' do
      let(:deployment) { build_stubbed(:deployment) }
      let(:deployment_query) { Gitlab::Prometheus::Queries::DeploymentQuery }

      around do |example|
        Timecop.freeze { example.run }
      end

      context 'with valid data' do
        subject { service.query(:deployment, deployment) }

        before do
          stub_reactive_cache(service, prometheus_data, deployment_query, deployment.id)
        end

        it 'returns reactive data' do
          expect(subject).to eq(prometheus_metrics_data)
        end
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
end
