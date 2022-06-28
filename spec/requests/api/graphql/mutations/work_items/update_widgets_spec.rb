# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update work item widgets' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project) }

  let(:input) { { 'descriptionWidget' => { 'description' => 'updated description' } } }
  let(:mutation_response) { graphql_mutation_response(:work_item_update_widgets) }
  let(:mutation) do
    graphql_mutation(:workItemUpdateWidgets, input.merge('id' => work_item.to_global_id.to_s), <<~FIELDS)
    errors
    workItem {
      description
      widgets {
        type
        ... on WorkItemWidgetDescription {
                description
        }
      }
    }
    FIELDS
  end

  context 'the user is not allowed to update a work item' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to update a work item', :aggregate_failures do
    let(:current_user) { developer }

    it_behaves_like 'update work item description widget' do
      let(:new_description) { 'updated description' }
    end

    it_behaves_like 'has spam protection' do
      let(:mutation_class) { ::Mutations::WorkItems::UpdateWidgets }
    end

    context 'when the work_items feature flag is disabled' do
      before do
        stub_feature_flags(work_items: false)
      end

      it 'does not update the work item and returns and error' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          work_item.reload
        end.to not_change(work_item, :description)

        expect(mutation_response['errors']).to contain_exactly('`work_items` feature flag disabled for this project')
      end
    end
  end
end
