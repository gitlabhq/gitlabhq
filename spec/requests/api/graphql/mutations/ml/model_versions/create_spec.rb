# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a machine learning model version', feature_category: :mlops do
  include GraphqlHelpers

  let_it_be(:model) { create(:ml_models) }
  let_it_be(:project) { model.project }
  let_it_be(:current_user) { project.owner }
  let_it_be(:candidate) do
    create(:ml_candidates, experiment: model.default_experiment, project: model.project)
  end

  let(:version) { '1.0.0' }
  let(:description) { 'A description' }
  let(:input) { { project_path: project.full_path, modelId: model.to_gid, version: version, description: description } }
  let(:fields) do
    <<~FIELDS
    modelVersion{
      version
      description
      id
    }
    errors
    FIELDS
  end

  let(:mutation) { graphql_mutation(:ml_model_version_create, input, fields, ['version']) }
  let(:mutation_response) { graphql_mutation_response(:ml_model_version_create) }

  context 'when user is not allowed write changes' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :write_model_registry, project)
                          .and_return(false)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user is allowed write changes' do
    it 'creates a model' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['modelVersion']).to include(
        'version' => version,
        'description' => description
      )
    end

    context 'when version is invalid' do
      let(:version) { 'invalid-version' }

      it_behaves_like 'a mutation that returns errors in the response', errors: ["Version must be semantic version"]
    end
  end

  context 'when a candidate_id is present' do
    let(:input) do
      {
        project_path: project.full_path,
        modelId: model.to_gid,
        version: version,
        candidate_id: candidate.to_global_id.to_s
      }
    end

    it 'creates a model' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['modelVersion']).to include(
        'version' => version
      )
    end

    context 'when run is not found in the same project' do
      let_it_be(:candidate) { create(:ml_candidates) }

      it_behaves_like 'a mutation that returns errors in the response', errors: ["Run not found"]
    end
  end
end
