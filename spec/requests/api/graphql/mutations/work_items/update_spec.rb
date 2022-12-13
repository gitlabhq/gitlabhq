# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update a work item', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:reporter) { create(:user).tap { |user| project.add_reporter(user) } }
  let_it_be(:guest) { create(:user).tap { |user| project.add_guest(user) } }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project) }

  let(:work_item_event) { 'CLOSE' }
  let(:input) { { 'stateEvent' => work_item_event, 'title' => 'updated title' } }
  let(:fields) do
    <<~FIELDS
    workItem {
      state
      title
    }
    errors
    FIELDS
  end

  let(:mutation) { graphql_mutation(:workItemUpdate, input.merge('id' => work_item.to_global_id.to_s), fields) }

  let(:mutation_response) { graphql_mutation_response(:work_item_update) }

  context 'the user is not allowed to update a work item' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to update a work item' do
    let(:current_user) { developer }

    it_behaves_like 'has spam protection' do
      let(:mutation_class) { ::Mutations::WorkItems::Update }
    end

    context 'when the work item is open' do
      it 'closes and updates the work item' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          work_item.reload
        end.to change(work_item, :state).from('opened').to('closed').and(
          change(work_item, :title).from(work_item.title).to('updated title')
        )

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['workItem']).to include(
          'state' => 'CLOSED',
          'title' => 'updated title'
        )
      end
    end

    context 'when the work item is closed' do
      let(:work_item_event) { 'REOPEN' }

      before do
        work_item.close!
      end

      it 'reopens the work item' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          work_item.reload
        end.to change(work_item, :state).from('closed').to('opened')

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['workItem']).to include(
          'state' => 'OPEN'
        )
      end
    end

    context 'when updating confidentiality' do
      let(:fields) do
        <<~FIELDS
        workItem {
          confidential
        }
        errors
        FIELDS
      end

      shared_examples 'toggling confidentiality' do
        it 'successfully updates work item' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.to change(work_item, :confidential).from(values[:old]).to(values[:new])

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['workItem']).to include(
            'confidential' => values[:new]
          )
        end
      end

      context 'when setting as confidential' do
        let(:input) { { 'confidential' => true } }

        it_behaves_like 'toggling confidentiality' do
          let(:values) { { old: false, new: true } }
        end
      end

      context 'when setting as non-confidential' do
        let(:input) { { 'confidential' => false } }

        before do
          work_item.update!(confidential: true)
        end

        it_behaves_like 'toggling confidentiality' do
          let(:values) { { old: true, new: false } }
        end
      end
    end

    context 'with description widget input' do
      let(:fields) do
        <<~FIELDS
        workItem {
          description
          widgets {
            type
            ... on WorkItemWidgetDescription {
                    description
            }
          }
        }
        errors
        FIELDS
      end

      it_behaves_like 'update work item description widget' do
        let(:new_description) { 'updated description' }
        let(:input) do
          { 'descriptionWidget' => { 'description' => new_description } }
        end
      end
    end

    context 'with labels widget input' do
      shared_examples 'mutation updating work item labels' do
        it 'updates labels' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.to change { work_item.labels.count }.to(expected_labels.count)

          expect(work_item.labels).to match_array(expected_labels)
          expect(mutation_response['workItem']['widgets']).to include(
            'labels' => {
              'nodes' => match_array(expected_labels.map { |l| { 'id' => l.to_gid.to_s } })
            },
            'type' => 'LABELS'
          )
        end
      end

      let_it_be(:existing_label) { create(:label, project: project) }
      let_it_be(:label1) { create(:label, project: project) }
      let_it_be(:label2) { create(:label, project: project) }

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

      let(:input) do
        { 'labelsWidget' => { 'addLabelIds' => add_label_ids, 'removeLabelIds' => remove_label_ids } }
      end

      let(:add_label_ids) { [] }
      let(:remove_label_ids) { [] }

      before_all do
        work_item.update!(labels: [existing_label])
      end

      context 'when only removing labels' do
        let(:remove_label_ids) { [existing_label.to_gid.to_s] }
        let(:expected_labels) { [] }

        it_behaves_like 'mutation updating work item labels'
      end

      context 'when only adding labels' do
        let(:add_label_ids) { [label1.to_gid.to_s, label2.to_gid.to_s] }
        let(:expected_labels) { [label1, label2, existing_label] }

        it_behaves_like 'mutation updating work item labels'
      end

      context 'when adding and removing labels' do
        let(:remove_label_ids) { [existing_label.to_gid.to_s] }
        let(:add_label_ids) { [label1.to_gid.to_s, label2.to_gid.to_s] }
        let(:expected_labels) { [label1, label2] }

        it_behaves_like 'mutation updating work item labels'
      end
    end

    context 'with due and start date widget input' do
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
            }
          }
          errors
        FIELDS
      end

      let(:input) do
        { 'startAndDueDateWidget' => { 'startDate' => start_date.to_s, 'dueDate' => due_date.to_s } }
      end

      it 'updates start and due date' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          work_item.reload
        end.to change(work_item, :start_date).from(nil).to(start_date).and(
          change(work_item, :due_date).from(nil).to(due_date)
        )

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['workItem']['widgets']).to include(
          {
            'startDate' => start_date.to_s,
            'dueDate' => due_date.to_s,
            'type' => 'START_AND_DUE_DATE'
          }
        )
      end

      context 'when provided input is invalid' do
        let(:due_date) { 1.week.ago.to_date }

        it 'returns validation errors without the work item' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response['workItem']).to be_nil
          expect(mutation_response['errors']).to contain_exactly('Due date must be greater than or equal to start date')
        end
      end

      context 'when dates were already set for the work item' do
        before do
          work_item.update!(start_date: start_date, due_date: due_date)
        end

        context 'when updating only start date' do
          let(:input) do
            { 'startAndDueDateWidget' => { 'startDate' => nil } }
          end

          it 'allows setting a single date to null' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to change(work_item, :start_date).from(start_date).to(nil).and(
              not_change(work_item, :due_date).from(due_date)
            )
          end
        end

        context 'when updating only due date' do
          let(:input) do
            { 'startAndDueDateWidget' => { 'dueDate' => nil } }
          end

          it 'allows setting a single date to null' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to change(work_item, :due_date).from(due_date).to(nil).and(
              not_change(work_item, :start_date).from(start_date)
            )
          end
        end
      end
    end

    context 'with hierarchy widget input' do
      let(:widgets_response) { mutation_response['workItem']['widgets'] }
      let(:fields) do
        <<~FIELDS
        workItem {
          description
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

      context 'when updating parent' do
        let_it_be(:work_item, reload: true) { create(:work_item, :task, project: project) }
        let_it_be(:valid_parent) { create(:work_item, project: project) }
        let_it_be(:invalid_parent) { create(:work_item, :task, project: project) }

        context 'when parent work item type is invalid' do
          let(:error) { "#{work_item.to_reference} cannot be added: is not allowed to add this type of parent" }
          let(:input) do
            { 'hierarchyWidget' => { 'parentId' => invalid_parent.to_global_id.to_s }, 'title' => 'new title' }
          end

          it 'returns response with errors' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to not_change(work_item, :work_item_parent).and(not_change(work_item, :title))

            expect(mutation_response['workItem']).to be_nil
            expect(mutation_response['errors']).to match_array([error])
          end
        end

        context 'when parent work item has a valid type' do
          let(:input) { { 'hierarchyWidget' => { 'parentId' => valid_parent.to_global_id.to_s } } }

          it 'sets the parent for the work item' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to change(work_item, :work_item_parent).from(nil).to(valid_parent)

            expect(response).to have_gitlab_http_status(:success)
            expect(widgets_response).to include(
              {
                'children' => { 'edges' => [] },
                'parent' => { 'id' => valid_parent.to_global_id.to_s },
                'type' => 'HIERARCHY'
              }
            )
          end

          context 'when a parent is already present' do
            let_it_be(:existing_parent) { create(:work_item, project: project) }

            before do
              work_item.update!(work_item_parent: existing_parent)
            end

            it 'is replaced with new parent' do
              expect do
                post_graphql_mutation(mutation, current_user: current_user)
                work_item.reload
              end.to change(work_item, :work_item_parent).from(existing_parent).to(valid_parent)
            end
          end
        end

        context 'when parentId is null' do
          let(:input) { { 'hierarchyWidget' => { 'parentId' => nil } } }

          context 'when parent is present' do
            before do
              work_item.update!(work_item_parent: valid_parent)
            end

            it 'removes parent and returns success message' do
              expect do
                post_graphql_mutation(mutation, current_user: current_user)
                work_item.reload
              end.to change(work_item, :work_item_parent).from(valid_parent).to(nil)

              expect(response).to have_gitlab_http_status(:success)
              expect(widgets_response)
                .to include(
                  {
                    'children' => { 'edges' => [] },
                    'parent' => nil,
                    'type' => 'HIERARCHY'
                  }
                )
            end
          end

          context 'when parent is not present' do
            before do
              work_item.update!(work_item_parent: nil)
            end

            it 'does not change work item and returns success message' do
              expect do
                post_graphql_mutation(mutation, current_user: current_user)
                work_item.reload
              end.not_to change(work_item, :work_item_parent)

              expect(response).to have_gitlab_http_status(:success)
            end
          end
        end

        context 'when parent work item is not found' do
          let(:input) { { 'hierarchyWidget' => { 'parentId' => "gid://gitlab/WorkItem/#{non_existing_record_id}" } } }

          it 'returns a top level error' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(graphql_errors.first['message']).to include('No object found for `parentId')
          end
        end
      end

      context 'when updating children' do
        let_it_be(:valid_child1) { create(:work_item, :task, project: project) }
        let_it_be(:valid_child2) { create(:work_item, :task, project: project) }
        let_it_be(:invalid_child) { create(:work_item, project: project) }

        let(:input) { { 'hierarchyWidget' => { 'childrenIds' => children_ids } } }
        let(:error) do
          "#{invalid_child.to_reference} cannot be added: is not allowed to add this type of parent"
        end

        context 'when child work item type is invalid' do
          let(:children_ids) { [invalid_child.to_global_id.to_s] }

          it 'returns response with errors' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(mutation_response['workItem']).to be_nil
            expect(mutation_response['errors']).to match_array([error])
          end
        end

        context 'when there is a mix of existing and non existing work items' do
          let(:children_ids) { [valid_child1.to_global_id.to_s, "gid://gitlab/WorkItem/#{non_existing_record_id}"] }

          it 'returns a top level error and does not add valid work item' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.not_to change(work_item.work_item_children, :count)

            expect(graphql_errors.first['message']).to include('No object found for `childrenIds')
          end
        end

        context 'when child work item type is valid' do
          let(:children_ids) { [valid_child1.to_global_id.to_s, valid_child2.to_global_id.to_s] }

          it 'updates the work item children' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to change(work_item.work_item_children, :count).by(2)

            expect(response).to have_gitlab_http_status(:success)
            expect(widgets_response).to include(
              {
                'children' => { 'edges' => [
                  { 'node' => { 'id' => valid_child2.to_global_id.to_s } },
                  { 'node' => { 'id' => valid_child1.to_global_id.to_s } }
                ] },
                'parent' => nil,
                'type' => 'HIERARCHY'
              }
            )
          end
        end
      end
    end

    context 'when updating assignees' do
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

      let(:input) do
        { 'assigneesWidget' => { 'assigneeIds' => [developer.to_global_id.to_s] } }
      end

      it 'updates the work item assignee' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          work_item.reload
        end.to change(work_item, :assignee_ids).from([]).to([developer.id])

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['workItem']['widgets']).to include(
          {
            'type' => 'ASSIGNEES',
            'assignees' => {
              'nodes' => [
                { 'id' => developer.to_global_id.to_s, 'username' => developer.username }
              ]
            }
          }
        )
      end
    end

    context 'when updating milestone' do
      let_it_be(:project_milestone) { create(:milestone, project: project) }
      let_it_be(:group_milestone) { create(:milestone, project: project) }

      let(:input) { { 'milestoneWidget' => { 'milestoneId' => new_milestone&.to_global_id&.to_s } } }

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

      shared_examples "work item's milestone is updated" do
        it "updates the work item's milestone" do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)

            work_item.reload
          end.to change(work_item, :milestone).from(old_milestone).to(new_milestone)

          expect(response).to have_gitlab_http_status(:success)
        end
      end

      shared_examples "work item's milestone is not updated" do
        it "ignores the update request" do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)

            work_item.reload
          end.to not_change(work_item, :milestone)

          expect(response).to have_gitlab_http_status(:success)
        end
      end

      context 'when user cannot set work item metadata' do
        let(:current_user) { guest }
        let(:old_milestone) { nil }

        it_behaves_like "work item's milestone is not updated" do
          let(:new_milestone) { project_milestone }
        end
      end

      context 'when user can set work item metadata' do
        let(:current_user) { reporter }

        context 'when assigning a project milestone' do
          it_behaves_like "work item's milestone is updated" do
            let(:old_milestone) { nil }
            let(:new_milestone) { project_milestone }
          end
        end

        context 'when assigning a group milestone' do
          it_behaves_like "work item's milestone is updated" do
            let(:old_milestone) { nil }
            let(:new_milestone) { group_milestone }
          end
        end

        context "when unsetting the work item's milestone" do
          it_behaves_like "work item's milestone is updated" do
            let(:old_milestone) { group_milestone }
            let(:new_milestone) { nil }

            before do
              work_item.update!(milestone: old_milestone)
            end
          end
        end
      end
    end

    context 'when unsupported widget input is sent' do
      let_it_be(:test_case) { create(:work_item_type, :default, :test_case) }
      let_it_be(:work_item) { create(:work_item, work_item_type: test_case, project: project) }

      let(:input) do
        {
          'hierarchyWidget' => {}
        }
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ["Following widget keys are not supported by Test Case type: [:hierarchy_widget]"]
    end
  end
end
