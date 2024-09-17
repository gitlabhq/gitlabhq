# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Editing of a machine learning model version', feature_category: :mlops do
  include GraphqlHelpers
  let_it_be(:model_version) { create(:ml_model_versions, :with_package, description: 'A **description**') }
  let_it_be(:project) { model_version.project }
  let_it_be(:current_user) { project.owner }
  let_it_be(:guest) { create(:user) }

  let(:model_id) { model_version.model.to_gid }
  let(:version) { model_version.version }
  let(:description) { 'A description' }
  let(:new_description) { 'A **new** description' }

  let(:edit_input) do
    { project_path: project.full_path, description: new_description, model_id: model_id, version: version }
  end

  let(:mutation) { graphql_mutation(:ml_model_version_edit, edit_input, nil, ['version']) }
  let(:mutation_response) { graphql_mutation_response(:ml_model_version_edit) }

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
    it 'does not update description' do
      post_graphql_mutation(mutation, current_user: guest)
      expect { mutation }.to not_change { model_version.reload.description }
      expect(mutation_response).to be_nil
    end
  end

  context 'when the user is authenticated' do
    context 'when the model does not exist' do
      let(:model_id) { "gid://gitlab/Ml::Model/0" }

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to match_array(['Model not found'])
      end
    end

    context 'when the model exists' do
      it 'updates the model description' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to be_empty

        model_version.reload
        expect(model_version.description).to eq(new_description)
      end
    end

    context 'when the model is not part of the project' do
      let(:project) { create(:project) }

      before do
        post_graphql_mutation(mutation, current_user: current_user)
      end

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when the update service fails' do
      before do
        allow_next_instance_of(::Ml::ModelVersions::UpdateModelVersionService) do |instance|
          allow(instance).to receive(:execute).and_return(
            ServiceResponse.error(message: 'Model update failed')
          )
        end
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to match_array(['Model update failed'])
        expect(mutation_response['modelVersion']).to be_nil
      end
    end
  end
end
