# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineClusterMetricsFilter do
  include FilterSpecHelper

  let!(:cluster) { create(:cluster) }
  let!(:project) { create(:project) }
  let(:params) { [project.namespace.path, project.path, cluster.id] }
  let(:query_params) { { group: 'Food metrics', title: 'Pizza Consumption', y_label: 'Slice Count' } }
  let(:trigger_url) { urls.namespace_project_cluster_url(*params, **query_params) }
  let(:dashboard_url) do
    urls.metrics_dashboard_namespace_project_cluster_url(
      *params,
      **{
        embedded: 'true',
        cluster_type: 'project',
        format: :json
      }.merge(query_params)
    )
  end

  it_behaves_like 'a metrics embed filter'
end
