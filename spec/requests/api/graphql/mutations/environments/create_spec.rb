# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create Environment', feature_category: :environment_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user, maintainer_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }

  let(:current_user) { developer }

  let(:mutation) do
    graphql_mutation(:environment_create, input)
  end

  context 'when creating an environment' do
    let(:input) do
      {
        project_path: project.full_path,
        name: 'production',
        external_url: 'https://gitlab.com/'
      }
    end

    it 'creates successfully' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_mutation_response(:environment_create)['environment']['name']).to eq('production')
      expect(graphql_mutation_response(:environment_create)['environment']['externalUrl']).to eq('https://gitlab.com/')
      expect(graphql_mutation_response(:environment_create)['errors']).to be_empty
    end

    context 'when current user is reporter' do
      let(:current_user) { reporter }

      it 'returns error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors.to_s)
          .to include("The resource that you are attempting to access does not exist or you don't have permission")
      end
    end
  end

  context 'when name is missing' do
    let(:input) do
      {
        project_path: project.full_path
      }
    end

    it 'returns error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors.to_s).to include("Expected value to not be null")
    end
  end
end
