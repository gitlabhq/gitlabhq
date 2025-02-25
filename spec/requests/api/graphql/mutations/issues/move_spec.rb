# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Moving an issue', feature_category: :team_planning do
  include GraphqlHelpers

  shared_examples 'move work item mutation request' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue) }
    let_it_be(:target_project) { create(:project) }

    let(:mutation_response) { graphql_mutation_response(:issue_move) }
    let(:mutation) do
      variables = {
        project_path: issue.project.full_path,
        target_project_path: target_project.full_path,
        iid: issue.iid.to_s
      }

      graphql_mutation(
        :issue_move,
        variables,
        <<-QL.strip_heredoc
        clientMutationId
        errors
        issue {
          title
        }
      QL
      )
    end

    context 'when the user is not allowed to read source project' do
      it 'returns an error' do
        error = Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to include(a_hash_including('message' => error))
      end
    end

    context 'when the user is not allowed to move issue to target project' do
      before do
        issue.project.add_developer(user)
      end

      context 'with work_item_move_and_clone disabled' do
        it 'returns an error' do
          post_graphql_mutation(mutation, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors'][0]).to eq(error)
        end
      end
    end

    context 'when the user is allowed to move issue' do
      before do
        issue.project.add_developer(user)
        target_project.add_developer(user)
      end

      it 'moves the issue' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response.dig('issue', 'title')).to eq(issue.title)
        expect(issue.reload.state).to eq('closed')
        expect(target_project.issues.find_by_title(issue.title)).to be_present
      end
    end
  end

  context 'with work_item_move_and_clone disabled' do
    it_behaves_like 'move work item mutation request' do
      let(:error) { "Cannot move issue due to insufficient permissions!" }

      before do
        stub_feature_flags(work_item_move_and_clone: false)
      end
    end
  end

  context 'with work_item_move_and_clone enabled' do
    it_behaves_like 'move work item mutation request' do
      let(:error) { "Cannot move work item due to insufficient permissions." }

      before do
        stub_feature_flags(work_item_move_and_clone: true)
      end
    end
  end
end
