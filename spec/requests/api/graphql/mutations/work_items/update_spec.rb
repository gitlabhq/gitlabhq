# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update a work item' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project) }

  let(:work_item_event) { 'CLOSE' }
  let(:input) { { 'stateEvent' => work_item_event, 'title' => 'updated title' } }
  let(:fields) do
    <<~FIELDS
    workItem {
      state
      title
    }
    errors
    FIELDS
  end

  let(:mutation) { graphql_mutation(:workItemUpdate, input.merge('id' => work_item.to_global_id.to_s), fields) }

  let(:mutation_response) { graphql_mutation_response(:work_item_update) }

  context 'the user is not allowed to update a work item' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to update a work item' do
    let(:current_user) { developer }

    context 'when the work item is open' do
      it 'closes and updates the work item' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          work_item.reload
        end.to change(work_item, :state).from('opened').to('closed').and(
          change(work_item, :title).from(work_item.title).to('updated title')
        )

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['workItem']).to include(
          'state' => 'CLOSED',
          'title' => 'updated title'
        )
      end
    end

    context 'when the work item is closed' do
      let(:work_item_event) { 'REOPEN' }

      before do
        work_item.close!
      end

      it 'reopens the work item' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          work_item.reload
        end.to change(work_item, :state).from('closed').to('opened')

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['workItem']).to include(
          'state' => 'OPEN'
        )
      end
    end

    it_behaves_like 'has spam protection' do
      let(:mutation_class) { ::Mutations::WorkItems::Update }
    end

    context 'when the work_items feature flag is disabled' do
      before do
        stub_feature_flags(work_items: false)
      end

      it 'does not update the work item and returns and error' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          work_item.reload
        end.to not_change(work_item, :title)

        expect(mutation_response['errors']).to contain_exactly('`work_items` feature flag disabled for this project')
      end
    end

    context 'with description widget input' do
      let(:fields) do
        <<~FIELDS
        workItem {
          description
          widgets {
            type
            ... on WorkItemWidgetDescription {
                    description
            }
          }
        }
        errors
        FIELDS
      end

      it_behaves_like 'update work item description widget' do
        let(:new_description) { 'updated description' }
        let(:input) do
          { 'descriptionWidget' => { 'description' => new_description } }
        end
      end
    end

    context 'with weight widget input' do
      let(:fields) do
        <<~FIELDS
        workItem {
          widgets {
            type
            ... on WorkItemWidgetWeight {
              weight
            }
          }
        }
        errors
        FIELDS
      end

      it_behaves_like 'update work item weight widget' do
        let(:new_weight) { 2 }

        let(:input) do
          { 'weightWidget' => { 'weight' => new_weight } }
        end
      end
    end
  end
end
