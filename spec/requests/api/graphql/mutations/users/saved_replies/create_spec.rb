# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'mutation Users::SavedReplies::Create', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:input) { { name: 'Test name', content: 'Test content' } }

  let(:mutation) { graphql_mutation(:saved_reply_create, input) }
  let(:mutation_response) { graphql_mutation_response(:saved_reply_create) }

  it 'creates a saved reply' do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
    end.to change { ::Users::SavedReply.count }.by(1)

    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['savedReply']).to include(
      'name' => 'Test name',
      'content' => 'Test content'
    )
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :create_saved_reply do
    let(:user) { current_user }
    let(:boundary_object) { :user }
    let(:mutation) { graphql_mutation(:saved_reply_create, input, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end
end
