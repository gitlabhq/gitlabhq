# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Dashboard::Stages::GrafanaFormatter do
  include GrafanaApiHelpers

  let_it_be(:namespace) { create(:namespace, name: 'foo') }
  let_it_be(:project) { create(:project, namespace: namespace, name: 'bar') }

  describe '#transform!' do
    let(:grafana_dashboard) { JSON.parse(fixture_file('grafana/simplified_dashboard_response.json'), symbolize_names: true) }
    let(:datasource) { JSON.parse(fixture_file('grafana/datasource_response.json'), symbolize_names: true) }

    let(:dashboard) { described_class.new(project, {}, params).transform! }

    let(:params) do
      {
        grafana_dashboard: grafana_dashboard,
        datasource: datasource,
        grafana_url: valid_grafana_dashboard_link('https://grafana.example.com')
      }
    end

    context 'when the query and resources are configured correctly' do
      let(:expected_dashboard) { JSON.parse(fixture_file('grafana/expected_grafana_embed.json'), symbolize_names: true) }

      it 'generates a gitlab-yml formatted dashboard' do
        expect(dashboard).to eq(expected_dashboard)
      end
    end

    context 'when the inputs are invalid' do
      shared_examples_for 'processing error' do
        it 'raises a processing error' do
          expect { dashboard }
            .to raise_error(Gitlab::Metrics::Dashboard::Stages::InputFormatValidator::DashboardProcessingError)
        end
      end

      context 'when the datasource is not proxyable' do
        before do
          params[:datasource][:access] = 'not-proxy'
        end

        it_behaves_like 'processing error'
      end

      context 'when query param "panelId" is not specified' do
        before do
          params[:grafana_url].gsub!('panelId=8', '')
        end

        it_behaves_like 'processing error'
      end

      context 'when query param "from" is not specified' do
        before do
          params[:grafana_url].gsub!('from=1570397739557', '')
        end

        it_behaves_like 'processing error'
      end

      context 'when query param "to" is not specified' do
        before do
          params[:grafana_url].gsub!('to=1570484139557', '')
        end

        it_behaves_like 'processing error'
      end

      context 'when the panel is not a graph' do
        before do
          params[:grafana_dashboard][:dashboard][:panels][0][:type] = 'singlestat'
        end

        it_behaves_like 'processing error'
      end

      context 'when the panel is not a line graph' do
        before do
          params[:grafana_dashboard][:dashboard][:panels][0][:lines] = false
        end

        it_behaves_like 'processing error'
      end

      context 'when the query dashboard includes undefined variables' do
        before do
          params[:grafana_url].gsub!('&var-instance=localhost:9121', '')
        end

        it_behaves_like 'processing error'
      end

      context 'when the expression contains unsupported global variables' do
        before do
          params[:grafana_dashboard][:dashboard][:panels][0][:targets][0][:expr] = 'sum(important_metric[$__interval_ms])'
        end

        it_behaves_like 'processing error'
      end
    end
  end
end
