# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Getting Grafana Integration', feature_category: :observability do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { project.first_owner }

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('GrafanaIntegration'.classify)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('grafanaIntegration', {}, fields)
    )
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  specify { expect(graphql_data['project']['grafanaIntegration']).to be_nil }
end
