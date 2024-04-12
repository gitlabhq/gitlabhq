# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Converts a work item to a new type", feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:new_type) { create(:work_item_type, :incident, :default) }
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
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { work_item.reload.work_item_type }.to(new_type)

      expect(response).to have_gitlab_http_status(:success)
      expect(work_item.reload.work_item_type.base_type).to eq('incident')
      expect(mutation_response['workItem']).to include('id' => work_item.to_global_id.to_s)
      expect(work_item.reload.milestone).to be_nil
    end

    it_behaves_like 'has spam protection' do
      let(:mutation_class) { ::Mutations::WorkItems::Convert }
    end
  end

  context 'when converting epic work item' do
    let_it_be(:new_type) { create(:work_item_type, :issue, :default) }
    let(:current_user) { developer }
    let_it_be(:group) { create(:group, developers: developer) }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(current_user, :create_issue, work_item).and_return(true)
    end

    context 'when epic work item does not have a synced epic' do
      let_it_be(:work_item) { create(:work_item, :epic, namespace: group) }

      it 'converts the work item type', :aggregate_failures do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { work_item.reload.work_item_type }.to(new_type)

        expect(response).to have_gitlab_http_status(:success)
        expect(work_item.reload.work_item_type.base_type).to eq('issue')
        expect(mutation_response['workItem']).to include('id' => work_item.to_global_id.to_s)
      end
    end
  end
end
