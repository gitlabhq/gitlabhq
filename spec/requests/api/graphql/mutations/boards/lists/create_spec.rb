# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a label or backlog board list', feature_category: :planning_views do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:board, group: group) }

  it_behaves_like 'board lists create request' do
    let(:mutation_name) { :board_list_create }
  end

  describe 'granular PAT authorization' do
    include GraphqlHelpers

    context 'for a group board' do
      it_behaves_like 'authorizing granular token permissions for GraphQL', :create_issue_board_list do
        let_it_be(:user) { create(:user, maintainer_of: group) }

        let(:boundary_object) { group }
        let(:mutation) do
          graphql_mutation(:board_list_create, { board_id: board.to_global_id.to_s, backlog: true }, 'errors')
        end

        let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
      end
    end

    context 'for a project board' do
      it_behaves_like 'authorizing granular token permissions for GraphQL', :create_issue_board_list do
        let_it_be(:project) { create(:project, :private) }
        let_it_be(:project_board) { create(:board, project: project) }
        let_it_be(:user) { create(:user, maintainer_of: project) }

        let(:boundary_object) { project }
        let(:mutation) do
          graphql_mutation(:board_list_create, { board_id: project_board.to_global_id.to_s, backlog: true }, 'errors')
        end

        let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
      end
    end
  end
end
