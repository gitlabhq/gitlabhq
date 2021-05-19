# frozen_string_literal: true

RSpec.shared_examples 'a GraphQL request to update board list' do
  context 'the user is not allowed to read board lists' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  before do
    list.update_preferences_for(current_user, collapsed: false)
  end

  context 'when user has permissions to admin board lists' do
    before do
      group.add_reporter(current_user)
    end

    it 'updates the list position and collapsed state' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['list']).to include(
        'position' => 1,
        'collapsed' => true
      )
    end
  end

  context 'when user has permissions to read board lists' do
    before do
      group.add_guest(current_user)
    end

    it 'updates the list collapsed state but not the list position' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['list']).to include(
        'position' => 0,
        'collapsed' => true
      )
    end
  end
end
