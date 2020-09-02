# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a label or backlog board list' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:board, group: group) }
  let_it_be(:user)  { create(:user) }
  let_it_be(:dev_label) do
    create(:group_label, title: 'Development', color: '#FFAABB', group: group)
  end

  let(:current_user) { user }
  let(:mutation) { graphql_mutation(:board_list_create, input) }
  let(:mutation_response) { graphql_mutation_response(:board_list_create) }

  context 'the user is not allowed to read board lists' do
    let(:input) { { board_id: board.to_global_id.to_s, backlog: true } }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to admin board lists' do
    before do
      group.add_reporter(current_user)
    end

    describe 'backlog list' do
      let(:input) { { board_id: board.to_global_id.to_s, backlog: true } }

      it 'creates the list' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['list'])
          .to include('position' => nil, 'listType' => 'backlog')
      end
    end

    describe 'label list' do
      let(:input) { { board_id: board.to_global_id.to_s, label_id: dev_label.to_global_id.to_s } }

      it 'creates the list' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['list'])
          .to include('position' => 0, 'listType' => 'label', 'label' => include('title' => 'Development'))
      end
    end
  end
end
