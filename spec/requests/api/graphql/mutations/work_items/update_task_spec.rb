# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update a work item task', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:unauthorized_work_item) { create(:work_item) }
  let_it_be(:referenced_work_item, refind: true) { create(:work_item, project: project, title: 'REFERENCED') }
  let_it_be(:parent_work_item) do
    create(:work_item, project: project, description: "- [ ] #{referenced_work_item.to_reference}+")
  end

  let(:task) { referenced_work_item }
  let(:work_item) { parent_work_item }
  let(:task_params) { { 'title' => 'UPDATED' } }
  let(:task_input) { { 'id' => task.to_global_id.to_s }.merge(task_params) }
  let(:input) { { 'id' => work_item.to_global_id.to_s, 'taskData' => task_input } }
  let(:mutation) { graphql_mutation(:workItemUpdateTask, input, nil, ['productAnalyticsState']) }
  let(:mutation_response) { graphql_mutation_response(:work_item_update_task) }

  context 'the user is not allowed to read a work item' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to update a work item' do
    let(:current_user) { developer }

    it 'updates the work item and invalidates markdown cache on the original work item' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        work_item.reload
        referenced_work_item.reload
      end.to change(referenced_work_item, :title).from(referenced_work_item.title).to('UPDATED')

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response).to include(
        'workItem' => hash_including(
          'title' => work_item.title,
          'descriptionHtml' => a_string_including('UPDATED')
        ),
        'task' => hash_including(
          'title' => 'UPDATED'
        )
      )
    end

    context 'when providing invalid task params' do
      let(:task_params) { { 'title' => '' } }

      it 'makes no changes to the DB and returns an error message' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          work_item.reload
          task.reload
        end.to not_change(task, :title).and(
          not_change(work_item, :description_html)
        )

        expect(mutation_response['errors']).to contain_exactly("Title can't be blank")
      end
    end

    context 'when user cannot update the task' do
      let(:task) { unauthorized_work_item }

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    it_behaves_like 'has spam protection' do
      let(:mutation_class) { ::Mutations::WorkItems::UpdateTask }
    end
  end

  context 'when user does not have permissions to update a work item' do
    let(:current_user) { developer }
    let(:work_item) { unauthorized_work_item }

    it_behaves_like 'a mutation that returns a top-level access error'
  end
end
