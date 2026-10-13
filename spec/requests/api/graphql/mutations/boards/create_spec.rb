# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Create, feature_category: :planning_views do
  let_it_be(:parent) { create(:project) }
  let_it_be_with_reload(:current_user) { create(:user) }

  let(:name) { 'board name' }
  let(:mutation) { graphql_mutation(:create_board, params) }

  let(:project_path) { parent.full_path }
  let(:params) do
    {
      project_path: project_path,
      name: name
    }
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:create_board)
  end

  it_behaves_like 'boards create mutation'

  describe 'granular PAT authorization' do
    include GraphqlHelpers

    context 'for a project board' do
      it_behaves_like 'authorizing granular token permissions for GraphQL', :create_issue_board do
        let_it_be(:user) { create(:user, maintainer_of: parent) }

        let(:boundary_object) { parent }
        let(:mutation) { graphql_mutation(:create_board, { project_path: parent.full_path, name: name }, 'errors') }
        let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
      end
    end

    context 'for a group board' do
      it_behaves_like 'authorizing granular token permissions for GraphQL', :create_issue_board do
        let_it_be(:group) { create(:group) }
        let_it_be(:user) { create(:user, maintainer_of: group) }

        let(:boundary_object) { group }
        let(:mutation) { graphql_mutation(:create_board, { group_path: group.full_path, name: name }, 'errors') }
        let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
      end
    end
  end
end
