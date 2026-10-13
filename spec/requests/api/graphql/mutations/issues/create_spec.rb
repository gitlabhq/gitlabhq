# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create an issue', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:assignee1) { create(:user) }
  let_it_be(:assignee2) { create(:user) }
  let_it_be(:project_label1) { create(:label, project: project) }
  let_it_be(:project_label2) { create(:label, project: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:new_label1) { FFaker::Lorem.word }
  let_it_be(:new_label2) { FFaker::Lorem.word }

  let(:input) do
    {
      'title' => 'new title',
      'description' => 'new description',
      'confidential' => true,
      'dueDate' => Date.tomorrow.iso8601,
      'type' => 'ISSUE'
    }
  end

  let(:mutation) { graphql_mutation(:createIssue, input.merge('projectPath' => project.full_path, 'locked' => true)) }

  let(:mutation_response) { graphql_mutation_response(:create_issue) }

  context 'the user is not allowed to create an issue' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to create an issue' do
    before do
      project.add_developer(current_user)
    end

    it_behaves_like 'authorizing granular token permissions for GraphQL', :create_issue do
      let(:user) { current_user }
      let(:boundary_object) { project }
      let(:mutation) do
        graphql_mutation(:createIssue, input.merge('projectPath' => project.full_path), 'errors')
      end

      let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
    end

    it 'creates the issue' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { Issue.count }.by(1)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['issue']).to include(input)
      expect(mutation_response['issue']).to include('discussionLocked' => true)
      expect(Issue.last.work_item_type.base_type).to eq('issue')
    end

    it_behaves_like 'has spam protection' do
      let(:mutation_class) { ::Mutations::Issues::Create }
    end

    context 'when creating an issue of type TASK' do
      before do
        input['type'] = 'TASK'
      end

      it 'creates an issue with TASK type' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { Issue.count }.by(1)

        created_issue = Issue.last

        expect(created_issue.work_item_type.base_type).to eq('task')
      end
    end

    context 'when position params are provided' do
      let(:existing_issue) { create(:issue, project: project, relative_position: 50) }

      before do
        input.merge!(
          move_after_id: existing_issue.to_global_id.to_s
        )
      end

      it 'sets the correct position' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['issue']['relativePosition']).to be < existing_issue.relative_position
      end
    end

    context 'when adding labels past the work item labels limit' do
      let(:mutation) do
        graphql_mutation(:createIssue, input.merge(
          'projectPath' => project.full_path,
          'labelIds' => [project_label1.to_global_id.to_s, project_label2.to_global_id.to_s]
        ))
      end

      before do
        stub_const('Issue::MAX_NUMBER_OF_LABELS', 1)
      end

      it 'returns the error in the mutation errors without creating the issue', :aggregate_failures do
        expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change { Issue.count }

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['issue']).to be_nil
        expect(mutation_response['errors']).to include(a_string_matching(/Cannot add more than 1 labels/))
      end
    end

    context 'when both labels and labelIds params are provided' do
      before do
        input.merge!(
          labels: [project_label1.name],
          label_ids: [project_label1.to_global_id.to_s]
        )
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['Only one of [labels, labelIds] arguments is allowed at the same time.']
    end
  end
end
