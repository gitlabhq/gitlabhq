# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a work item list for a project', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:reporter) { create(:user).tap { |reporter| project.add_reporter(reporter) } }
  let_it_be(:label1) { create(:label, project: project) }
  let_it_be(:label2) { create(:label, project: project) }
  let_it_be(:milestone1) { create(:milestone, project: project) }
  let_it_be(:milestone2) { create(:milestone, project: project) }

  let_it_be(:item1) { create(:work_item, project: project, discussion_locked: true, title: 'item1', labels: [label1]) }
  let_it_be(:item2) do
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

  let_it_be(:confidential_item) { create(:work_item, confidential: true, project: project, title: 'item3') }
  let_it_be(:other_item) { create(:work_item) }

  let(:items_data) { graphql_data['project']['workItems']['edges'] }
  let(:item_filter_params) { {} }

  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('workItems'.classify, max_depth: 2)}
      }
    }
    QUERY
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

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
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
      let(:issuable_data) { items_data }
      let(:user) { current_user }
      let_it_be(:issuable) { create(:work_item, project: project, description: 'bar') }
    end
  end

  context 'when filtering by author username' do
    let_it_be(:author) { create(:author) }
    let_it_be(:item_3) { create(:work_item, project: project, author: author) }

    let(:item_filter_params) { { author_username: item_3.author.username } }

    it 'returns correct results' do
      post_graphql(query, current_user: current_user)

      expect(item_ids).to match_array([item_3.to_global_id.to_s])
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

  describe 'fetching work item notes widget' do
    let(:item_filter_params) { { iid: item2.iid.to_s } }
    let(:fields) do
      <<~GRAPHQL
        edges {
          node {
            widgets {
              type
              ... on WorkItemWidgetNotes {
                system: discussions(filter: ONLY_ACTIVITY, first: 10) { nodes { id  notes { nodes { id system internal body } } } },
                comments: discussions(filter: ONLY_COMMENTS, first: 10) { nodes { id  notes { nodes { id system internal body } } } },
                all_notes: discussions(filter: ALL_NOTES, first: 10) { nodes { id  notes { nodes { id system internal body } } } }
              }
            }
          }
        }
      GRAPHQL
    end

    before_all do
      create_notes(item1, "some note1")
      create_notes(item2, "some note2")
    end

    shared_examples 'fetches work item notes' do |user_comments_count:, system_notes_count:|
      it "fetches notes" do
        post_graphql(query, current_user: current_user)

        all_widgets = graphql_dig_at(items_data, :node, :widgets)
        notes_widget = all_widgets.find { |x| x["type"] == "NOTES" }

        all_notes = graphql_dig_at(notes_widget["all_notes"], :nodes)
        system_notes = graphql_dig_at(notes_widget["system"], :nodes)
        comments = graphql_dig_at(notes_widget["comments"], :nodes)

        expect(comments.count).to eq(user_comments_count)
        expect(system_notes.count).to eq(system_notes_count)
        expect(all_notes.count).to eq(user_comments_count + system_notes_count)
      end
    end

    context 'when user has permission to view internal notes' do
      before do
        project.add_developer(current_user)
      end

      it_behaves_like 'fetches work item notes', user_comments_count: 2, system_notes_count: 5
    end

    context 'when user cannot view internal notes' do
      it_behaves_like 'fetches work item notes', user_comments_count: 1, system_notes_count: 5
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

  def item_ids
    graphql_dig_at(items_data, :node, :id)
  end

  def query(params = item_filter_params)
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('workItems', params, fields)
    )
  end

  def create_notes(work_item, note_body)
    create(:note, system: true, project: work_item.project, noteable: work_item)

    disc_start = create(:discussion_note_on_issue, noteable: work_item, project: work_item.project, note: note_body)
    create(:note,
      discussion_id: disc_start.discussion_id, noteable: work_item,
      project: work_item.project, note: "reply on #{note_body}")

    create(:resource_label_event, user: current_user, issue: work_item, label: label1, action: 'add')
    create(:resource_label_event, user: current_user, issue: work_item, label: label1, action: 'remove')

    create(:resource_milestone_event, issue: work_item, milestone: milestone1, action: 'add')
    create(:resource_milestone_event, issue: work_item, milestone: milestone1, action: 'remove')

    # confidential notes are currently available only on issues and epics
    conf_disc_start = create(:discussion_note_on_issue, :confidential,
      noteable: work_item, project: work_item.project, note: "confidential #{note_body}")
    create(:note, :confidential,
      discussion_id: conf_disc_start.discussion_id, noteable: work_item,
      project: work_item.project, note: "reply on confidential #{note_body}")
  end
end
