# frozen_string_literal: true

require 'spec_helper'

describe 'Milestones through GroupQuery' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:now) { Time.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:milestone_1) { create(:milestone, group: group) }
  let_it_be(:milestone_2) { create(:milestone, group: group, state: :closed, start_date: now, due_date: now + 1.day) }
  let_it_be(:milestone_3) { create(:milestone, group: group, start_date: now, due_date: now + 2.days) }
  let_it_be(:milestone_4) { create(:milestone, group: group, state: :closed, start_date: now - 2.days, due_date: now - 1.day) }
  let_it_be(:milestone_from_other_group) { create(:milestone, group: create(:group)) }

  let(:milestone_data) { graphql_data['group']['milestones']['edges'] }

  describe 'Get list of milestones from a group' do
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

    context 'when including milestones from decendants' do
      let_it_be(:accessible_group) { create(:group, :private, parent: group) }
      let_it_be(:accessible_project) { create(:project, group: accessible_group) }
      let_it_be(:inaccessible_group) { create(:group, :private, parent: group) }
      let_it_be(:inaccessible_project) { create(:project, :private, group: group) }
      let_it_be(:submilestone_1) { create(:milestone, group: accessible_group) }
      let_it_be(:submilestone_2) { create(:milestone, project: accessible_project) }
      let_it_be(:submilestone_3) { create(:milestone, group: inaccessible_group) }
      let_it_be(:submilestone_4) { create(:milestone, project: inaccessible_project) }

      let(:args) { { include_descendants: true } }

      before do
        accessible_group.add_developer(user)
      end

      it 'returns milestones also from subgroups and subprojects visible to user' do
        fetch_milestones(user, args)

        expect_array_response(
          milestone_1.to_global_id.to_s, milestone_2.to_global_id.to_s,
          milestone_3.to_global_id.to_s, milestone_4.to_global_id.to_s,
          submilestone_1.to_global_id.to_s, submilestone_2.to_global_id.to_s
        )
      end

      context 'when group_milestone_descendants is disabled' do
        before do
          stub_feature_flags(group_milestone_descendants: false)
        end

        it 'ignores descendant milestones' do
          fetch_milestones(user, args)

          expect_array_response(
            milestone_1.to_global_id.to_s, milestone_2.to_global_id.to_s,
            milestone_3.to_global_id.to_s, milestone_4.to_global_id.to_s
          )
        end
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
