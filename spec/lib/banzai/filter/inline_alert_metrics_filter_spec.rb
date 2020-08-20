# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineAlertMetricsFilter do
  include FilterSpecHelper

  let(:params) { ['foo', 'bar', 12] }
  let(:query_params) { {} }

  let(:trigger_url) { urls.metrics_dashboard_namespace_project_prometheus_alert_url(*params, query_params) }
  let(:dashboard_url) { urls.metrics_dashboard_namespace_project_prometheus_alert_url(*params, **query_params, embedded: true, format: :json) }

  it_behaves_like 'a metrics embed filter'

  context 'with query params specified' do
    let(:query_params) { { timestamp: 'yesterday' } }

    it_behaves_like 'a metrics embed filter'
  end
end
