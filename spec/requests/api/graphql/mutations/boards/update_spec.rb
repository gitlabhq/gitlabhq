# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating a board', feature_category: :team_planning do
  include GraphqlHelpers

  describe 'granular PAT authorization' do
    context 'for a project board' do
      it_behaves_like 'authorizing granular token permissions for GraphQL', :update_issue_board do
        let_it_be(:project) { create(:project) }
        let_it_be(:board) { create(:board, project: project, name: 'board name') }
        let_it_be(:user) { create(:user, maintainer_of: project) }

        let(:boundary_object) { project }
        let(:mutation) { graphql_mutation(:update_board, { id: board.to_global_id.to_s, name: 'new name' }, 'errors') }
        let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
      end
    end

    context 'for a group board' do
      it_behaves_like 'authorizing granular token permissions for GraphQL', :update_issue_board do
        let_it_be(:group) { create(:group) }
        let_it_be(:board) { create(:board, group: group, name: 'board name') }
        let_it_be(:user) { create(:user, maintainer_of: group) }

        let(:boundary_object) { group }
        let(:mutation) { graphql_mutation(:update_board, { id: board.to_global_id.to_s, name: 'new name' }, 'errors') }
        let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
      end
    end
  end
end
