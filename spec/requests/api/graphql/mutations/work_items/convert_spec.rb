# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Converts a work item to a new type", feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:new_type) { create(:work_item_type, :incident) }
  let_it_be(:work_item, refind: true) do
    create(:work_item, :task, project: project, milestone: create(:milestone, project: project))
  end

  let(:current_user) { create(:user) }
  let(:work_item_type_id) { new_type.to_global_id.to_s }
  let(:mutation) { graphql_mutation(:workItemConvert, input) }
  let(:mutation_response) { graphql_mutation_response(:work_item_convert) }
  let(:input) do
    {
      'id' => work_item.to_global_id.to_s,
      'work_item_type_id' => work_item_type_id
    }
  end

  context 'when user is not allowed to update a work item' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to convert the work item type' do
    let(:current_user) { developer }

    context 'when work item type does not exist' do
      let(:work_item_type_id) { "gid://gitlab/WorkItems::Type/#{non_existing_record_id}" }

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).to include(
          a_hash_including('message' => "Work Item type with id #{non_existing_record_id} was not found")
        )
      end
    end

    it 'converts the work item', :aggregate_failures do
      expect(new_type.to_gid.model_id.to_i).to eq(new_type.correct_id)

      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { work_item.reload.work_item_type }.to(new_type)

      expect(response).to have_gitlab_http_status(:success)
      expect(work_item.reload.work_item_type.base_type).to eq('incident')
      expect(mutation_response['workItem']).to include('id' => work_item.to_global_id.to_s)
      expect(GlobalID.new(mutation_response.dig('workItem', 'workItemType', 'id')).model_id.to_i).to eq(
        new_type.correct_id
      )
    end

    context 'when an old ID is used' do
      let(:work_item_type_id) { ::Gitlab::GlobalId.build(new_type, id: new_type.old_id).to_s }

      it 'converts the work item' do
        expect(new_type.old_id).not_to eq(new_type.correct_id)

        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { work_item.reload.work_item_type }.to(new_type)

        expect(response).to have_gitlab_http_status(:success)
        expect(work_item.reload.work_item_type.base_type).to eq('incident')
        expect(mutation_response['workItem']).to include('id' => work_item.to_global_id.to_s)
        expect(GlobalID.new(mutation_response.dig('workItem', 'workItemType', 'id')).model_id.to_i).to eq(
          new_type.correct_id
        )
      end
    end

    it_behaves_like 'has spam protection' do
      let(:mutation_class) { ::Mutations::WorkItems::Convert }
    end
  end
end
