# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a work item list for a project', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:label1) { create(:label, project: project) }
  let_it_be(:label2) { create(:label, project: project) }
  let_it_be(:milestone1) { create(:milestone, project: project) }
  let_it_be(:milestone2) { create(:milestone, project: project) }

  let_it_be_with_reload(:item1) do
    create(:work_item, project: project, discussion_locked: true, title: 'item1', labels: [label1])
  end

  let_it_be_with_reload(:item2) do
    create(
      :work_item,
      project: project,
      title: 'item2',
      last_edited_by: current_user,
      last_edited_at: 1.day.ago,
      labels: [label2],
      milestone: milestone1
    )
  end

  let_it_be_with_reload(:confidential_item) { create(:work_item, confidential: true, project: project, title: 'item3') }
  let_it_be(:other_item) { create(:work_item) }

  let(:items_data) { graphql_data['project']['workItems']['nodes'] }
  let(:item_filter_params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('workItems'.classify, max_depth: 2)}
      }
    QUERY
  end

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  shared_examples 'work items resolver without N + 1 queries' do
    it 'avoids N+1 queries', :use_sql_query_cache do
      post_graphql(query, current_user: current_user) # warm-up

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: current_user)
      end

      expect_graphql_errors_to_be_empty

      create_list(
        :work_item, 3,
        :task,
        :last_edited_by_user,
        last_edited_at: 1.week.ago,
        project: project,
        labels: [label1, label2],
        milestone: milestone2,
        author: reporter
      )

      expect { post_graphql(query, current_user: current_user) }.not_to exceed_all_query_limit(control)
      expect_graphql_errors_to_be_empty
    end
  end

  it_behaves_like 'graphql work item list request spec' do
    let_it_be(:container_build_params) { { project: project } }
    let(:work_item_node_path) { %w[project workItems nodes] }

    def post_query(request_user = current_user)
      post_graphql(query, current_user: request_user)
    end
  end

  describe 'N + 1 queries' do
    context 'when querying root fields' do
      it_behaves_like 'work items resolver without N + 1 queries'
    end

    # We need a separate example since all_graphql_fields_for will not fetch fields from types
    # that implement the widget interface. Only `type` for the widgets field.
    context 'when querying the widget interface' do
      let(:fields) do
        <<~GRAPHQL
          nodes {
            widgets {
              type
              ... on WorkItemWidgetDescription {
                edited
                lastEditedAt
                lastEditedBy {
                  webPath
                  username
                }
              }
              ... on WorkItemWidgetAssignees {
                assignees { nodes { id } }
              }
              ... on WorkItemWidgetHierarchy {
                parent { id }
                children {
                  nodes {
                    id
                  }
                }
              }
              ... on WorkItemWidgetLabels {
                labels { nodes { id } }
                allowsScopedLabels
              }
              ... on WorkItemWidgetMilestone {
                milestone {
                  id
                }
              }
            }
          }
        GRAPHQL
      end

      it_behaves_like 'work items resolver without N + 1 queries'
    end
  end

  context 'when querying WorkItemWidgetAssignees' do
    let(:work_items_data) { graphql_data['project']['workItems']['nodes'].pluck('widgets') }
    let(:widget_data) { work_items_data.map { |data| data.find { |widget| widget['type'] == 'ASSIGNEES' } } }
    let(:assignee_data) { widget_data.map { |data| data.dig('assignees', 'nodes') } }
    let(:assignees) do
      [
        create(:user, name: 'BBB'),
        create(:user, name: 'AAA'),
        create(:user, name: 'BBB')
      ]
    end

    let(:fields) do
      <<~GRAPHQL
        nodes {
          widgets {
            type
            ... on WorkItemWidgetAssignees {
              assignees { nodes { id } }
            }
          }
        }
      GRAPHQL
    end

    before do
      project.work_items.each { |work_item| work_item.update!(assignees: assignees) }
    end

    it 'returns assignees ordered by name ASC id DESC' do
      post_graphql(query, current_user: current_user)

      expect(assignee_data).to all(
        eq(
          [
            { 'id' => assignees[1].to_gid.to_s },
            { 'id' => assignees[2].to_gid.to_s },
            { 'id' => assignees[0].to_gid.to_s }
          ]
        )
      )
    end
  end

  context 'when querying WorkItemWidgetHierarchy' do
    let_it_be(:children) { create_list(:work_item, 4, :task, project: project) }
    let_it_be(:child_link1) { create(:parent_link, work_item_parent: item1, work_item: children[0]) }
    let_it_be(:child_link2) { create(:parent_link, work_item_parent: item1, work_item: children[1]) }

    let(:fields) do
      <<~GRAPHQL
        nodes {
          id
          widgets {
            type
            ... on WorkItemWidgetHierarchy {
              hasChildren
              parent { id }
              children { nodes { id } }
            }
          }
        }
      GRAPHQL
    end

    context 'with ordered children' do
      let(:items_data) { graphql_data['project']['workItems']['nodes'] }
      let(:work_item_data) { items_data.find { |item| item['id'] == item1.to_gid.to_s } }
      let(:work_item_widget) { work_item_data["widgets"].find { |widget| widget.key?("children") } }
      let(:children_ids) { work_item_widget.dig("children", "nodes").pluck("id") }

      let(:first_child) { children[0].to_gid.to_s }
      let(:second_child) { children[1].to_gid.to_s }

      it 'returns children ordered by created_at by default' do
        post_graphql(query, current_user: current_user)

        expect(children_ids).to eq([first_child, second_child])
      end

      context 'when ordered by relative position' do
        before do
          child_link1.update!(relative_position: 20)
          child_link2.update!(relative_position: 10)
        end

        it 'returns children in correct order' do
          post_graphql(query, current_user: current_user)

          expect(children_ids).to eq([second_child, first_child])
        end
      end
    end

    it 'executes limited number of N+1 queries' do
      post_graphql(query, current_user: current_user) # warm-up

      control = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: current_user)
      end

      parent_work_items = create_list(:work_item, 2, project: project)
      create(:parent_link, work_item_parent: parent_work_items[0], work_item: children[2])
      create(:parent_link, work_item_parent: parent_work_items[1], work_item: children[3])

      expect { post_graphql(query, current_user: current_user) }
        .not_to exceed_query_limit(control)
    end

    it 'avoids N+1 queries when children are added to a work item' do
      post_graphql(query, current_user: current_user) # warm-up

      control = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: current_user)
      end

      create(:parent_link, work_item_parent: item1, work_item: children[2])
      create(:parent_link, work_item_parent: item1, work_item: children[3])

      expect { post_graphql(query, current_user: current_user) }
        .not_to exceed_query_limit(control)
    end
  end

  context 'when querying WorkItemWidgetStartAndDueDate' do
    let(:fields) do
      <<~GRAPHQL
        nodes {
          widgets {
            type
            ... on WorkItemWidgetStartAndDueDate {
              dueDate
              startDate
            }
          }
        }
      GRAPHQL
    end

    it 'avoids N+1 queries when we create more work items' do
      post_graphql(query, current_user: current_user) # warm-up

      control = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: current_user)
      end

      create_list(:work_item, 3, project: project)

      expect { post_graphql(query, current_user: current_user) }
        .not_to exceed_query_limit(control)
    end
  end

  context 'when the user does not have access to the item' do
    before do
      project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
    end

    it 'returns an empty list' do
      post_graphql(query)

      expect(items_data).to eq([])
    end
  end

  it 'returns only items visible to user' do
    post_graphql(query, current_user: current_user)

    expect(item_ids).to eq([item2.to_global_id.to_s, item1.to_global_id.to_s])
  end

  context 'when the user can see confidential items' do
    before do
      project.add_developer(current_user)
    end

    it 'returns also confidential items' do
      post_graphql(query, current_user: current_user)

      expect(item_ids).to eq([confidential_item.to_global_id.to_s, item2.to_global_id.to_s, item1.to_global_id.to_s])
    end
  end

  context 'when filtering by search' do
    it_behaves_like 'query with a search term' do
      let(:ids) { item_ids }
      let(:user) { current_user }
      let_it_be(:issuable) { create(:work_item, project: project, description: 'bar') }
    end
  end

  context 'when filtering by subscribed' do
    let_it_be(:subscribed_item) { create(:work_item, project: project) }
    let_it_be(:unsubscribed_item) { create(:work_item, project: project) }
    let_it_be(:subscription) do
      create(:subscription, subscribable: subscribed_item, user: current_user, subscribed: true)
    end

    let_it_be(:unsubscription) do
      create(:subscription, subscribable: unsubscribed_item, user: current_user, subscribed: false)
    end

    it 'returns only subscribed items' do
      post_graphql(query(subscribed: :EXPLICITLY_SUBSCRIBED), current_user: current_user)

      expect(item_ids).to match_array([subscribed_item.to_global_id.to_s])
    end

    it 'returns only unsubscribed items' do
      post_graphql(query(subscribed: :EXPLICITLY_UNSUBSCRIBED), current_user: current_user)

      expect(item_ids).to match_array([unsubscribed_item.to_global_id.to_s])
    end

    it 'does not filter subscribed items' do
      post_graphql(query, current_user: current_user)

      expect(item_ids).to match_array([subscribed_item.to_global_id.to_s, unsubscribed_item.to_global_id.to_s,
        item1.to_global_id.to_s, item2.to_global_id.to_s])
    end
  end

  describe 'sorting and pagination' do
    let(:data_path) { [:project, :work_items] }

    def pagination_query(params)
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        query_graphql_field('workItems', params, "#{page_info} nodes { id }")
      )
    end

    before do
      project.add_developer(current_user)
    end

    context 'when sorting by title ascending' do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :TITLE_ASC }
        let(:first_param) { 2 }
        let(:all_records) { [item1, item2, confidential_item].map { |item| item.to_global_id.to_s } }
      end
    end

    context 'when sorting by title descending' do
      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :TITLE_DESC }
        let(:first_param) { 2 }
        let(:all_records) { [confidential_item, item2, item1].map { |item| item.to_global_id.to_s } }
      end
    end
  end

  context 'when fetching work item notifications widget' do
    let(:fields) do
      <<~GRAPHQL
        nodes {
          widgets {
            type
            ... on WorkItemWidgetNotifications {
              subscribed
            }
          }
        }
      GRAPHQL
    end

    it 'executes limited number of N+1 queries', :use_sql_query_cache do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: current_user)
      end

      create_list(:work_item, 3, project: project)

      # Performs 1 extra query per item to fetch subscriptions
      expect { post_graphql(query, current_user: current_user) }
        .not_to exceed_all_query_limit(control).with_threshold(3)
      expect_graphql_errors_to_be_empty
    end
  end

  context 'when fetching work item award emoji widget' do
    let(:fields) do
      <<~GRAPHQL
        nodes {
          widgets {
            type
            ... on WorkItemWidgetAwardEmoji {
              awardEmoji {
                nodes {
                  name
                  emoji
                  user { id }
                }
              }
              upvotes
              downvotes
            }
          }
        }
      GRAPHQL
    end

    before do
      create(:award_emoji, name: 'star', user: current_user, awardable: item1)
      create(:award_emoji, :upvote, awardable: item1)
      create(:award_emoji, :downvote, awardable: item1)
    end

    it 'executes limited number of N+1 queries', :use_sql_query_cache do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: current_user)
      end

      create_list(:work_item, 2, project: project) do |item|
        create(:award_emoji, name: 'rocket', awardable: item)
        create_list(:award_emoji, 2, :upvote, awardable: item)
        create_list(:award_emoji, 2, :downvote, awardable: item)
      end

      expect { post_graphql(query, current_user: current_user) }
        .not_to exceed_all_query_limit(control)
      expect_graphql_errors_to_be_empty
    end
  end

  context 'when fetching work item linked items widget' do
    let_it_be(:other_project) { create(:project, :repository, :public, group: group) }
    let_it_be(:other_milestone) { create(:milestone, project: other_project) }
    let_it_be(:related_items) { create_list(:work_item, 3, project: other_project, milestone: other_milestone) }

    let(:fields) do
      <<~GRAPHQL
        nodes {
          widgets {
            type
            ... on WorkItemWidgetLinkedItems {
              linkedItems {
                nodes {
                  linkId
                  linkType
                  linkCreatedAt
                  linkUpdatedAt
                  workItem {
                    id
                    widgets {
                      ... on WorkItemWidgetMilestone {
                        milestone {
                          id
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      GRAPHQL
    end

    before do
      create(:work_item_link, source: item1, target: related_items[0], link_type: 'relates_to')
      create(:work_item_link, source: item2, target: related_items[0], link_type: 'relates_to')
    end

    it 'executes limited number of N+1 queries', :use_sql_query_cache do
      post_graphql(query, current_user: current_user) # warm-up

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: current_user)
      end

      [item1, item2].each do |item|
        create(:work_item_link, source: item, target: related_items[1], link_type: 'relates_to')
        create(:work_item_link, source: item, target: related_items[2], link_type: 'relates_to')
      end

      expect_graphql_errors_to_be_empty
      expect { post_graphql(query, current_user: current_user) }
        .not_to exceed_all_query_limit(control)
    end
  end

  context 'when fetching work item participants widget' do
    let_it_be(:other_project) { create(:project, group: group) }
    let_it_be(:project) { other_project }
    let_it_be(:users) { create_list(:user, 3) }
    let_it_be(:work_items) { create_list(:work_item, 3, project: project, assignees: users) }

    let(:fields) do
      <<~GRAPHQL
        nodes {
          id
          widgets {
            type
            ... on WorkItemWidgetParticipants {
              participants {
                nodes {
                  id
                  username
                }
              }
            }
          }
        }
      GRAPHQL
    end

    before do
      project.add_guest(current_user)
    end

    it 'returns participants' do
      post_graphql(query, current_user: current_user)

      participants_usernames = graphql_dig_at(items_data, 'widgets', 'participants', 'nodes', 'username')
      expect(participants_usernames).to match_array(work_items.flat_map(&:participants).map(&:username))
    end

    it 'executes limited number of N+1 queries', :use_sql_query_cache do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        post_graphql(query, current_user: current_user)
      end

      create_list(:work_item, 2, project: project, assignees: users)

      expect_graphql_errors_to_be_empty
      expect { post_graphql(query, current_user: current_user) }.not_to exceed_all_query_limit(control)
    end
  end

  context 'with development widget' do
    context 'for closing merge requests field' do
      before do
        [item1, item2].each do |item|
          create(
            :merge_requests_closing_issues,
            issue: item,
            merge_request: create(:merge_request, source_project: project, target_branch: "feature#{item.id}")
          )
        end
      end

      let(:fields) do
        <<~GRAPHQL
          nodes {
            id
            widgets {
              type
              ... on WorkItemWidgetDevelopment {
                closingMergeRequests {
                  nodes {
                    id
                    fromMrDescription
                    mergeRequest { id }
                  }
                }
              }
            }
          }
        GRAPHQL
      end

      it 'avoids N+1 queries' do
        post_graphql(query, current_user: current_user) # warmup

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end
        expect(graphql_errors).to be_blank

        2.times do
          new_work_item = create(:work_item, project: project)
          create(
            :merge_requests_closing_issues,
            issue: new_work_item,
            merge_request: create(:merge_request, source_project: project, target_branch: "feature#{new_work_item.id}")
          )
        end

        expect { post_graphql(query, current_user: current_user) }.to issue_same_number_of_queries_as(control)
        expect(graphql_errors).to be_blank
      end
    end

    context 'for related merge requests field' do
      let(:fields) do
        <<~GRAPHQL
          nodes {
            id
            widgets {
              type
              ... on WorkItemWidgetDevelopment {
                relatedMergeRequests {
                  nodes {
                    id
                    iid
                  }
                }
              }
            }
          }
        GRAPHQL
      end

      it 'limits the field to 1 execution' do
        post_graphql(query, current_user: current_user)

        expect_graphql_errors_to_include(
          '"relatedMergeRequests" field can be requested only for 1 WorkItemWidgetDevelopment(s) at a time.'
        )
      end
    end

    context 'for related branches field' do
      let(:fields) do
        <<~GRAPHQL
          nodes {
            id
            widgets {
              type
              ... on WorkItemWidgetDevelopment {
                relatedBranches  {
                  nodes {
                    name
                    comparePath
                    pipelineStatus { name label favicon }
                  }
                }
              }
            }
          }
        GRAPHQL
      end

      it 'limits the field to 1 execution' do
        post_graphql(query, current_user: current_user)

        expect_graphql_errors_to_include(
          '"relatedBranches" field can be requested only for 1 WorkItemWidgetDevelopment(s) at a time.'
        )
      end
    end
  end

  describe 'filters' do
    before_all do
      project.add_developer(current_user)
    end

    let(:fields) do
      <<~QUERY
        nodes {
          id
        }
      QUERY
    end

    context 'when filtering by confidential' do
      let(:item_filter_params) { { confidential: true } }

      it 'returns only confidential items' do
        post_graphql(query, current_user: current_user)

        expect(item_ids).to contain_exactly(confidential_item.to_global_id.to_s)
      end
    end

    context 'when filtering by assignees' do
      before_all do
        IssueAssignee.create!(issue: item1, assignee: current_user)
        IssueAssignee.create!(issue: item2, assignee: reporter)
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      let(:item_filter_params) { { assignee_usernames: [current_user.username] } }

      it 'returns items assigned to the user' do
        expect(item_ids).to contain_exactly(item1.to_global_id.to_s)
      end

      context 'when using NOT' do
        let(:item_filter_params) { { not: { assignee_usernames: [current_user.username] } } }

        it 'returns items not assigned to the user' do
          expect(item_ids).to contain_exactly(item2.to_global_id.to_s, confidential_item.to_global_id.to_s)
        end
      end

      context 'when using OR' do
        let(:item_filter_params) { { or: { assignee_usernames: [current_user.username, reporter.username] } } }

        it 'returns items assigned to either user' do
          expect(item_ids).to contain_exactly(item1.to_global_id.to_s, item2.to_global_id.to_s)
        end
      end

      context 'when using a wildcard' do
        let(:item_filter_params) { { assignee_wildcard_id: :NONE } }

        it 'returns items without an assignee' do
          expect(item_ids).to contain_exactly(confidential_item.to_global_id.to_s)
        end
      end

      context 'when both assigneeUsernames and assigneeWildcardId are provided' do
        let(:item_filter_params) { { assignee_usernames: [current_user.username], assignee_wildcard_id: :NONE } }

        it 'returns an error' do
          expect_graphql_errors_to_include(
            'Only one of [assigneeUsernames, assigneeWildcardId] arguments is allowed at the same time.'
          )
        end
      end
    end

    context 'when filtering by author' do
      before_all do
        item1.update_columns(author_id: current_user.id)
        item2.update_columns(author_id: reporter.id)
        confidential_item.update_columns(author_id: create(:user).id)
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      let(:item_filter_params) { { author_username: current_user.username } }

      it 'returns items authored by the user' do
        expect(item_ids).to contain_exactly(item1.to_global_id.to_s)
      end

      context 'when using NOT' do
        let(:item_filter_params) { { not: { author_username: current_user.username } } }

        it 'returns items not authored by the user' do
          expect(item_ids).to contain_exactly(item2.to_global_id.to_s, confidential_item.to_global_id.to_s)
        end
      end

      context 'when using OR' do
        let(:item_filter_params) { { or: { author_usernames: [current_user.username, reporter.username] } } }

        it 'returns items authored by either user' do
          expect(item_ids).to contain_exactly(item1.to_global_id.to_s, item2.to_global_id.to_s)
        end
      end
    end

    context 'when filtering by label' do
      before do
        post_graphql(query, current_user: current_user)
      end

      let(:item_filter_params) { { label_name: label1.name } }

      it 'returns items with the label' do
        expect(item_ids).to contain_exactly(item1.to_global_id.to_s)
      end

      context 'when using NOT' do
        let(:item_filter_params) { { not: { label_name: label1.name } } }

        it 'returns items without the label' do
          expect(item_ids).to contain_exactly(item2.to_global_id.to_s, confidential_item.to_global_id.to_s)
        end
      end

      context 'when using OR' do
        let(:item_filter_params) { { or: { label_names: [label1.name, label2.name] } } }

        it 'returns items authored by either user' do
          expect(item_ids).to contain_exactly(item1.to_global_id.to_s, item2.to_global_id.to_s)
        end
      end
    end

    context 'when filtering by milestone' do
      before_all do
        item1.update_columns(milestone_id: milestone1.id)
        item2.update_columns(milestone_id: milestone2.id)
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      let(:item_filter_params) { { milestone_title: milestone1.title } }

      it 'returns items with the milestone' do
        expect(item_ids).to contain_exactly(item1.to_global_id.to_s)
      end

      context 'when using NOT' do
        let(:item_filter_params) { { not: { milestone_title: milestone1.title } } }

        it 'returns items without the milestone' do
          expect(item_ids).to contain_exactly(item2.to_global_id.to_s, confidential_item.to_global_id.to_s)
        end
      end

      context 'when using a wildcard' do
        let(:item_filter_params) { { milestone_wildcard_id: :NONE } }

        it 'returns items without a milestone' do
          expect(item_ids).to contain_exactly(confidential_item.to_global_id.to_s)
        end
      end

      context 'when both milestoneTitle and milestoneWildcardId are provided' do
        let(:item_filter_params) { { milestone_title: [milestone1.title], milestone_wildcard_id: :NONE } }

        it 'returns an error' do
          expect_graphql_errors_to_include(
            'Only one of [milestoneTitle, milestoneWildcardId] arguments is allowed at the same time.'
          )
        end
      end
    end

    context 'when filtering by reaction emoji' do
      before_all do
        create(:award_emoji, :upvote, user: current_user, awardable: item1)
        create(:award_emoji, :downvote, user: current_user, awardable: item2)
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      let(:item_filter_params) { { my_reaction_emoji: AwardEmoji::THUMBS_UP } }

      it 'returns items with the reaction emoji' do
        expect(item_ids).to contain_exactly(item1.to_global_id.to_s)
      end

      context 'when using NOT' do
        let(:item_filter_params) { { not: { my_reaction_emoji: AwardEmoji::THUMBS_UP } } }

        it 'returns items without the reaction emoji' do
          expect(item_ids).to contain_exactly(item2.to_global_id.to_s, confidential_item.to_global_id.to_s)
        end
      end
    end
  end

  def item_ids
    graphql_dig_at(items_data, :id)
  end

  def query(params = item_filter_params)
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('workItems', params, fields)
    )
  end
end
