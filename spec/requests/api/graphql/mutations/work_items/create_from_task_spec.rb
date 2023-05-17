# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Create a work item from a task in a work item's description", feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:work_item, refind: true) { create(:work_item, :confidential, project: project, description: '- [ ] A task in a list', lock_version: 3) }

  let(:lock_version) { work_item.lock_version }
  let(:input) do
    {
      'id' => work_item.to_global_id.to_s,
      'workItemData' => {
        'title' => 'A task in a list',
        'workItemTypeId' => WorkItems::Type.default_by_type(:task).to_global_id.to_s,
        'lineNumberStart' => 1,
        'lineNumberEnd' => 1,
        'lockVersion' => lock_version
      }
    }
  end

  let(:mutation) { graphql_mutation(:workItemCreateFromTask, input, nil, ['productAnalyticsState']) }
  let(:mutation_response) { graphql_mutation_response(:work_item_create_from_task) }

  context 'the user is not allowed to update a work item' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to create a work item' do
    let(:current_user) { developer }

    it 'creates the work item' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change(WorkItem, :count).by(1)

      created_work_item = WorkItem.last
      work_item.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(work_item.description).to eq("- [ ] #{created_work_item.to_reference}+")
      expect(created_work_item.work_item_type.base_type).to eq('task')
      expect(created_work_item.work_item_parent).to eq(work_item)
      expect(created_work_item).to be_confidential
      expect(mutation_response['workItem']).to include('id' => work_item.to_global_id.to_s)
      expect(mutation_response['newWorkItem']).to include('id' => created_work_item.to_global_id.to_s)
    end

    context 'when creating a work item fails' do
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

    it_behaves_like 'has spam protection' do
      let(:mutation_class) { ::Mutations::WorkItems::CreateFromTask }
    end
  end
end
