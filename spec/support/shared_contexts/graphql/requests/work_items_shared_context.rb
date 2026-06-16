# frozen_string_literal: true

RSpec.shared_context 'with work items list request' do
  include GraphqlHelpers

  let_it_be(:group, freeze: false) { create(:group, :public) }
  let_it_be(:project, freeze: false) { create(:project, :repository, :public, group: group) }
  let_it_be(:user, freeze: false) { create(:user) }
  let_it_be(:reporter, freeze: false) { create(:user, reporter_of: [group, project]) }
  let_it_be(:current_user, freeze: false) { user }

  let(:item_filter_params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('workItems'.classify, max_depth: 2)}
      }
    QUERY
  end
end

RSpec.shared_context 'with work item request context' do
  include GraphqlHelpers

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, :repository, :private, group: group) }
  let_it_be(:developer, freeze: false) { create(:user, developer_of: group) }
  let_it_be(:guest, freeze: false) { create(:user, guest_of: group) }
  let_it_be(:start_date, freeze: false) { 5.days.ago }
  let_it_be(:due_date, freeze: false) { 5.days.from_now }
  let_it_be(:milestone, freeze: false) do
    create(:milestone, project: project, start_date: start_date, due_date: due_date)
  end

  let_it_be(:labels, freeze: false) { create_list(:group_label, 2, group: group) }
  let_it_be(:work_item, freeze: false) do
    create(
      :work_item,
      project: project,
      description: '- [x] List item',
      start_date: Time.zone.today,
      due_date: 1.week.from_now,
      created_at: 1.week.ago,
      last_edited_at: 1.day.ago,
      last_edited_by: guest,
      user_agent_detail: create(:user_agent_detail),
      milestone: milestone
    ).tap do |work_item|
      create_list(:discussion_note_on_issue, 3, noteable: work_item, project: project)
    end
  end

  let(:work_item_data) { graphql_data['workItem'] }
  let(:work_item_fields) { all_graphql_fields_for('WorkItem', max_depth: 2) }
  let(:global_id) { work_item.to_gid.to_s }

  let(:widget_fields) do
    <<~GRAPHQL
      id
      iid
      confidential
      workItemType {
        id
        name
        iconName
      }
      namespace {
        id
        fullPath
        name
      }
      title
      state
      createdAt
      closedAt
      webUrl
      webPath
      reference(full: true)
      widgets {
        ... on WorkItemWidgetHierarchy {
          type
          hasChildren
          hasParent
          depthLimitReachedByType {
            workItemType {
              id
              name
            }
            depthLimitReached
          }
          rolledUpCountsByType {
            countsByState {
              all
              closed
            }
            workItemType {
              id
              name
              iconName
            }
          }
        }
        type
        ... on WorkItemWidgetStartAndDueDate {
          dueDate
          startDate
        }
        ... on WorkItemWidgetMilestone {
          milestone {
            expired
            id
            title
            state
            startDate
            dueDate
            webPath
            projectMilestone
          }
        }
        ... on WorkItemWidgetAssignees {
          allowsMultipleAssignees
          canInviteMembers
          assignees {
            nodes {
              ... on User {
                id
                avatarUrl
                name
                username
                webUrl
                webPath
              }
            }
          }
        }
        ... on WorkItemWidgetLabels {
          allowsScopedLabels
          labels {
            nodes {
              id
              title
              description
              color
              textColor
            }
          }
        }
      }
    GRAPHQL
  end

  let(:query) do
    graphql_query_for('workItem', { 'id' => global_id }, work_item_fields)
  end

  def add_child_task(parent, project, args = {})
    options = { project: project, work_item_parent: parent, assignees: [guest] }
    options.merge!(args)

    create(:work_item, :task, options).tap do |child|
      create(:work_items_dates_source, work_item: child, due_date: due_date, start_date: start_date)
    end
  end
end
