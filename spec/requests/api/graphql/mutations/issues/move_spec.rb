# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Moving an issue', feature_category: :team_planning do
  include GraphqlHelpers

  shared_examples 'move work item mutation request' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue) }
    let_it_be(:target_project) { create(:project) }

    let(:target_work_item_type_id) { nil }
    let(:mutation_response) { graphql_mutation_response(:issue_move) }
    let(:mutation) do
      variables = {
        project_path: issue.project.full_path,
        target_project_path: target_project.full_path,
        iid: issue.iid.to_s
      }
      variables[:target_work_item_type_id] = target_work_item_type_id if target_work_item_type_id

      graphql_mutation(
        :issue_move,
        variables,
        <<-QL.strip_heredoc
        clientMutationId
        errors
        issue {
          title
          type
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

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors'][0]).to eq("Unable to move. You have insufficient permissions.")
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

      it_behaves_like 'authorizing granular token permissions for GraphQL', :move_issue do
        let(:boundary_object) { issue.project }
        let(:mutation) do
          graphql_mutation(
            :issue_move,
            {
              project_path: issue.project.full_path,
              target_project_path: target_project.full_path,
              iid: issue.iid.to_s
            },
            'errors'
          )
        end

        let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
      end

      context 'when targetWorkItemTypeId is provided' do
        let(:incident_type) { build(:work_item_system_defined_type, :incident) }

        context 'and the type is available in the destination namespace' do
          let(:target_work_item_type_id) { incident_type.to_global_id.to_s }

          it 'moves the issue and converts it to the target type', :aggregate_failures do
            post_graphql_mutation(mutation, current_user: user)

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['errors']).to be_empty
            expect(mutation_response.dig('issue', 'type')).to eq('INCIDENT')

            moved = target_project.issues.find_by_title(issue.title)
            expect(moved.work_item_type_id).to eq(incident_type.id)
          end
        end

        context 'and the type id does not resolve in the destination namespace' do
          let(:target_work_item_type_id) do
            ::Gitlab::GlobalId.build(model_name: 'WorkItems::Type', id: non_existing_record_id).to_s
          end

          it 'returns an error and does not move the issue', :aggregate_failures do
            post_graphql_mutation(mutation, current_user: user)

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['errors']).to include(
              'Unable to move. The selected work item type is not available in the target namespace.'
            )
            expect(mutation_response['issue']).to be_nil
            expect(target_project.issues.find_by_title(issue.title)).to be_nil
          end
        end
      end
    end
  end

  it_behaves_like 'move work item mutation request'
end
