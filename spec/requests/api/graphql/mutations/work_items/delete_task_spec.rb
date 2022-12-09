# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Delete a task in a work item's description", feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:task) { create(:work_item, :task, project: project, author: developer) }
  let_it_be(:work_item, refind: true) do
    create(:work_item, project: project, description: "- [ ] #{task.to_reference}+", lock_version: 3)
  end

  before_all do
    create(:issue_link, source_id: work_item.id, target_id: task.id)
  end

  let(:lock_version) { work_item.lock_version }
  let(:input) do
    {
      'id' => work_item.to_global_id.to_s,
      'lockVersion' => lock_version,
      'taskData' => {
        'id' => task.to_global_id.to_s,
        'lineNumberStart' => 1,
        'lineNumberEnd' => 1
      }
    }
  end

  let(:mutation) { graphql_mutation(:workItemDeleteTask, input) }
  let(:mutation_response) { graphql_mutation_response(:work_item_delete_task) }

  context 'the user is not allowed to update a work item' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user can update the description but not delete the task' do
    let(:current_user) { create(:user).tap { |u| project.add_developer(u) } }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to remove a task' do
    let(:current_user) { developer }

    it 'removes the task from the work item' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        work_item.reload
      end.to change(WorkItem, :count).by(-1).and(
        change(IssueLink, :count).by(-1)
      ).and(
        change(work_item, :description).from("- [ ] #{task.to_reference}+").to("- [ ] #{task.title}")
      )

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['workItem']).to include('id' => work_item.to_global_id.to_s)
    end

    context 'when removing the task fails' do
      let(:lock_version) { 2 }

      it 'makes no changes to the DB and returns an error message' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          work_item.reload
        end.to not_change(WorkItem, :count).and(
          not_change(work_item, :description)
        )

        expect(mutation_response['errors']).to contain_exactly('Stale work item. Check lock version')
      end
    end
  end
end
