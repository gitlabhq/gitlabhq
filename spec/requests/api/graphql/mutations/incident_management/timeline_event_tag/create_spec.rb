# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a timeline event tag', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:name) { 'Test tag 1' }

  let(:input) { { project_path: project.full_path, name: name } }
  let(:mutation) do
    graphql_mutation(:timeline_event_tag_create, input) do
      <<~QL
        clientMutationId
        errors
        timelineEventTag {
          id
          name
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:timeline_event_tag_create) }

  context 'when user has permissions to create timeline event tag' do
    before do
      project.add_maintainer(user)
    end

    it 'creates timeline event tag', :aggregate_failures do
      post_graphql_mutation(mutation, current_user: user)

      timeline_event_tag_response = mutation_response['timelineEventTag']

      expect(response).to have_gitlab_http_status(:success)
      expect(timeline_event_tag_response).to include(
        'name' => name
      )
    end
  end

  context 'when user does not have permissions to create timeline event tag' do
    before do
      project.add_developer(user)
    end

    it 'raises error' do
      post_graphql_mutation(mutation, current_user: user)

      expect(mutation_response).to be_nil
      expect_graphql_errors_to_include(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
    end
  end
end
