# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Stages::GrafanaFormatter do
  include GrafanaApiHelpers

  let_it_be(:namespace) { create(:namespace, path: 'foo') }
  let_it_be(:project) { create(:project, namespace: namespace, path: 'bar') }

  describe '#transform!' do
    let(:grafana_dashboard) { Gitlab::Json.parse(fixture_file('grafana/simplified_dashboard_response.json'), symbolize_names: true) }
    let(:datasource) { Gitlab::Json.parse(fixture_file('grafana/datasource_response.json'), symbolize_names: true) }
    let(:expected_dashboard) { Gitlab::Json.parse(fixture_file('grafana/expected_grafana_embed.json'), symbolize_names: true) }

    subject(:dashboard) { described_class.new(project, {}, params).transform! }

    let(:params) do
      {
        grafana_dashboard: grafana_dashboard,
        datasource: datasource,
        grafana_url: valid_grafana_dashboard_link('https://grafana.example.com')
      }
    end

    context 'when the query and resources are configured correctly' do
      it { is_expected.to eq expected_dashboard }
    end

    context 'when a panelId is not included in the grafana_url' do
      before do
        params[:grafana_url].gsub('&panelId=8', '')
      end

      it { is_expected.to eq expected_dashboard }

      context 'when there is also no valid panel in the dashboard' do
        before do
          params[:grafana_dashboard][:dashboard][:panels] = []
        end

        it 'raises a processing error' do
          expect { dashboard }.to raise_error(::Gitlab::Metrics::Dashboard::Errors::DashboardProcessingError)
        end
      end
    end

    context 'when an input is invalid' do
      before do
        params[:datasource][:access] = 'not-proxy'
      end

      it 'raises a processing error' do
        expect { dashboard }.to raise_error(::Gitlab::Metrics::Dashboard::Errors::DashboardProcessingError)
      end
    end
  end
end
