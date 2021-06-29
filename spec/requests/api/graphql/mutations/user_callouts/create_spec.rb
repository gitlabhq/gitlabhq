# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a user callout' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:feature_name) { ::UserCallout.feature_names.each_key.first }

  let(:input) do
    {
      'featureName' => feature_name
    }
  end

  let(:mutation) { graphql_mutation(:userCalloutCreate, input) }
  let(:mutation_response) { graphql_mutation_response(:userCalloutCreate) }

  it 'creates user callout' do
    freeze_time do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['userCallout']['featureName']).to eq(feature_name.upcase)
      expect(mutation_response['userCallout']['dismissedAt']).to eq(Time.current.iso8601)
    end
  end
end
