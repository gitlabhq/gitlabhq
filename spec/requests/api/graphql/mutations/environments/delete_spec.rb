# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete Environment', feature_category: :deployment_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:environment) { create(:environment, project: project, state: :stopped) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:developer) { create(:user, maintainer_of: project) }

  let(:environment_id) { environment.to_global_id.to_s }
  let(:current_user) { developer }

  let(:mutation) do
    graphql_mutation(:environment_delete, input)
  end

  context 'when delete is successful' do
    let(:input) do
      { id: environment_id }
    end

    it 'deletes the environment' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { project.reload.environments.include?(environment) }.from(true).to(false)

      expect(graphql_mutation_response(:environment_delete)['errors']).to be_empty
    end
  end
end
