# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update work item widgets' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project) }

  let(:input) do
    {
      'descriptionWidget' => { 'description' => 'updated description' }
    }
  end

  let(:mutation) { graphql_mutation(:workItemUpdateWidgets, input.merge('id' => work_item.to_global_id.to_s)) }

  let(:mutation_response) { graphql_mutation_response(:work_item_update_widgets) }

  context 'the user is not allowed to update a work item' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to update a work item', :aggregate_failures do
    let(:current_user) { developer }

    context 'when the updated work item is not valid' do
      it 'returns validation errors without the work item' do
        errors = ActiveModel::Errors.new(work_item).tap { |e| e.add(:description, 'error message') }

        allow_next_found_instance_of(::WorkItem) do |instance|
          allow(instance).to receive(:valid?).and_return(false)
          allow(instance).to receive(:errors).and_return(errors)
        end

        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['workItem']).to be_nil
        expect(mutation_response['errors']).to match_array(['Description error message'])
      end
    end

    it 'updates the work item widgets' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        work_item.reload
      end.to change(work_item, :description).from(nil).to('updated description')

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['workItem']).to include(
        'title' => work_item.title
      )
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
        end.to not_change(work_item, :title)

        expect(mutation_response['errors']).to contain_exactly('`work_items` feature flag disabled for this project')
      end
    end
  end
end
