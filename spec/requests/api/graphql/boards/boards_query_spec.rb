# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get list of boards', feature_category: :portfolio_management do
  include GraphqlHelpers

  include_context 'group and project boards query context'

  describe 'for a project' do
    let(:board_parent) { create(:project, :repository, :private) }

    it_behaves_like 'group and project boards query'

    it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_project, :read_issue_board] do
      let(:user) { create(:user, developer_of: board_parent) }
      let(:boundary_object) { board_parent }
      let(:query) do
        graphql_query_for(:project, { full_path: board_parent.full_path },
          query_graphql_field(:boards, {}, 'nodes { id }'))
      end

      let(:request) { post_graphql(query, token: { personal_access_token: pat }) }

      before do
        create(:board, resource_parent: board_parent)
      end
    end
  end

  describe 'for a group' do
    let(:board_parent) { create(:group, :private) }

    before do
      allow(board_parent).to receive(:multiple_issue_boards_available?).and_return(false)
    end

    it_behaves_like 'group and project boards query'

    it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_group, :read_issue_board] do
      let(:user) { create(:user, developer_of: board_parent) }
      let(:boundary_object) { board_parent }
      let(:query) do
        graphql_query_for(:group, { full_path: board_parent.full_path },
          query_graphql_field(:boards, {}, 'nodes { id }'))
      end

      let(:request) { post_graphql(query, token: { personal_access_token: pat }) }

      before do
        create(:board, resource_parent: board_parent)
      end
    end
  end
end
