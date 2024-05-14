# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a machine learning model', feature_category: :mlops do
  include GraphqlHelpers

  let_it_be(:model) { create(:ml_models) }
  let_it_be(:project) { model.project }
  let_it_be(:current_user) { project.owner }

  let(:input) { { project_path: project.full_path, name: name, description: description } }
  let(:name) { 'some_name' }
  let(:description) { 'A description' }

  let(:mutation) { graphql_mutation(:ml_model_create, input, nil, ['version']) }
  let(:mutation_response) { graphql_mutation_response(:ml_model_create) }

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
      expect(mutation_response['model']).to include(
        'name' => name,
        'description' => description
      )
    end

    context 'when name already exists' do
      err_msg = "Name should be unique in the project"
      let(:name) { model.name }

      it_behaves_like 'a mutation that returns errors in the response', errors: [err_msg]
    end
  end
end
