# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'mutation Users::SavedReplies::Update', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let!(:saved_reply) { create(:saved_reply, user: current_user) }

  let(:input) { { id: saved_reply.to_global_id, name: 'New name', content: 'New content' } }

  let(:mutation) { graphql_mutation(:saved_reply_update, input) }
  let(:mutation_response) { graphql_mutation_response(:saved_reply_update) }

  it 'updates the saved reply' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['savedReply']).to include(
      'name' => 'New name',
      'content' => 'New content'
    )
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :update_saved_reply do
    let(:user) { current_user }
    let(:boundary_object) { :user }
    let(:mutation) { graphql_mutation(:saved_reply_update, input, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
