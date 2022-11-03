# frozen_string_literal: true

RSpec.shared_examples 'timeline event mutation responds with validation error' do |error_message:|
  it 'responds with a validation error' do
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['errors']).to match_array([error_message])
  end
end
