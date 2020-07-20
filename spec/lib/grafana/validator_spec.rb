# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Grafana::Validator do
  let(:grafana_dashboard) { Gitlab::Json.parse(fixture_file('grafana/simplified_dashboard_response.json'), symbolize_names: true) }
  let(:datasource) { Gitlab::Json.parse(fixture_file('grafana/datasource_response.json'), symbolize_names: true) }
  let(:panel) { grafana_dashboard[:dashboard][:panels].first }

  let(:query_params) do
    {
      from: '1570397739557',
      to: '1570484139557',
      panelId: '8',
      'var-instance': 'localhost:9121'
    }
  end

  describe 'validate!' do
    shared_examples_for 'processing error' do |message|
      it 'raises a processing error' do
        expect { subject }
          .to raise_error(::Grafana::Validator::Error, message)
      end
    end

    subject { described_class.new(grafana_dashboard, datasource, panel, query_params).validate! }

    it 'does not raise an error' do
      expect { subject }.not_to raise_error
    end

    context 'when query param "from" is not specified' do
      before do
        query_params.delete(:from)
      end

      it_behaves_like 'processing error', 'Grafana query parameters must include from and to.'
    end

    context 'when query param "to" is not specified' do
      before do
        query_params.delete(:to)
      end

      it_behaves_like 'processing error', 'Grafana query parameters must include from and to.'
    end

    context 'when the panel is not provided' do
      let(:panel) { nil }

      it_behaves_like 'processing error', 'Panel type must be a line graph.'
    end

    context 'when the panel is not a graph' do
      before do
        panel[:type] = 'singlestat'
      end

      it_behaves_like 'processing error', 'Panel type must be a line graph.'
    end

    context 'when the panel is not a line graph' do
      before do
        panel[:lines] = false
      end

      it_behaves_like 'processing error', 'Panel type must be a line graph.'
    end

    context 'when the query dashboard includes undefined variables' do
      before do
        query_params.delete(:'var-instance')
      end

      it_behaves_like 'processing error', 'All Grafana variables must be defined in the query parameters.'
    end

    context 'when the expression contains unsupported global variables' do
      before do
        grafana_dashboard[:dashboard][:panels][0][:targets][0][:expr] = 'sum(important_metric[$__interval_ms])'
      end

      it_behaves_like 'processing error', "Prometheus must not include #{described_class::UNSUPPORTED_GRAFANA_GLOBAL_VARS}"
    end

    context 'when the datasource is not proxyable' do
      before do
        datasource[:access] = 'not-proxy'
      end

      it_behaves_like 'processing error', 'Only Prometheus datasources with proxy access in Grafana are supported.'
    end

    # Skipping datasource validation allows for checks to be
    # run without a secondary call to Grafana API
    context 'when the datasource is not provided' do
      let(:datasource) { nil }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe 'valid?' do
    subject { described_class.new(grafana_dashboard, datasource, panel, query_params).valid? }

    context 'with valid arguments' do
      it { is_expected.to be true }
    end

    context 'with invalid arguments' do
      let(:query_params) { {} }

      it { is_expected.to be false }
    end
  end
end
