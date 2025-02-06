# frozen_string_literal: true

RSpec.shared_examples 'graphql work item type list request spec' do |context_name = nil|
  include GraphqlHelpers

  include_context context_name || 'with work item types request context'

  let(:parent_key) { parent.to_ability_name.to_sym }
  let(:query) do
    graphql_query_for(
      parent_key.to_s,
      { 'fullPath' => parent.full_path },
      query_nodes('WorkItemTypes', work_item_type_fields)
    )
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when user has access to the resource parent' do
    it_behaves_like 'a working graphql query that returns data' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'returns all default work item types' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(parent_key, :workItemTypes, :nodes)).to match_array(
        expected_work_item_type_response(parent, current_user)
      )
    end

    it 'exposes correct_id in the API through the id field' do
      post_graphql(query, current_user: current_user)

      expect(ids_from_response).to match_array(WorkItems::Type.pluck(:correct_id))
    end

    it 'prevents N+1 queries' do
      # Destroy 2 existing types
      WorkItems::Type.by_type([:issue, :task]).delete_all

      post_graphql(query, current_user: current_user) # warm-up

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { post_graphql(query, current_user: current_user) }
      expect(graphql_errors).to be_blank

      # Add back the 2 deleted types
      expect do
        Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.upsert_types
      end.to change { WorkItems::Type.count }.by(2)

      # TODO: Followup to solve the extra queries - https://gitlab.com/gitlab-org/gitlab/-/issues/512617
      expect do
        post_graphql(query, current_user: current_user)
      end.to issue_same_number_of_queries_as(control).with_threshold(2)
      expect(graphql_errors).to be_blank
    end
  end

  context "when user doesn't have access to the parent" do
    let(:current_user) { create(:user) }

    before do
      post_graphql(query, current_user: current_user)
    end

    it 'does not return the parent' do
      expect(graphql_data).to eq(parent_key.to_s => nil)
    end
  end

  def ids_from_response
    graphql_data_at(parent_key, :workItemTypes, :nodes, :id).map { |gid| GlobalID.new(gid).model_id.to_i }
  end
end
