# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.work_item(id)', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:work_item) do
    create(
      :work_item,
      project: project,
      description: '- List item',
      start_date: Date.today,
      due_date: 1.week.from_now,
      created_at: 1.week.ago,
      last_edited_at: 1.day.ago,
      last_edited_by: guest
    )
  end

  let_it_be(:child_item1) { create(:work_item, :task, project: project) }
  let_it_be(:child_item2) { create(:work_item, :task, confidential: true, project: project) }
  let_it_be(:child_link1) { create(:parent_link, work_item_parent: work_item, work_item: child_item1) }
  let_it_be(:child_link2) { create(:parent_link, work_item_parent: work_item, work_item: child_item2) }

  let(:current_user) { developer }
  let(:work_item_data) { graphql_data['workItem'] }
  let(:work_item_fields) { all_graphql_fields_for('WorkItem', max_depth: 2) }
  let(:global_id) { work_item.to_gid.to_s }

  let(:query) do
    graphql_query_for('workItem', { 'id' => global_id }, work_item_fields)
  end

  context 'when the user can read the work item' do
    let(:incoming_email_token) { current_user.incoming_email_token }
    let(:work_item_email) do
      "p+#{project.full_path_slug}-#{project.project_id}-#{incoming_email_token}-issue-#{work_item.iid}@gl.ab"
    end

    before do
      project.add_developer(developer)
      project.add_guest(guest)
      stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")

      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns all fields' do
      expect(work_item_data).to include(
        'description' => work_item.description,
        'id' => work_item.to_gid.to_s,
        'iid' => work_item.iid.to_s,
        'lockVersion' => work_item.lock_version,
        'state' => "OPEN",
        'title' => work_item.title,
        'confidential' => work_item.confidential,
        'workItemType' => hash_including('id' => work_item.work_item_type.to_gid.to_s),
        'reference' => work_item.to_reference,
        'createNoteEmail' => work_item_email,
        'userPermissions' => {
          'readWorkItem' => true,
          'updateWorkItem' => true,
          'deleteWorkItem' => false,
          'adminWorkItem' => true,
          'adminParentLink' => true,
          'setWorkItemMetadata' => true,
          'createNote' => true
        },
        'project' => hash_including('id' => project.to_gid.to_s, 'fullPath' => project.full_path)
      )
    end

    context 'when querying widgets' do
      describe 'description widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetDescription {
                description
                descriptionHtml
                edited
                lastEditedBy {
                  webPath
                  username
                }
                lastEditedAt
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'DESCRIPTION',
                'description' => work_item.description,
                'descriptionHtml' => ::MarkupHelper.markdown_field(work_item, :description, {}),
                'edited' => true,
                'lastEditedAt' => work_item.last_edited_at.iso8601,
                'lastEditedBy' => {
                  'webPath' => "/#{guest.full_path}",
                  'username' => guest.username
                }
              )
            )
          )
        end
      end

      describe 'hierarchy widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetHierarchy {
                parent {
                  id
                }
                children {
                  nodes {
                    id
                  }
                }
                hasChildren
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'HIERARCHY',
                'parent' => nil,
                'children' => { 'nodes' => match_array(
                  [
                    hash_including('id' => child_link1.work_item.to_gid.to_s),
                    hash_including('id' => child_link2.work_item.to_gid.to_s)
                  ]) },
                'hasChildren' => true
              )
            )
          )
        end

        it 'avoids N+1 queries' do
          post_graphql(query, current_user: current_user) # warm up

          control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            post_graphql(query, current_user: current_user)
          end

          create_list(:parent_link, 3, work_item_parent: work_item)

          expect do
            post_graphql(query, current_user: current_user)
          end.not_to exceed_all_query_limit(control_count)
        end

        context 'when user is guest' do
          let(:current_user) { guest }

          it 'filters out not accessible children or parent' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'HIERARCHY',
                  'parent' => nil,
                  'children' => { 'nodes' => match_array(
                    [
                      hash_including('id' => child_link1.work_item.to_gid.to_s)
                    ]) },
                  'hasChildren' => true
                )
              )
            )
          end
        end

        context 'when requesting child item' do
          let_it_be(:work_item) { create(:work_item, :task, project: project, description: '- List item') }
          let_it_be(:parent_link) { create(:parent_link, work_item: work_item) }

          it 'returns parent information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'HIERARCHY',
                  'parent' => hash_including('id' => parent_link.work_item_parent.to_gid.to_s),
                  'children' => { 'nodes' => match_array([]) },
                  'hasChildren' => false
                )
              )
            )
          end
        end

        context 'when ordered by default by created_at' do
          let_it_be(:newest_child) { create(:work_item, :task, project: project, created_at: 5.minutes.from_now) }
          let_it_be(:oldest_child) { create(:work_item, :task, project: project, created_at: 5.minutes.ago) }
          let_it_be(:newest_link) { create(:parent_link, work_item_parent: work_item, work_item: newest_child) }
          let_it_be(:oldest_link) { create(:parent_link, work_item_parent: work_item, work_item: oldest_child) }

          let(:hierarchy_widget) { work_item_data['widgets'].find { |widget| widget['type'] == 'HIERARCHY' } }
          let(:hierarchy_children) { hierarchy_widget['children']['nodes'] }

          it 'places the oldest child item to the beginning of the children list' do
            expect(hierarchy_children.first['id']).to eq(oldest_child.to_gid.to_s)
          end

          it 'places the newest child item to the end of the children list' do
            expect(hierarchy_children.last['id']).to eq(newest_child.to_gid.to_s)
          end

          context 'when relative position is set' do
            let_it_be(:first_child) { create(:work_item, :task, project: project, created_at: 5.minutes.from_now) }

            let_it_be(:first_link) do
              create(:parent_link, work_item_parent: work_item, work_item: first_child, relative_position: 1)
            end

            it 'places children according to relative_position at the beginning of the children list' do
              ordered_list = [first_child, oldest_child, child_item1, child_item2, newest_child]

              expect(hierarchy_children.pluck('id')).to eq(ordered_list.map(&:to_gid).map(&:to_s))
            end
          end
        end
      end

      describe 'assignees widget' do
        let(:assignees) { create_list(:user, 2) }
        let(:work_item) { create(:work_item, project: project, assignees: assignees) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetAssignees {
                allowsMultipleAssignees
                canInviteMembers
                assignees {
                  nodes {
                    id
                    username
                  }
                }
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'ASSIGNEES',
                'allowsMultipleAssignees' => boolean,
                'canInviteMembers' => boolean,
                'assignees' => {
                  'nodes' => match_array(
                    assignees.map { |a| { 'id' => a.to_gid.to_s, 'username' => a.username } }
                  )
                }
              )
            )
          )
        end
      end

      describe 'labels widget' do
        let(:labels) { create_list(:label, 2, project: project) }
        let(:work_item) { create(:work_item, project: project, labels: labels) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetLabels {
                labels {
                  nodes {
                    id
                    title
                  }
                }
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'LABELS',
                'labels' => {
                  'nodes' => match_array(
                    labels.map { |a| { 'id' => a.to_gid.to_s, 'title' => a.title } }
                  )
                }
              )
            )
          )
        end
      end

      describe 'start and due date widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetStartAndDueDate {
                startDate
                dueDate
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'START_AND_DUE_DATE',
                'startDate' => work_item.start_date.to_s,
                'dueDate' => work_item.due_date.to_s
              )
            )
          )
        end
      end

      describe 'milestone widget' do
        let_it_be(:milestone) { create(:milestone, project: project) }

        let(:work_item) { create(:work_item, project: project, milestone: milestone) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetMilestone {
                milestone {
                  id
                }
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'MILESTONE',
                'milestone' => {
                  'id' => work_item.milestone.to_gid.to_s
                }
              )
            )
          )
        end
      end

      describe 'notifications widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetNotifications {
                subscribed
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'NOTIFICATIONS',
                'subscribed' => work_item.subscribed?(current_user, project)
              )
            )
          )
        end
      end

      describe 'currentUserTodos widget' do
        let_it_be(:current_user) { developer }
        let_it_be(:other_todo) { create(:todo, state: :pending, user: current_user) }

        let_it_be(:done_todo) do
          create(:todo, state: :done, target: work_item, target_type: work_item.class.name, user: current_user)
        end

        let_it_be(:pending_todo) do
          create(:todo, state: :pending, target: work_item, target_type: work_item.class.name, user: current_user)
        end

        let_it_be(:other_user_todo) do
          create(:todo, state: :pending, target: work_item, target_type: work_item.class.name, user: create(:user))
        end

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetCurrentUserTodos {
                currentUserTodos {
                  nodes {
                    id
                    state
                  }
                }
              }
            }
          GRAPHQL
        end

        context 'with access' do
          it 'returns widget information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'CURRENT_USER_TODOS',
                  'currentUserTodos' => {
                    'nodes' => match_array(
                      [done_todo, pending_todo].map { |t| { 'id' => t.to_gid.to_s, 'state' => t.state } }
                    )
                  }
                )
              )
            )
          end
        end

        context 'with filter' do
          let(:work_item_fields) do
            <<~GRAPHQL
              id
              widgets {
                type
                ... on WorkItemWidgetCurrentUserTodos {
                  currentUserTodos(state: done) {
                    nodes {
                      id
                      state
                    }
                  }
                }
              }
            GRAPHQL
          end

          it 'returns widget information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'CURRENT_USER_TODOS',
                  'currentUserTodos' => {
                    'nodes' => match_array(
                      [done_todo].map { |t| { 'id' => t.to_gid.to_s, 'state' => t.state } }
                    )
                  }
                )
              )
            )
          end
        end
      end

      describe 'award emoji widget' do
        let_it_be(:emoji) { create(:award_emoji, name: 'star', awardable: work_item) }
        let_it_be(:upvote) { create(:award_emoji, :upvote, awardable: work_item) }
        let_it_be(:downvote) { create(:award_emoji, :downvote, awardable: work_item) }

        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetAwardEmoji {
                upvotes
                downvotes
                awardEmoji {
                  nodes {
                    name
                  }
                }
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'id' => work_item.to_gid.to_s,
            'widgets' => include(
              hash_including(
                'type' => 'AWARD_EMOJI',
                'upvotes' => work_item.upvotes,
                'downvotes' => work_item.downvotes,
                'awardEmoji' => {
                  'nodes' => match_array(
                    [emoji, upvote, downvote].map { |e| { 'name' => e.name } }
                  )
                }
              )
            )
          )
        end
      end

      describe 'linked items widget' do
        let_it_be(:related_item) { create(:work_item, project: project) }
        let_it_be(:blocked_item) { create(:work_item, project: project) }
        let_it_be(:link1) { create(:work_item_link, source: work_item, target: related_item, link_type: 'relates_to') }
        let_it_be(:link2) { create(:work_item_link, source: work_item, target: blocked_item, link_type: 'blocks') }
        let(:work_item_fields) do
          <<~GRAPHQL
            id
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
                    }
                  }
                }
              }
            }
          GRAPHQL
        end

        it 'returns widget information' do
          expect(work_item_data).to include(
            'widgets' => include(
              hash_including(
                'type' => 'LINKED_ITEMS',
                'linkedItems' => { 'nodes' => match_array(
                  [
                    hash_including(
                      'linkId' => link1.to_gid.to_s, 'linkType' => 'relates_to',
                      'linkCreatedAt' => link1.created_at.iso8601, 'linkUpdatedAt' => link1.updated_at.iso8601,
                      'workItem' => { 'id' => related_item.to_gid.to_s }
                    ),
                    hash_including(
                      'linkId' => link2.to_gid.to_s, 'linkType' => 'blocks',
                      'linkCreatedAt' => link2.created_at.iso8601, 'linkUpdatedAt' => link2.updated_at.iso8601,
                      'workItem' => { 'id' => blocked_item.to_gid.to_s }
                    )
                  ]
                ) }
              )
            )
          )
        end

        context 'when filtering by link type' do
          let(:work_item_fields) do
            <<~GRAPHQL
              widgets {
                type
                ... on WorkItemWidgetLinkedItems {
                  linkedItems(filter: RELATED) {
                    nodes {
                      linkType
                    }
                  }
                }
              }
            GRAPHQL
          end

          it 'returns items with specified type' do
            widget_data = work_item_data["widgets"].find { |widget| widget.key?("linkedItems") }["linkedItems"]

            expect(widget_data["nodes"].size).to eq(1)
            expect(widget_data.dig("nodes", 0, "linkType")).to eq('relates_to')
          end
        end

        context 'when `linked_work_items` feature flag is disabled' do
          before do
            stub_feature_flags(linked_work_items: false)
            post_graphql(query, current_user: current_user)
          end

          it 'returns empty result' do
            expect(work_item_data).to include(
              'widgets' => include(
                hash_including(
                  'type' => 'LINKED_ITEMS',
                  'linkedItems' => { "nodes" => [] }
                )
              )
            )
          end
        end
      end
    end

    describe 'notes widget' do
      let(:work_item_fields) do
        <<~GRAPHQL
          id
          widgets {
            type
            ... on WorkItemWidgetNotes {
              system: discussions(filter: ONLY_ACTIVITY, first: 10) { nodes { id  notes { nodes { id system internal body } } } },
              comments: discussions(filter: ONLY_COMMENTS, first: 10) { nodes { id  notes { nodes { id system internal body } } } },
              all_notes: discussions(filter: ALL_NOTES, first: 10) { nodes { id  notes { nodes { id system internal body } } } }
            }
          }
        GRAPHQL
      end

      context 'when fetching award emoji from notes' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetNotes {
                discussions(filter: ONLY_COMMENTS, first: 10) {
                  nodes {
                    id
                    notes {
                      nodes {
                        id
                        body
                        maxAccessLevelOfAuthor
                        authorIsContributor
                        awardEmoji {
                          nodes {
                            name
                            user {
                              name
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

        let_it_be(:note) { create(:note, project: work_item.project, noteable: work_item) }

        before_all do
          create(:award_emoji, awardable: note, name: 'rocket', user: developer)
        end

        it 'returns award emoji data' do
          all_widgets = graphql_dig_at(work_item_data, :widgets)
          notes_widget = all_widgets.find { |x| x['type'] == 'NOTES' }
          notes = graphql_dig_at(notes_widget['discussions'], :nodes).flat_map { |d| d['notes']['nodes'] }

          note_with_emoji = notes.find { |n| n['id'] == note.to_gid.to_s }

          expect(note_with_emoji).to include(
            'awardEmoji' => {
              'nodes' => include(
                hash_including(
                  'name' => 'rocket',
                  'user' => {
                    'name' => developer.name
                  }
                )
              )
            }
          )
        end

        it 'returns author contributor status and max access level' do
          all_widgets = graphql_dig_at(work_item_data, :widgets)
          notes_widget = all_widgets.find { |x| x['type'] == 'NOTES' }
          notes = graphql_dig_at(notes_widget['discussions'], :nodes).flat_map { |d| d['notes']['nodes'] }

          expect(notes).to contain_exactly(
            hash_including('maxAccessLevelOfAuthor' => 'Owner', 'authorIsContributor' => false)
          )
        end

        it 'avoids N+1 queries' do
          another_user = create(:user).tap { |u| note.resource_parent.add_developer(u) }
          create(:note, project: note.project, noteable: work_item, author: another_user)

          post_graphql(query, current_user: developer)

          control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: developer) }

          expect_graphql_errors_to_be_empty

          another_note = create(:note, project: work_item.project, noteable: work_item)
          create(:award_emoji, awardable: another_note, name: 'star', user: guest)
          another_user = create(:user).tap { |u| note.resource_parent.add_developer(u) }
          note_with_different_user = create(:note, project: note.project, noteable: work_item, author: another_user)
          create(:award_emoji, awardable: note_with_different_user, name: 'star', user: developer)

          # TODO: Fix existing N+1 queries in https://gitlab.com/gitlab-org/gitlab/-/issues/414747
          expect { post_graphql(query, current_user: developer) }.not_to exceed_query_limit(control).with_threshold(3)
          expect_graphql_errors_to_be_empty
        end
      end
    end

    context 'when an Issue Global ID is provided' do
      let(:global_id) { Issue.find(work_item.id).to_gid.to_s }

      it 'allows an Issue GID as input' do
        expect(work_item_data).to include('id' => work_item.to_gid.to_s)
      end
    end
  end

  context 'when the user can not read the work item' do
    let(:current_user) { create(:user) }

    before do
      post_graphql(query)
    end

    it 'returns an access error' do
      expect(work_item_data).to be_nil
      expect(graphql_errors).to contain_exactly(
        hash_including('message' => ::Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      )
    end
  end

  context 'when the user cannot set work item metadata' do
    let(:current_user) { guest }

    before do
      project.add_guest(guest)
      post_graphql(query, current_user: current_user)
    end

    it 'returns correct user permission' do
      expect(work_item_data).to include(
        'id' => work_item.to_gid.to_s,
        'userPermissions' =>
          hash_including(
            'setWorkItemMetadata' => false
          )
      )
    end
  end
end
