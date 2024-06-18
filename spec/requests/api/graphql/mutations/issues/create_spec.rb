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

    it 'creates the issue' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change(Issue, :count).by(1)

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
        end.to change(Issue, :count).by(1)

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
