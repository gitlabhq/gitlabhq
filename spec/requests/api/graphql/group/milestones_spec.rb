# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Milestones through GroupQuery' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:now) { Time.now }

  describe 'Get list of milestones from a group' do
    let_it_be(:parent_group) { create(:group) }
    let_it_be(:group) { create(:group, parent: parent_group) }
    let_it_be(:milestone_1) { create(:milestone, group: group) }
    let_it_be(:milestone_2) { create(:milestone, group: group, state: :closed, start_date: now, due_date: now + 1.day) }
    let_it_be(:milestone_3) { create(:milestone, group: group, start_date: now, due_date: now + 2.days) }
    let_it_be(:milestone_4) { create(:milestone, group: group, state: :closed, start_date: now - 2.days, due_date: now - 1.day) }
    let_it_be(:milestone_from_other_group) { create(:milestone, group: create(:group)) }
    let_it_be(:parent_milestone) { create(:milestone, group: parent_group) }

    let(:milestone_data) { graphql_data['group']['milestones']['edges'] }

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

      it 'fetches milestones between timeframe start and end arguments' do
        today = Date.today
        fetch_milestones(user, { timeframe: { start: today.to_s, end: (today + 2.days).to_s } })

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

      context 'when including decendants' do
        let(:args) { { include_descendants: true } }

        it 'returns milestones also from subgroups and subprojects visible to user' do
          fetch_milestones(user, args)

          expect_array_response(
            milestone_1.to_global_id.to_s, milestone_2.to_global_id.to_s,
            milestone_3.to_global_id.to_s, milestone_4.to_global_id.to_s,
            submilestone_1.to_global_id.to_s, submilestone_2.to_global_id.to_s
          )
        end
      end

      context 'when including ancestors' do
        let(:args) { { include_ancestors: true } }

        it 'returns milestones from ancestor groups' do
          fetch_milestones(user, args)

          expect_array_response(
            milestone_1.to_global_id.to_s, milestone_2.to_global_id.to_s,
            milestone_3.to_global_id.to_s, milestone_4.to_global_id.to_s,
            parent_milestone.to_global_id.to_s
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

  describe 'ensures each field returns the correct value' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:milestone) { create(:milestone, group: group, start_date: now, due_date: now + 1.day) }
    let_it_be(:open_issue) { create(:issue, project: project, milestone: milestone) }
    let_it_be(:closed_issue) { create(:issue, :closed, project: project, milestone: milestone) }

    let(:milestone_query) do
      %{
        id
        title
        description
        state
        webPath
        dueDate
        startDate
        createdAt
        updatedAt
        projectMilestone
        groupMilestone
        subgroupMilestone
      }
    end

    def post_query
      full_query = graphql_query_for("group",
        { full_path: group.full_path },
        [query_graphql_field("milestones", nil, "nodes { #{milestone_query} }")]
      )

      post_graphql(full_query, current_user: user)

      graphql_data.dig('group', 'milestones', 'nodes', 0)
    end

    it 'returns correct values for scalar fields' do
      expect(post_query).to eq({
        'id' => global_id_of(milestone),
        'title' => milestone.title,
        'description' => milestone.description,
        'state' => 'active',
        'webPath' => milestone_path(milestone),
        'dueDate' => milestone.due_date.iso8601,
        'startDate' => milestone.start_date.iso8601,
        'createdAt' => milestone.created_at.iso8601,
        'updatedAt' => milestone.updated_at.iso8601,
        'projectMilestone' => false,
        'groupMilestone' => true,
        'subgroupMilestone' => false
      })
    end

    context 'milestone statistics' do
      let(:milestone_query) do
        %{
          stats {
            totalIssuesCount
            closedIssuesCount
          }
        }
      end

      it 'returns the correct milestone statistics' do
        expect(post_query).to eq({
          'stats' => {
            'totalIssuesCount' => 2,
            'closedIssuesCount' => 1
          }
        })
      end
    end
  end
end
