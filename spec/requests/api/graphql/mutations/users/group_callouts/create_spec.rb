# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a user group callout', feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:current_user) { create(:user) }

  let(:feature_name) { ::Users::GroupCallout.feature_names.each_key.first }

  let(:input) do
    {
      'featureName' => feature_name,
      'groupId' => group.to_global_id.to_s
    }
  end

  let(:mutation) { graphql_mutation(:userGroupCalloutCreate, input) }
  let(:mutation_response) { graphql_mutation_response(:userGroupCalloutCreate) }

  context 'when user has permission to read the group' do
    before_all do
      group.add_guest(current_user)
    end

    it 'creates user group callout' do
      freeze_time do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['userGroupCallout']['featureName']).to eq(feature_name.upcase)
        expect(mutation_response['userGroupCallout']['dismissedAt']).to eq(Time.current.iso8601)
        expect(mutation_response['userGroupCallout']['groupId']).to eq(group.to_global_id.to_s)
      end
    end

    it 'returns no errors' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['errors']).to be_empty
    end

    context 'when callout already exists' do
      before do
        create(:group_callout, user: current_user, group: group, feature_name: feature_name)
      end

      it 'returns the existing callout' do
        freeze_time do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['userGroupCallout']['featureName']).to eq(feature_name.upcase)
          expect(mutation_response['userGroupCallout']['groupId']).to eq(group.to_global_id.to_s)
        end
      end
    end
  end

  context 'when user does not have permission to read the group' do
    it 'returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors)
        .to include(hash_including('message' => /The resource that you are attempting to access does not exist/))
    end
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      post_graphql_mutation(mutation)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors)
        .to include(hash_including('message' => /The resource that you are attempting to access does not exist/))
    end
  end
end
