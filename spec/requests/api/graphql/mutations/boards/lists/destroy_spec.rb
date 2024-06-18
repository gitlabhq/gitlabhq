# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Lists::Destroy, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user, reload: true) { create(:user) }

  it_behaves_like 'board lists destroy request' do
    let_it_be(:group, reload: true) { create(:group) }
    let_it_be(:board) { create(:board, group: group) }
    let_it_be(:list, refind: true) { create(:list, board: board) }

    let(:variables) do
      {
        list_id: GitlabSchema.id_from_object(list).to_s
      }
    end

    let(:mutation) do
      graphql_mutation(:destroy_board_list, variables)
    end

    let(:mutation_response) { graphql_mutation_response(:destroy_board_list) }
    let(:klass) { List }
  end
end
