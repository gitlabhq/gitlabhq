# frozen_string_literal: true

require 'spec_helper'

describe 'Milestones through GroupQuery' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:now) { Time.now }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:milestone_1) { create(:milestone, group: group) }
  let_it_be(:milestone_2) { create(:milestone, group: group, state: :closed, start_date: now, due_date: now + 1.day) }
  let_it_be(:milestone_3) { create(:milestone, group: group, start_date: now, due_date: now + 2.days) }
  let_it_be(:milestone_4) { create(:milestone, group: group, state: :closed, start_date: now - 2.days, due_date: now - 1.day) }
  let_it_be(:milestone_from_other_group) { create(:milestone, group: create(:group)) }

  let(:milestone_data) { graphql_data['group']['milestones']['edges'] }

  describe 'Get list of milestones from a group' do
    before do
      group.add_developer(user)
    end

    context 'when the request is correct' do
      before do
        fetch_milestones(user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns milestones successfully' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(graphql_errors).to be_nil
        expect_array_response(milestone_1.to_global_id.to_s, milestone_2.to_global_id.to_s, milestone_3.to_global_id.to_s, milestone_4.to_global_id.to_s)
      end
    end

    context 'when filtering by timeframe' do
      it 'fetches milestones between start_date and due_date' do
        fetch_milestones(user, { start_date: now.to_s, end_date: (now + 2.days).to_s })

        expect_array_response(milestone_2.to_global_id.to_s, milestone_3.to_global_id.to_s)
      end
    end

    context 'when filtering by state' do
      it 'returns milestones with given state' do
        fetch_milestones(user, { state: :active })

        expect_array_response(milestone_1.to_global_id.to_s, milestone_3.to_global_id.to_s)
      end
    end

    def fetch_milestones(user = nil, args = {})
      post_graphql(milestones_query(args), current_user: user)
    end

    def milestones_query(args = {})
      milestone_node = <<~NODE
      edges {
        node {
          id
          title
          state
        }
      }
      NODE

      graphql_query_for("group",
        { full_path: group.full_path },
        [query_graphql_field("milestones", args, milestone_node)]
      )
    end

    def expect_array_response(*items)
      expect(response).to have_gitlab_http_status(:success)
      expect(milestone_data).to be_an Array
      expect(milestone_node_array('id')).to match_array(items)
    end

    def milestone_node_array(extract_attribute = nil)
      node_array(milestone_data, extract_attribute)
    end
  end
end
