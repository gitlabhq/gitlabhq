# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Lists::Destroy do
  include GraphqlHelpers

  let_it_be(:current_user, reload: true) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:list) { create(:list, board: board) }
  let(:mutation) do
    variables = {
      list_id: GitlabSchema.id_from_object(list).to_s
    }

    graphql_mutation(:destroy_board_list, variables)
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:destroy_board_list)
  end

  context 'when the user does not have permission' do
    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not destroy the list' do
      expect { subject }.not_to change { List.count }
    end
  end

  context 'when the user has permission' do
    before do
      project.add_maintainer(current_user)
    end

    context 'when given id is not for a list' do
      let_it_be(:list) { build_stubbed(:issue, project: project) }

      it 'returns an error' do
        subject

        expect(graphql_errors.first['message']).to include('does not represent an instance of List')
      end
    end

    context 'when everything is ok' do
      it 'destroys the list' do
        expect { subject }.to change { List.count }.from(2).to(1)
      end

      it 'returns an empty list' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response).to have_key('list')
        expect(mutation_response['list']).to be_nil
      end
    end

    context 'when the list is not destroyable' do
      let_it_be(:list) { create(:list, board: board, list_type: :backlog) }

      it 'does not destroy the list' do
        expect { subject }.not_to change { List.count }.from(3)
      end

      it 'returns an error and not nil list' do
        subject

        expect(mutation_response['errors']).not_to be_empty
        expect(mutation_response['list']).not_to be_nil
      end
    end
  end
end
