# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update of an existing issue', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:label1) { create(:label, title: "a", project: project) }
  let_it_be(:label2) { create(:label, title: "b", project: project) }

  let(:input) do
    {
      'iid' => issue.iid.to_s,
      'title' => 'new title',
      'description' => 'new description',
      'confidential' => true,
      'dueDate' => Date.tomorrow.iso8601,
      'type' => 'ISSUE'
    }
  end

  let(:extra_params) { { project_path: project.full_path, locked: true } }
  let(:input_params) { input.merge(extra_params) }
  let(:mutation) { graphql_mutation(:update_issue, input_params) }
  let(:mutation_response) { graphql_mutation_response(:update_issue) }

  context 'the user is not allowed to update issue' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to update issue' do
    before do
      project.add_developer(current_user)
    end

    it 'updates the issue' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['issue']).to include(input)
      expect(mutation_response['issue']).to include('discussionLocked' => true)
    end

    context 'when issue_type is updated' do
      let(:input) { { 'iid' => issue.iid.to_s, 'type' => 'INCIDENT' } }

      it 'updates issue_type and work_item_type' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          issue.reload
        end.to change { issue.work_item_type.base_type }.from('issue').to('incident')
      end
    end

    context 'setting labels' do
      let(:mutation) do
        graphql_mutation(:update_issue, input_params) do
          <<~QL
              issue {
                 labels {
                   nodes {
                     id
                   }
                 }
              }
              errors
          QL
        end
      end

      context 'reset labels' do
        let(:input_params) { input.merge(extra_params).merge({ labelIds: [label1.id, label2.id] }) }

        it 'resets labels' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['errors']).to be_nil
          expect(mutation_response['issue']['labels']).to include({ "nodes" => [{ "id" => label1.to_global_id.to_s }, { "id" => label2.to_global_id.to_s }] })
        end

        context 'reset labels and add labels' do
          let(:input_params) { input.merge(extra_params).merge({ labelIds: [label1.id], addLabelIds: [label2.id] }) }

          it 'returns error for mutually exclusive arguments' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response['errors'].first['message']).to eq('labelIds is mutually exclusive with any of addLabelIds or removeLabelIds')
            expect(mutation_response).to be_nil
          end
        end

        context 'reset labels and remove labels' do
          let(:input_params) { input.merge(extra_params).merge({ labelIds: [label1.id], removeLabelIds: [label2.id] }) }

          it 'returns error for mutually exclusive arguments' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response['errors'].first['message']).to eq('labelIds is mutually exclusive with any of addLabelIds or removeLabelIds')
            expect(mutation_response).to be_nil
          end
        end

        context 'with global label ids' do
          let(:input_params) { input.merge(extra_params).merge({ labelIds: [label1.to_global_id.to_s, label2.to_global_id.to_s] }) }

          it 'resets labels' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response['errors']).to be_nil
            expect(mutation_response['issue']['labels']).to include({ "nodes" => [{ "id" => label1.to_global_id.to_s }, { "id" => label2.to_global_id.to_s }] })
          end
        end
      end

      context 'add and remove labels' do
        let(:input_params) { input.merge(extra_params).merge({ addLabelIds: [label1.id], removeLabelIds: [label2.id] }) }

        it 'returns correct labels' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['errors']).to be_nil
          expect(mutation_response['issue']['labels']).to include({ "nodes" => [{ "id" => label1.to_global_id.to_s }] })
        end
      end

      context 'add labels' do
        let(:input_params) { input.merge(extra_params).merge({ addLabelIds: [label1.id] }) }

        before do
          issue.update!({ labels: [label2] })
        end

        it 'adds labels and keeps the title ordering' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['errors']).to be_nil
          expect(mutation_response['issue']['labels']['nodes']).to eq([{ "id" => label1.to_global_id.to_s }, { "id" => label2.to_global_id.to_s }])
        end
      end
    end

    it_behaves_like 'updating time estimate' do
      let(:resource) { issue }
      let(:mutation_name) { 'updateIssue' }
    end
  end
end
