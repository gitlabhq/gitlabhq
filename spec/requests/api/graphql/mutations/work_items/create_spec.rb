# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a work item', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }

  let(:work_item_create_type) { WorkItems::Type.default_by_type(:task) }
  let(:work_item_type_gid) { work_item_create_type.to_gid }
  let(:input) do
    {
      'title' => 'new title',
      'description' => 'new description',
      'confidential' => true,
      'workItemTypeId' => work_item_type_gid.to_s
    }
  end

  let(:fields) { nil }
  let(:mutation_response) { graphql_mutation_response(:work_item_create) }
  let(:current_user) { developer }

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  RSpec.shared_examples 'creates work item' do
    it 'creates the work item' do
      expect(work_item_type_gid.model_id.to_i).to eq(work_item_create_type.correct_id)

      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .to change { WorkItem.count }.by(1)

      created_work_item = WorkItem.last
      expect(response).to have_gitlab_http_status(:success)
      expect(created_work_item).to be_confidential
      expect(created_work_item.work_item_type.base_type).to eq('task')
      expect(mutation_response['workItem']).to include(
        input.except('workItemTypeId').merge(
          'id' => created_work_item.to_gid.to_s,
          'workItemType' => hash_including('name' => 'Task')
        )
      )
    end

    context 'when an old ID is used' do
      let(:work_item_type_gid) do
        ::Gitlab::GlobalId.build(work_item_create_type, id: work_item_create_type.old_id).to_s
      end

      it 'converts the work item' do
        expect(work_item_create_type.old_id).not_to eq(work_item_create_type.correct_id)

        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { WorkItem.count }.by(1)

        created_work_item = WorkItem.last
        expect(response).to have_gitlab_http_status(:success)
        expect(created_work_item.work_item_type).to eq(work_item_create_type)
        expect(mutation_response['workItem']).to include(
          input.except('workItemTypeId').merge(
            'id' => created_work_item.to_gid.to_s,
            'workItemType' => hash_including('name' => 'Task')
          )
        )
      end
    end

    context 'when input is invalid' do
      let(:input) { { 'title' => '', 'workItemTypeId' => WorkItems::Type.default_by_type(:task).to_gid.to_s } }

      it 'does not create and returns validation errors' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to not_change(WorkItem, :count)

        expect(graphql_mutation_response(:work_item_create)['errors']).to contain_exactly("Title can't be blank")
      end
    end

    it_behaves_like 'has spam protection' do
      let(:mutation_class) { ::Mutations::WorkItems::Create }
    end

    context 'with description widget input' do
      let(:input) do
        {
          title: 'title',
          workItemTypeId: WorkItems::Type.default_by_type(:task).to_gid.to_s,
          descriptionWidget: { description: 'some description' }
        }
      end

      let(:widgets_response) { mutation_response['workItem']['widgets'] }
      let(:fields) do
        <<~FIELDS
        workItem {
          widgets {
            type
            ... on WorkItemWidgetDescription {
              description
              lastEditedAt
              lastEditedBy {
                id
              }
            }
          }
        }
        errors
        FIELDS
      end

      it 'sets the description but does not set last_edited_at and last_edited_by' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(widgets_response).to include(
          {
            'type' => 'DESCRIPTION',
            'description' => 'some description',
            'lastEditedAt' => nil,
            'lastEditedBy' => nil
          }
        )
      end
    end

    context 'with hierarchy widget input' do
      let(:widgets_response) { mutation_response['workItem']['widgets'] }
      let(:fields) do
        <<~FIELDS
        workItem {
          widgets {
            type
            ... on WorkItemWidgetHierarchy {
              parent {
                id
              }
              children {
                edges {
                  node {
                    id
                  }
                }
              }
            }
          }
        }
        errors
        FIELDS
      end

      context 'when setting parent' do
        let_it_be(:parent) { create(:work_item, **container_params) }

        let(:input) do
          {
            title: 'item1',
            workItemTypeId: WorkItems::Type.default_by_type(:task).to_gid.to_s,
            hierarchyWidget: { 'parentId' => parent.to_gid.to_s }
          }
        end

        it 'updates the work item parent' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expect(widgets_response).to include(
            {
              'children' => { 'edges' => [] },
              'parent' => { 'id' => parent.to_gid.to_s },
              'type' => 'HIERARCHY'
            }
          )
        end

        context 'when parent work item type is invalid' do
          let_it_be(:parent) { create(:work_item, :task, **container_params) }

          it 'returns error' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(mutation_response['errors'])
              .to contain_exactly(/cannot be added: it's not allowed to add this type of parent item/)
            expect(mutation_response['workItem']).to be_nil
          end
        end

        context 'when parent work item is not found' do
          let_it_be(:parent) { build_stubbed(:work_item, id: non_existing_record_id) }

          it 'returns a top level error' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(graphql_errors.first['message']).to include('No object found for `parentId')
          end
        end

        context 'when adjacent is already in place' do
          let_it_be(:adjacent) { create(:work_item, :task, **container_params) }

          let(:work_item) { WorkItem.last }

          let(:input) do
            {
              title: 'item1',
              workItemTypeId: WorkItems::Type.default_by_type(:task).to_gid.to_s,
              hierarchyWidget: { 'parentId' => parent.to_gid.to_s }
            }
          end

          before_all do
            create(:parent_link, work_item_parent: parent, work_item: adjacent, relative_position: 0)
          end

          it 'creates work item and sets the relative position to be BEFORE adjacent' do
            expect { post_graphql_mutation(mutation, current_user: current_user) }
              .to change { WorkItem.count }.by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(widgets_response).to include(
              {
                'children' => { 'edges' => [] },
                'parent' => { 'id' => parent.to_gid.to_s },
                'type' => 'HIERARCHY'
              }
            )
            expect(work_item.parent_link.relative_position).to be < adjacent.parent_link.relative_position
          end
        end
      end

      context 'when unsupported widget input is sent' do
        let(:input) do
          {
            'title' => 'new title',
            'description' => 'new description',
            'workItemTypeId' => WorkItems::Type.default_by_type(:test_case).to_gid.to_s,
            'hierarchyWidget' => {}
          }
        end

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ['Following widget keys are not supported by Test Case type: [:hierarchy_widget]']
      end
    end

    context 'with milestone widget input' do
      let(:widgets_response) { mutation_response['workItem']['widgets'] }
      let(:fields) do
        <<~FIELDS
        workItem {
          widgets {
            type
            ... on WorkItemWidgetMilestone {
              milestone {
                id
              }
            }
          }
        }
        errors
        FIELDS
      end

      context 'when setting milestone on work item creation' do
        let_it_be(:project_milestone) { create(:milestone, project: project) }
        let_it_be(:group_milestone) { create(:milestone, group: group) }

        let(:input) do
          {
            title: 'some WI',
            workItemTypeId: WorkItems::Type.default_by_type(:task).to_gid.to_s,
            milestoneWidget: { 'milestoneId' => milestone.to_gid.to_s }
          }
        end

        shared_examples "work item's milestone is set" do
          it "sets the work item's milestone" do
            expect { post_graphql_mutation(mutation, current_user: current_user) }
              .to change { WorkItem.count }.by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(widgets_response).to include(
              {
                'type' => 'MILESTONE',
                'milestone' => { 'id' => milestone.to_gid.to_s }
              }
            )
          end
        end

        context 'when assigning a project milestone' do
          before do
            group_work_item = container_params[:namespace].present?
            skip('cannot set a project level milestone to a group level work item') if group_work_item
          end

          it_behaves_like "work item's milestone is set" do
            let(:milestone) { project_milestone }
          end
        end

        context 'when assigning a group milestone' do
          it_behaves_like "work item's milestone is set" do
            let(:milestone) { group_milestone }
          end
        end
      end
    end

    context 'with assignee widget input' do
      let(:widgets_response) { mutation_response['workItem']['widgets'] }
      let(:fields) do
        <<~FIELDS
          workItem {
            widgets {
              type
              ... on WorkItemWidgetAssignees {
                assignees {
                  nodes {
                    id
                    username
                  }
                }
              }
            }
          }
          errors
        FIELDS
      end

      context 'when setting assignee on work item creation' do
        let_it_be(:assignee) { create(:user, developer_of: project) }

        let(:input) do
          {
            title: 'some WI',
            workItemTypeId: WorkItems::Type.default_by_type(:task).to_gid.to_s,
            assigneesWidget: { 'assigneeIds' => assignee.to_gid.to_s }
          }
        end

        it "sets the work item's assignee" do
          expect { post_graphql_mutation(mutation, current_user: current_user) }
            .to change { WorkItem.count }.by(1)

          expect(response).to have_gitlab_http_status(:success)
          expect(widgets_response).to include(
            {
              'assignees' => { 'nodes' => [{ 'id' => assignee.to_gid.to_s, 'username' => assignee.username }] },
              'type' => 'ASSIGNEES'
            }
          )
        end
      end
    end

    context 'with labels widget input' do
      let(:widgets_response) { mutation_response['workItem']['widgets'] }
      let(:fields) do
        <<~FIELDS
          workItem {
            widgets {
              type
              ... on WorkItemWidgetLabels {
                labels {
                  nodes { id }
                }
              }
            }
          }
          errors
        FIELDS
      end

      context 'when setting labels on work item creation' do
        let_it_be(:label1) { create(:group_label, group: group) }
        let_it_be(:label2) { create(:group_label, group: group) }
        let(:label_ids) { [label1.to_gid.to_s, label2.to_gid.to_s] }

        let(:input) do
          {
            title: 'some WI',
            workItemTypeId: WorkItems::Type.default_by_type(:task).to_gid.to_s,
            labelsWidget: { labelIds: label_ids }
          }
        end

        it "sets the work item's labels" do
          expect { post_graphql_mutation(mutation, current_user: current_user) }
            .to change { WorkItem.count }.by(1)

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['workItem']['widgets']).to include(
            'labels' => {
              'nodes' => containing_exactly(
                hash_including('id' => label_ids.first.to_s),
                hash_including('id' => label_ids.second.to_s)
              )
            },
            'type' => 'LABELS'
          )
        end
      end
    end

    context 'with linked items widget input' do
      let_it_be(:item1_global_id) { create(:work_item, :task, project: project).to_global_id.to_s }
      let_it_be(:item2_global_id) { create(:work_item, :task, project: project).to_global_id.to_s }

      let(:widgets_response) { mutation_response['workItem']['widgets'] }

      let(:fields) do
        <<~FIELDS
        workItem {
          widgets {
            type
            ... on WorkItemWidgetLinkedItems {
              linkedItems {
                nodes {
                  linkType
                  workItem { id }
                }
              }
            }
          }
        }
        errors
        FIELDS
      end

      let(:input) do
        {
          title: 'item1',
          workItemTypeId: WorkItems::Type.default_by_type(:task).to_gid.to_s,
          linkedItemsWidget: { 'workItemsIds' => [item1_global_id, item2_global_id], 'linkType' => 'RELATED' }
        }
      end

      it 'creates work item with related items' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { WorkItem.count }.by(1)
          .and change { WorkItems::RelatedWorkItemLink.count }.by(2)

        # We don't control the order in which links are created and we don't need to.
        # Because of that, we can't control the order of the returned linked items. But we do want to assert they are
        # ordered by `"issue_links"."id" DESC` when fetched from the API
        expected_ordered_linked_items = WorkItems::RelatedWorkItemLink.order(id: :desc).limit(2).map do |linked_item|
          { 'linkType' => 'relates_to', "workItem" => { "id" => linked_item.target.to_gid.to_s } }
        end

        expect(response).to have_gitlab_http_status(:success)
        expect(widgets_response).to include(
          {
            'linkedItems' => { 'nodes' => expected_ordered_linked_items },
            'type' => 'LINKED_ITEMS'
          }
        )
      end

      context 'when number of items exceeds maximum allowed' do
        before do
          stub_const('Types::WorkItems::Widgets::LinkedItemsCreateInputType::MAX_WORK_ITEMS', 1)
        end

        it_behaves_like 'a mutation that returns top-level errors',
          errors: [Types::WorkItems::Widgets::LinkedItemsCreateInputType::ERROR_MESSAGE]
      end

      context 'with invalid items' do
        let_it_be(:private_project) { create(:project, :private) }
        let_it_be(:item1_global_id) { create(:work_item, :task, project: private_project).to_global_id.to_s }
        let_it_be(:item2_global_id) { create(:work_item, :task, project: private_project).to_global_id.to_s }

        it 'creates the work item without linking items' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }
            .to change { WorkItem.count }.by(1)
            .and not_change { WorkItems::RelatedWorkItemLink.count }

          expect(mutation_response['errors']).to contain_exactly(
            'No matching work item found. Make sure you are adding a valid ID and you have access to the item.'
          )
        end
      end
    end

    context 'with due and start date widget input', :freeze_time do
      let(:start_date) { Date.today }
      let(:due_date) { 1.week.from_now.to_date }
      let(:fields) do
        <<~FIELDS
          workItem {
            widgets {
              type
              ... on WorkItemWidgetStartAndDueDate {
                startDate
                dueDate
              }
              ... on WorkItemWidgetDescription {
                description
              }
            }
          }
          errors
        FIELDS
      end

      let(:input) do
        {
          'title' => 'new title',
          'description' => 'new description',
          'confidential' => true,
          'workItemTypeId' => WorkItems::Type.default_by_type(:task).to_gid.to_s,
          'startAndDueDateWidget' => {
            'startDate' => start_date.to_s,
            'dueDate' => due_date.to_s
          }
        }
      end

      it 'updates start and due date' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { WorkItem.count }.by(1)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['workItem']['widgets']).to include(
          {
            'startDate' => start_date.to_s,
            'dueDate' => due_date.to_s,
            'type' => 'START_AND_DUE_DATE'
          }
        )
      end
    end
  end

  context 'when the user is not allowed to create a work item' do
    let(:current_user) { create(:user) }
    let(:mutation) { graphql_mutation(:workItemCreate, input.merge('projectPath' => project.full_path), fields) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to create a work item' do
    context 'when creating work items in a project' do
      context 'with projectPath' do
        let_it_be(:container_params) { { project: project } }
        let(:mutation) { graphql_mutation(:workItemCreate, input.merge('projectPath' => project.full_path), fields) }

        it_behaves_like 'creates work item'
      end

      context 'with namespacePath' do
        let_it_be(:container_params) { { project: project } }
        let(:mutation) { graphql_mutation(:workItemCreate, input.merge('namespacePath' => project.full_path), fields) }

        it_behaves_like 'creates work item'

        context 'when the namespace_level_work_items feature flag is disabled' do
          before do
            stub_feature_flags(namespace_level_work_items: false)
          end

          it_behaves_like 'creates work item'
        end
      end
    end

    context 'when creating work items in a group' do
      let_it_be(:container_params) { { namespace: group } }
      let(:mutation) { graphql_mutation(:workItemCreate, input.merge(namespacePath: group.full_path), fields) }

      it 'does not create the work item' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .not_to change { WorkItem.count }
      end

      it_behaves_like 'a mutation that returns top-level errors', errors: [
        "The resource that you are attempting to access does not exist or you don't have " \
          "permission to perform this action"
      ]
    end

    context 'when both projectPath and namespacePath are passed' do
      let_it_be(:container_params) { { project: project } }
      let(:mutation) do
        graphql_mutation(
          :workItemCreate,
          input.merge('projectPath' => project.full_path, 'namespacePath' => project.full_path),
          fields
        )
      end

      it_behaves_like 'a mutation that returns top-level errors', errors: [
        Mutations::WorkItems::Create::MUTUALLY_EXCLUSIVE_ARGUMENTS_ERROR
      ]
    end

    context 'when neither of projectPath nor namespacePath are passed' do
      let_it_be(:container_params) { { project: project } }
      let(:mutation) do
        graphql_mutation(
          :workItemCreate,
          input,
          fields
        )
      end

      it_behaves_like 'a mutation that returns top-level errors', errors: [
        Mutations::WorkItems::Create::MUTUALLY_EXCLUSIVE_ARGUMENTS_ERROR
      ]
    end
  end

  context 'with time tracking widget input' do
    shared_examples 'mutation creating work item with time tracking data' do
      it 'creates work item with time tracking data' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { WorkItem.count }.by(1)

        expect(mutation_response['workItem']['widgets']).to include(
          'timeEstimate' => 12.hours.to_i,
          'totalTimeSpent' => 2.hours.to_i,
          'timelogs' => {
            'nodes' => [
              {
                'timeSpent' => 2.hours.to_i
              }
            ]
          },
          'type' => 'TIME_TRACKING'
        )

        expect(mutation_response['workItem']['widgets']).to include(
          'description' => 'some description',
          'type' => 'DESCRIPTION'
        )
      end
    end

    let(:mutation) { graphql_mutation(:workItemCreate, input.merge('namespacePath' => project.full_path), fields) }
    let(:fields) do
      <<~FIELDS
        workItem {
          widgets {
            ... on WorkItemWidgetTimeTracking {
              type
              timeEstimate
              totalTimeSpent
              timelogs {
                nodes {
                  timeSpent
                }
              }
            }
            ... on WorkItemWidgetDescription {
              type
              description
            }
          }
        }
        errors
      FIELDS
    end

    context 'when adding time estimate and time spent' do
      context 'with quick action' do
        let(:input) do
          {
            title: 'item1',
            workItemTypeId: WorkItems::Type.default_by_type(:task).to_gid.to_s,
            'descriptionWidget' => { 'description' => "some description\n\n/estimate 12h\n/spend 2h" }
          }
        end

        it_behaves_like 'mutation creating work item with time tracking data'
      end

      context 'when work item belongs directly to the group' do
        let(:input) do
          {
            title: 'item1',
            workItemTypeId: WorkItems::Type.default_by_type(:task).to_gid.to_s,
            descriptionWidget: { description: "some description\n\n/estimate 12h\n/spend 2h" },
            namespacePath: group.full_path
          }
        end

        it_behaves_like 'mutation creating work item with time tracking data'
      end
    end

    context 'when the work item type does not support time tracking widget' do
      let(:input) do
        {
          title: 'item1',
          workItemTypeId: WorkItems::Type.default_by_type(:task).to_gid.to_s,
          'descriptionWidget' => { 'description' => "some description\n\n/estimate 12h\n/spend 2h" }
        }
      end

      before do
        WorkItems::Type.default_by_type(:task).widget_definitions
          .find_by_widget_type(:time_tracking).update!(disabled: true)
      end

      it 'ignores the quick action' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { WorkItem.count }.by(1)

        expect(mutation_response['workItem']['widgets']).not_to include('type' => 'TIME_TRACKING')
        expect(mutation_response['workItem']['widgets']).to include(
          'description' => "some description",
          'type' => 'DESCRIPTION'
        )
      end
    end
  end

  context 'with CRM contacts widget input' do
    let(:mutation) { graphql_mutation(:workItemCreate, input.merge('namespacePath' => project.full_path), fields) }
    let(:fields) do
      <<~FIELDS
        workItem {
          widgets {
            ... on WorkItemWidgetCrmContacts {
              type
              contacts {
                nodes {
                  id
                  firstName
                }
              }
            }
          }
        }
        errors
      FIELDS
    end

    let_it_be(:contact) { create(:contact, group: project.group) }

    shared_examples 'mutation setting work item contacts' do
      it 'creates work item with contact data' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { WorkItem.count }.by(1)

        expect(mutation_response['workItem']['widgets']).to include(
          'contacts' => {
            'nodes' => [
              {
                'id' => expected_result[:id],
                'firstName' => expected_result[:first_name]
              }
            ]
          },
          'type' => 'CRM_CONTACTS'
        )
      end
    end

    context 'when setting the contacts' do
      context 'when mutating the work item' do
        let(:input) do
          {
            'title' => 'item1',
            'workItemTypeId' => WorkItems::Type.default_by_type(:issue).to_gid.to_s,
            'crmContactsWidget' => {
              'contactIds' => [global_id_of(contact)]
            }
          }
        end

        let(:expected_result) do
          {
            id: global_id_of(contact).to_s,
            first_name: contact.first_name
          }
        end

        it_behaves_like 'mutation setting work item contacts'
      end
    end
  end

  context 'when resolving a merge request discussion' do
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be_with_reload(:discussion_note1) do
      create(:discussion_note, project: project, noteable: merge_request)
    end

    let_it_be_with_reload(:discussion_note2) do
      create(:discussion_note, project: project, noteable: merge_request)
    end

    let_it_be_with_reload(:discussion_reply1) do
      create(:discussion_note, project: project, noteable: merge_request, in_reply_to: discussion_note1)
    end

    let_it_be_with_reload(:discussion_reply2) do
      create(:discussion_note, project: project, noteable: merge_request, in_reply_to: discussion_note2)
    end

    let(:namespace_argument) { { 'namespacePath' => project.full_path } }
    let(:mutation) do
      graphql_mutation(
        :workItemCreate,
        input.merge(resolve_discussion_arguments).merge(namespace_argument),
        fields
      )
    end

    let(:fields) do
      <<~GRAPHQL
        workItem {
          id
        }
        errors
      GRAPHQL
    end

    context 'when a noteable that is not a merge reques is specified' do
      let(:resolve_discussion_arguments) do
        {
          discussions_to_resolve: { noteable_id: create(:issue, project: project).to_gid.to_s }
        }
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).to contain_exactly(
          hash_including(
            'message' => _('Only Merge Requests are allowed as a noteable to resolve discussions of at the moment.')
          )
        )
      end
    end

    context 'when no discussion ID is provided' do
      let(:resolve_discussion_arguments) do
        {
          discussions_to_resolve: { noteable_id: merge_request.to_gid.to_s }
        }
      end

      it 'resolves all discussions for the MR', :aggregate_failures do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { discussion_note1.reload.resolved? }.from(false).to(true)
          .and(change { discussion_note1.reload.resolved? }.from(false).to(true))
          .and(change { WorkItem.count }.by(1))
      end

      context 'when user cannot resolve discussions' do
        it 'returns an error' do
          post_graphql_mutation(mutation, current_user: create(:user, guest_of: project))

          expect(graphql_errors).to contain_exactly(
            hash_including(
              'message' => "The resource that you are attempting to access does not exist or you don't " \
                'have permission to perform this action'
            )
          )
        end
      end
    end

    context 'when a discussion ID is provided', :aggregate_failures do
      let(:resolve_discussion_arguments) do
        {
          discussions_to_resolve: {
            noteable_id: merge_request.to_gid.to_s,
            discussion_id: discussion_note1.discussion_id
          }
        }
      end

      it 'resolves only the specified discussion' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { discussion_note1.reload.resolved? }.from(false).to(true)
          .and(change { discussion_reply1.reload.resolved? }.from(false).to(true))
          .and(not_change { discussion_note2.reload.resolved? }.from(false))
          .and(not_change { discussion_reply2.reload.resolved? }.from(false))
          .and(change { WorkItem.count }.by(1))
      end
    end
  end
end
