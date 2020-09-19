# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineMetricsFilter do
  include FilterSpecHelper

  let(:environment_id) { 12 }
  let(:dashboard_url) { urls.metrics_dashboard_namespace_project_environment_url(*params, **query_params, embedded: true) }

  let(:query_params) do
    {
      dashboard: 'config/prometheus/common_metrics.yml',
      group: 'System metrics (Kubernetes)',
      title: 'Core Usage (Pod Average)',
      y_label: 'Cores per Pod'
    }
  end

  context 'with /-/environments/:environment_id/metrics URL' do
    let(:params) { ['group', 'project', environment_id] }
    let(:trigger_url) { urls.metrics_namespace_project_environment_url(*params, **query_params) }

    context 'with no query params' do
      let(:query_params) { {} }

      it_behaves_like 'a metrics embed filter'
    end

    context 'with query params' do
      it_behaves_like 'a metrics embed filter'
    end
  end

  context 'with /-/metrics?environment=:environment_id URL' do
    let(:params) { %w(group project) }
    let(:trigger_url) { urls.namespace_project_metrics_dashboard_url(*params, **query_params) }
    let(:dashboard_url) do
      urls.metrics_dashboard_namespace_project_environment_url(
        *params.append(environment_id),
        **query_params.except(:environment),
        embedded: true
      )
    end

    context 'with query params' do
      it_behaves_like 'a metrics embed filter' do
        before do
          query_params.merge!(environment: environment_id)
        end
      end
    end

    context 'with only environment in query params' do
      let(:query_params) { { environment: environment_id } }

      it_behaves_like 'a metrics embed filter'
    end

    context 'with no query params' do
      let(:query_params) { {} }

      it 'ignores metrics URL without environment parameter' do
        input = %(<a href="#{trigger_url}">example</a>)
        filtered_input = filter(input).to_s

        expect(CGI.unescape_html(filtered_input)).to eq(input)
      end
    end
  end

  it 'leaves links to other dashboards unchanged' do
    url = urls.namespace_project_grafana_api_metrics_dashboard_url('foo', 'bar')
    input = %(<a href="#{url}">example</a>)

    expect(filter(input).to_s).to eq(input)
  end
end
