# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Stages::VariableEndpointInserter do
  include MetricsDashboardHelpers

  let(:project) { build_stubbed(:project) }
  let(:environment) { build_stubbed(:environment, project: project) }

  describe '#transform!' do
    subject(:transform!) { described_class.new(project, dashboard, environment: environment).transform! }

    let(:dashboard) { load_sample_dashboard.deep_symbolize_keys }

    context 'when dashboard variables are present' do
      it 'assigns prometheus_endpoint_path to metric_label_values variable type' do
        endpoint_path = Gitlab::Routing.url_helpers.prometheus_api_project_environment_path(
          project,
          environment,
          proxy_path: :series,
          match: ['backend:haproxy_backend_availability:ratio{env="{{env}}"}']
        )

        transform!

        expect(
          dashboard.dig(:templating, :variables, :metric_label_values_variable, :options)
        ).to include(prometheus_endpoint_path: endpoint_path)
      end

      it 'does not modify other variable types' do
        original_text_variable = dashboard[:templating][:variables][:text_variable_full_syntax].deep_dup

        transform!

        expect(dashboard[:templating][:variables][:text_variable_full_syntax]).to eq(original_text_variable)
      end

      context 'when variable does not have the required series_selector' do
        it 'adds prometheus_endpoint_path without match parameter' do
          dashboard[:templating][:variables][:metric_label_values_variable][:options].delete(:series_selector)
          endpoint_path = Gitlab::Routing.url_helpers.prometheus_api_project_environment_path(
            project,
            environment,
            proxy_path: :series
          )

          transform!

          expect(
            dashboard.dig(:templating, :variables, :metric_label_values_variable, :options)
          ).to include(prometheus_endpoint_path: endpoint_path)
        end
      end
    end

    context 'when no variables are present' do
      it 'does not fail' do
        dashboard.delete(:templating)

        expect { transform! }.not_to raise_error
      end
    end

    context 'with no environment' do
      subject(:transform!) { described_class.new(project, dashboard, {}).transform! }

      it 'raises error' do
        expect { transform! }.to raise_error(
          Gitlab::Metrics::Dashboard::Errors::DashboardProcessingError,
          'Environment is required for Stages::VariableEndpointInserter'
        )
      end
    end
  end
end
