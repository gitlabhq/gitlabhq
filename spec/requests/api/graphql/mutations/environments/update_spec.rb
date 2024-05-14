# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update Environment', feature_category: :deployment_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:developer) { create(:user, maintainer_of: project) }

  let(:environment_id) { environment.to_global_id.to_s }
  let(:current_user) { developer }

  let(:mutation) do
    graphql_mutation(:environment_update, input)
  end

  context 'when updating external URL' do
    let(:input) do
      {
        id: environment_id,
        external_url: 'https://gitlab.com/'
      }
    end

    it 'updates successfully' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { environment.reload.external_url }.to('https://gitlab.com/')

      expect(graphql_mutation_response(:environment_update)['errors']).to be_empty
    end

    context 'when url is invalid' do
      let(:input) do
        {
          id: environment_id,
          external_url: 'http://${URL}'
        }
      end

      it 'returns error' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.not_to change { environment.reload.external_url }

        expect(graphql_mutation_response(:environment_update)['errors'].first).to include('URI is invalid')
      end
    end
  end

  context 'when updating tier' do
    let(:input) do
      {
        id: environment_id,
        tier: 'STAGING'
      }
    end

    it 'updates successfully' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { environment.reload.tier }.to('staging')

      expect(graphql_mutation_response(:environment_update)['errors']).to be_empty
    end
  end
end
