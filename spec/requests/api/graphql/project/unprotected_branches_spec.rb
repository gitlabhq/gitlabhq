# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting unprotected branches for a project', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project, freeze: false) { create(:project, :repository) }

  let(:variables) { { path: project.full_path } }

  let(:query) do
    <<~GQL
      query($path: ID!, $n: Int, $cursor: String, $search: String) {
        project(fullPath: $path) {
          unprotectedBranches(first: $n, after: $cursor, search: $search) {
            pageInfo {
              hasNextPage
              endCursor
            }
            nodes
          }
        }
      }
    GQL
  end

  def unprotected_branches_data
    graphql_data_at(:project, :unprotected_branches, :nodes)
  end

  def page_info
    graphql_data_at(:project, :unprotected_branches, :page_info)
  end

  context 'when the user does not have read_code permissions' do
    before_all do
      project.add_guest(current_user)
    end

    it 'returns null' do
      post_graphql(query, current_user: current_user, variables: variables)

      expect(graphql_data_at(:project, :unprotected_branches)).to be_nil
    end
  end

  context 'when the user has read_code permissions' do
    before_all do
      project.add_maintainer(current_user)
    end

    context 'when the repository is empty' do
      let_it_be(:empty_project) { create(:project, :empty_repo) }

      let(:variables) { { path: empty_project.full_path } }

      before_all do
        empty_project.add_maintainer(current_user)
      end

      it 'returns an empty list', :aggregate_failures do
        post_graphql(query, current_user: current_user, variables: variables)

        expect(unprotected_branches_data).to be_empty
        expect(page_info['hasNextPage']).to be false
      end
    end

    context 'when the repository has branches' do
      it 'returns unprotected branch names' do
        post_graphql(query, current_user: current_user, variables: variables)

        expect(unprotected_branches_data).to be_present
        expect(unprotected_branches_data).to all(be_a(String))
      end

      context 'with a protected branch' do
        before do
          create(:protected_branch, project: project, name: 'master')
        end

        it 'excludes the protected branch' do
          post_graphql(query, current_user: current_user, variables: variables)

          expect(unprotected_branches_data).not_to include('master')
        end
      end

      describe 'search' do
        let(:variables) { { path: project.full_path, search: 'feature' } }

        it 'filters branches by search term' do
          post_graphql(query, current_user: current_user, variables: variables)

          expect(unprotected_branches_data).to be_present
          expect(unprotected_branches_data).to all(include('feature'))
        end
      end

      describe 'invalid cursor' do
        let(:variables) { { path: project.full_path, cursor: '!!!invalid-base64!!!' } }

        it 'returns an error' do
          post_graphql(query, current_user: current_user, variables: variables)

          expect(graphql_errors).to include(
            a_hash_including('message' => 'Invalid pagination cursor')
          )
        end
      end

      describe 'pagination' do
        let(:variables) { { path: project.full_path, n: 3 } }

        it 'returns paginated unprotected branch names', :aggregate_failures do
          post_graphql(query, current_user: current_user, variables: variables)
          first_page = unprotected_branches_data
          cursor = page_info['endCursor']

          expect(first_page.length).to eq(3)
          expect(page_info['hasNextPage']).to be true
          expect(cursor).to be_present

          post_graphql(query, current_user: current_user, variables: variables.merge(cursor: cursor))
          second_page = unprotected_branches_data

          expect(second_page).to be_present
          expect(second_page & first_page).to be_empty
        end
      end
    end
  end
end
