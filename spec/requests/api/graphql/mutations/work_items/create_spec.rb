# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a work item', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }

  let(:input) do
    {
      'title' => 'new title',
      'description' => 'new description',
      'confidential' => true,
      'workItemTypeId' => WorkItems::Type.default_by_type(:task).to_gid.to_s
    }
  end

  let(:fields) { nil }
  let(:mutation_response) { graphql_mutation_response(:work_item_create) }
  let(:current_user) { developer }

  RSpec.shared_examples 'creates work item' do
    it 'creates the work item' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change(WorkItem, :count).by(1)

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
              .to contain_exactly(/cannot be added: is not allowed to add this type of parent/)
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

          it 'creates work item and sets the relative position to be AFTER adjacent' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
            end.to change(WorkItem, :count).by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(widgets_response).to include(
              {
                'children' => { 'edges' => [] },
                'parent' => { 'id' => parent.to_gid.to_s },
                'type' => 'HIERARCHY'
              }
            )
            expect(work_item.parent_link.relative_position).to be > adjacent.parent_link.relative_position
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
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
            end.to change(WorkItem, :count).by(1)

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
  end

  context 'the user is not allowed to create a work item' do
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

      it_behaves_like 'creates work item'

      context 'when the namespace_level_work_items feature flag is disabled' do
        before do
          stub_feature_flags(namespace_level_work_items: false)
        end

        it_behaves_like 'a mutation that returns top-level errors', errors: [
          Mutations::WorkItems::Create::DISABLED_FF_ERROR
        ]
      end
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
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change(WorkItem, :count).by(1)

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
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change(WorkItem, :count).by(1)

        expect(mutation_response['workItem']['widgets']).not_to include('type' => 'TIME_TRACKING')
        expect(mutation_response['workItem']['widgets']).to include(
          'description' => "some description",
          'type' => 'DESCRIPTION'
        )
      end
    end
  end
end
