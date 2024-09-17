# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Editing of a machine learning model', feature_category: :mlops do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { project.owner }
  let_it_be(:guest) { create(:user) }

  let(:name) { 'some_name' }
  let(:description) { 'A description' }

  let(:input) { { project_path: project.full_path, name: name, description: description } }

  let(:model) { create(:ml_models, project: project, name: name, description: description) }

  let(:new_description) { 'A new description' }
  let(:edit_input) { { project_path: project.full_path, name: name, description: new_description, model_id: model.id } }

  let(:mutation) { graphql_mutation(:ml_model_edit, edit_input, nil, ['version']) }
  let(:mutation_response) { graphql_mutation_response(:ml_model_edit) }

  context 'when user is not allowed write changes' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :write_model_registry, project)
                          .and_return(false)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when the user is not part of the project' do
    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: guest)
      expect { mutation }.to not_change { ::Ml::Model.count }
      expect(mutation_response).to be_nil
    end
  end

  context 'when the user is authenticated' do
    context 'when the model does not exist' do
      it 'returns an error' do
        edit_input[:model_id] = 0

        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).not_to be_empty
        expect(mutation_response['errors']).to match_array(['Model not found'])
      end
    end

    context 'when the model exists' do
      before do
        model
      end

      it 'updates the model description' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to be_empty

        model.reload
        expect(model.name).to eq(name)
        expect(model.description).to eq(new_description)
      end
    end

    context 'when the model is not part of the project' do
      let(:model) { create(:ml_models, name: name, description: description) }

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).not_to be_empty
        expect(mutation_response['errors']).to match_array(['Model not found'])
      end
    end
  end
end
