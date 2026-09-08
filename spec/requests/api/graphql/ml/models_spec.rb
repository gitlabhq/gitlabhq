# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.mlModel', feature_category: :mlops do
  include GraphqlHelpers

  let_it_be(:model) { create(:ml_models, :with_versions) }
  let_it_be(:project) { model.project }
  let_it_be(:current_user) { project.owner }
  let_it_be(:candidate) do
    create(:ml_candidates, :with_metrics_and_params, :with_metadata,
      project: project, experiment: model.default_experiment)
  end

  let(:user) { current_user }
  let(:boundary_object) { project }
  let(:model_selection) { 'id' }
  let(:query) { graphql_query_for(:ml_model, { id: global_id_of(model) }, model_selection) }
  let(:request) { post_graphql(query, token: { personal_access_token: pat }) }

  context 'when querying project.mlModels' do
    let(:model_fields) do
      <<~FIELDS
        mlModels {
          nodes {
            id
            name
            _links { showPath }
            latestVersion {
              id
              _links { showPath packagePath importPath }
            }
            candidates {
              nodes {
                id
                _links { showPath artifactPath }
                params { nodes { id name } }
                metrics { nodes { id name } }
                metadata { nodes { id name } }
              }
            }
          }
        }
      FIELDS
    end

    let(:query) { graphql_query_for(:project, { full_path: project.full_path }, model_fields) }

    it_behaves_like 'authorizing granular token permissions for GraphQL',
      [:read_project, :read_ml_model, :read_model_version, :read_ml_flow_run]
  end

  context 'when the token is scoped to the model but not to its children' do
    let(:pat) do
      create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(project), permissions: %w[read_ml_model])
    end

    let(:model_selection) { 'id latestVersion { id } candidates { nodes { id } }' }

    it 'returns the model without its versions or candidates', :aggregate_failures do
      request

      expect(graphql_data_at(:ml_model, :id)).to be_present
      expect(graphql_data_at(:ml_model, :latest_version)).to be_nil
      expect(graphql_data_at(:ml_model, :candidates, :nodes)).to all(be_nil)
    end
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL with a skipped child type',
    [:read_ml_model] do
    let(:model_selection) { '_links { showPath }' }
    let(:skipped_data_path) { %i[ml_model _links] }
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL with a skipped child type',
    [:read_ml_model, :read_model_version] do
    let(:model_selection) { 'latestVersion { _links { showPath packagePath importPath } }' }
    let(:skipped_data_path) { %i[ml_model latest_version _links] }
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL with a skipped child type',
    [:read_ml_model, :read_ml_flow_run] do
    let(:model_selection) { 'candidates { nodes { _links { showPath artifactPath } } }' }
    let(:skipped_data_path) { %i[ml_model candidates nodes _links] }
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL with a skipped child type',
    [:read_ml_model, :read_ml_flow_run] do
    let(:model_selection) { 'candidates { nodes { metrics { nodes { id name } } } }' }
    let(:skipped_data_path) { %i[ml_model candidates nodes metrics nodes] }
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL with a skipped child type',
    [:read_ml_model, :read_ml_flow_run] do
    let(:model_selection) { 'candidates { nodes { params { nodes { id name } } } }' }
    let(:skipped_data_path) { %i[ml_model candidates nodes params nodes] }
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL with a skipped child type',
    [:read_ml_model, :read_ml_flow_run] do
    let(:model_selection) { 'candidates { nodes { metadata { nodes { id name } } } }' }
    let(:skipped_data_path) { %i[ml_model candidates nodes metadata nodes] }
  end
end
