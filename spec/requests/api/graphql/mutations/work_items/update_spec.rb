# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update a work item', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:author) { create(:user, reporter_of: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }
  let_it_be(:reporter) { create(:user, reporter_of: group) }
  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project, author: author) }

  let(:input) { { 'stateEvent' => 'CLOSE', 'title' => 'updated title' } }
  let(:fields) do
    <<~FIELDS
      workItem {
        state
        title
      }
      errors
    FIELDS
  end

  let(:mutation_work_item) { work_item }
  let(:mutation) { graphql_mutation(:workItemUpdate, input.merge('id' => mutation_work_item.to_gid.to_s), fields) }

  let(:mutation_response) { graphql_mutation_response(:work_item_update) }

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  shared_examples 'request with error' do |message|
    it 'ignores update and returns an error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['workItem']).to be_nil
      expect(mutation_response['errors'].first).to include(message)
    end
  end

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
      let(:input) { { 'stateEvent' => 'REOPEN' } }

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

    context 'with description widget input', :freeze_time do
      let(:fields) do
        <<~FIELDS
          workItem {
            title
            description
            state
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
            mutation_work_item.reload
          end.to change { mutation_work_item.labels.count }.to(expected_labels.count)

          expect(mutation_work_item.labels).to match_array(expected_labels)
          expect(mutation_response['workItem']['widgets']).to include(
            'labels' => {
              'nodes' => match_array(expected_labels.map { |l| { 'id' => l.to_gid.to_s } })
            },
            'type' => 'LABELS'
          )
        end
      end

      let_it_be(:existing_label) { create(:group_label, group: group) }
      let_it_be(:label1) { create(:group_label, group: group) }
      let_it_be(:label2) { create(:group_label, group: group) }

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
              ... on WorkItemWidgetDescription {
                description
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
      let_it_be(:group_work_item) { create(:work_item, :task, :group_level, namespace: group) }

      before_all do
        work_item.update!(labels: [existing_label])
        group_work_item.update!(labels: [existing_label])
      end

      context 'when only removing labels' do
        let(:remove_label_ids) { [existing_label.to_gid.to_s] }
        let(:expected_labels) { [] }

        it_behaves_like 'mutation updating work item labels'

        context 'with quick action' do
          let(:input) { { 'descriptionWidget' => { 'description' => "/remove_label ~\"#{existing_label.name}\"" } } }

          it_behaves_like 'mutation updating work item labels'
        end

        context 'when work item belongs directly to the group', if: Gitlab.ee? do
          let(:mutation_work_item) { group_work_item }

          before do
            stub_licensed_features(epics: true)
          end

          it_behaves_like 'mutation updating work item labels'

          context 'without group level work item license' do
            before do
              stub_licensed_features(epics: false)
            end

            it_behaves_like 'a mutation that returns top-level errors', errors: [
              "The resource that you are attempting to access does not exist or you don't have " \
                "permission to perform this action"
            ]
          end

          context 'with quick action' do
            let(:input) { { 'descriptionWidget' => { 'description' => "/remove_label ~\"#{existing_label.name}\"" } } }

            it_behaves_like 'mutation updating work item labels'

            context 'without group level work item license' do
              before do
                stub_licensed_features(epics: false)
              end

              it_behaves_like 'a mutation that returns top-level errors', errors: [
                "The resource that you are attempting to access does not exist or you don't have " \
                  "permission to perform this action"
              ]
            end
          end
        end
      end

      context 'when only adding labels' do
        let(:add_label_ids) { [label1.to_gid.to_s, label2.to_gid.to_s] }
        let(:expected_labels) { [label1, label2, existing_label] }

        it_behaves_like 'mutation updating work item labels'

        context 'with quick action' do
          let(:input) do
            { 'descriptionWidget' => { 'description' => "/labels ~\"#{label1.name}\" ~\"#{label2.name}\"" } }
          end

          it_behaves_like 'mutation updating work item labels'
        end

        context 'when work item belongs directly to the group', if: Gitlab.ee? do
          let(:mutation_work_item) { group_work_item }

          before do
            stub_licensed_features(epics: true)
          end

          it_behaves_like 'mutation updating work item labels'

          context 'without group level work item license' do
            before do
              stub_licensed_features(epics: false)
            end

            it_behaves_like 'a mutation that returns top-level errors', errors: [
              "The resource that you are attempting to access does not exist or you don't have " \
                "permission to perform this action"
            ]
          end

          context 'with quick action' do
            let(:input) do
              { 'descriptionWidget' => { 'description' => "/labels ~\"#{label1.name}\" ~\"#{label2.name}\"" } }
            end

            it_behaves_like 'mutation updating work item labels'

            context 'without group level work item license' do
              before do
                stub_licensed_features(epics: false)
              end

              it_behaves_like 'a mutation that returns top-level errors', errors: [
                "The resource that you are attempting to access does not exist or you don't have " \
                  "permission to perform this action"
              ]
            end
          end
        end
      end

      context 'when adding and removing labels' do
        let(:remove_label_ids) { [existing_label.to_gid.to_s] }
        let(:add_label_ids) { [label1.to_gid.to_s, label2.to_gid.to_s] }
        let(:expected_labels) { [label1, label2] }

        it_behaves_like 'mutation updating work item labels'

        context 'with quick action' do
          let(:input) do
            { 'descriptionWidget' => { 'description' =>
                  "/label ~\"#{label1.name}\" ~\"#{label2.name}\"\n/remove_label ~\"#{existing_label.name}\"" } }
          end

          it_behaves_like 'mutation updating work item labels'
        end

        context 'when work item belongs directly to the group', if: Gitlab.ee? do
          let(:mutation_work_item) { group_work_item }

          before do
            stub_licensed_features(epics: true)
          end

          it_behaves_like 'mutation updating work item labels'

          context 'without group level work item license' do
            before do
              stub_licensed_features(epics: false)
            end

            it_behaves_like 'a mutation that returns top-level errors', errors: [
              "The resource that you are attempting to access does not exist or you don't have " \
                "permission to perform this action"
            ]
          end
        end
      end

      context 'when the work item type does not support labels widget' do
        let_it_be(:work_item) { create(:work_item, :task, project: project) }

        let(:input) { { 'descriptionWidget' => { 'description' => "Updating labels.\n/labels ~\"#{label1.name}\"" } } }

        before do
          WorkItems::Type.default_by_type(:task).widget_definitions
            .find_by_widget_type(:labels).update!(disabled: true)
        end

        it 'ignores the quick action' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.not_to change(work_item.labels, :count)

          expect(work_item.labels).to be_empty
          expect(mutation_response['workItem']['widgets']).to include(
            'description' => "Updating labels.",
            'type' => 'DESCRIPTION'
          )
          expect(mutation_response['workItem']['widgets']).not_to include(
            'labels',
            'type' => 'LABELS'
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

      context 'when using quick action' do
        let(:due_date) { Date.today }

        context 'when removing due date' do
          let(:input) { { 'descriptionWidget' => { 'description' => "/remove_due_date" } } }

          before do
            (work_item.dates_source || work_item.build_dates_source)
              .update!(due_date: due_date)
          end

          it 'updates start and due date' do
            expect { post_graphql_mutation(mutation, current_user: current_user) }
              .to change { work_item.reload.due_date }.from(due_date).to(nil)
              .and change { work_item.dates_source&.due_date }.from(due_date).to(nil)
              .and not_change { work_item.start_date }
              .and not_change { work_item.dates_source&.start_date }

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['workItem']['widgets']).to include({
              'startDate' => nil,
              'dueDate' => nil,
              'type' => 'START_AND_DUE_DATE'
            })
          end
        end

        context 'when setting due date' do
          let(:input) { { 'descriptionWidget' => { 'description' => "/due today" } } }

          it 'updates due date' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to not_change(work_item, :start_date).and(
              change(work_item, :due_date).from(nil).to(due_date)
            )

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['workItem']['widgets']).to include({
              'startDate' => nil,
              'dueDate' => Date.today.to_s,
              'type' => 'START_AND_DUE_DATE'
            })
          end
        end

        context 'when the work item type does not support start and due date widget' do
          let_it_be(:work_item) { create(:work_item, :task, project: project) }

          let(:input) { { 'descriptionWidget' => { 'description' => "Updating due date.\n/due today" } } }

          before do
            WorkItems::Type.default_by_type(:task).widget_definitions
              .find_by_widget_type(:start_and_due_date).update!(disabled: true)
          end

          it 'ignores the quick action' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.not_to change(work_item, :due_date)

            expect(mutation_response['workItem']['widgets']).to include(
              'description' => "Updating due date.",
              'type' => 'DESCRIPTION'
            )
            expect(mutation_response['workItem']['widgets']).not_to include({
              'dueDate' => nil,
              'type' => 'START_AND_DUE_DATE'
            })
          end
        end
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
          (work_item.dates_source || work_item.build_dates_source)
            .update!(start_date: start_date, start_date_fixed: start_date, due_date: due_date, due_date_fixed: due_date)
        end

        context 'when updating only start date' do
          let(:input) do
            { 'startAndDueDateWidget' => { 'startDate' => nil } }
          end

          it 'allows setting a single date to null', :aggregate_failures do
            expect { post_graphql_mutation(mutation, current_user: current_user) }
              .to change { work_item.reload.start_date }.from(start_date).to(nil)
              .and change { work_item.dates_source.start_date }.from(start_date).to(nil)
              .and not_change { work_item.due_date }.from(due_date)
              .and not_change { work_item.dates_source.due_date }.from(due_date)
          end
        end

        context 'when updating only due date' do
          let(:input) do
            { 'startAndDueDateWidget' => { 'dueDate' => nil } }
          end

          it 'allows setting a single date to null' do
            expect { post_graphql_mutation(mutation, current_user: current_user) }
              .to change { work_item.reload.due_date }.from(due_date).to(nil)
              .and change { work_item.dates_source.due_date }.from(due_date).to(nil)
              .and not_change { work_item.start_date }.from(start_date)
              .and not_change { work_item.dates_source.start_date }.from(start_date)
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

      let_it_be(:valid_parent) { create(:work_item, project: project) }
      let_it_be(:valid_child1) { create(:work_item, :task, project: project, created_at: 5.minutes.ago) }
      let_it_be(:valid_child2) { create(:work_item, :task, project: project, created_at: 5.minutes.from_now) }
      let(:input_base) { { parentId: valid_parent.to_gid.to_s } }
      let(:child1_ref) { { adjacentWorkItemId: valid_child1.to_global_id.to_s } }
      let(:child2_ref) { { adjacentWorkItemId: valid_child2.to_global_id.to_s } }
      let(:relative_range) { [valid_child1, valid_child2].map(&:parent_link).map(&:relative_position) }

      let(:invalid_relative_position_error) do
        WorkItems::Callbacks::Hierarchy::INVALID_RELATIVE_POSITION_ERROR
      end

      shared_examples 'updates work item parent and sets the relative position' do
        it do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.to change(work_item, :work_item_parent).from(nil).to(valid_parent)

          expect(response).to have_gitlab_http_status(:success)
          expect(widgets_response).to include({ 'type' => 'HIERARCHY', 'children' => { 'edges' => [] },
            'parent' => { 'id' => valid_parent.to_global_id.to_s } })

          expect(work_item.parent_link.relative_position).to be_between(*relative_range)
        end
      end

      shared_examples 'sets the relative position and does not update work item parent' do
        it do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.to not_change(work_item, :work_item_parent)

          expect(response).to have_gitlab_http_status(:success)
          expect(widgets_response).to include({ 'type' => 'HIERARCHY', 'children' => { 'edges' => [] },
            'parent' => { 'id' => valid_parent.to_global_id.to_s } })

          expect(work_item.parent_link.relative_position).to be_between(*relative_range)
        end
      end

      shared_examples 'returns "relative position is not valid" error message' do
        it do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.to not_change(work_item, :work_item_parent)

          expect(mutation_response['workItem']).to be_nil
          expect(mutation_response['errors']).to match_array([invalid_relative_position_error])
        end
      end

      context 'when updating parent' do
        let_it_be(:work_item, reload: true) { create(:work_item, :task, project: project) }
        let_it_be(:invalid_parent) { create(:work_item, :task, project: project) }

        context 'when parent work item type is invalid' do
          let(:error) do
            "#{invalid_parent.to_reference} cannot be added: it's not allowed to add this type of parent item"
          end

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

          it 'updates work item parent' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to change(work_item, :work_item_parent).from(nil).to(valid_parent)

            expect(response).to have_gitlab_http_status(:success)
            expect(widgets_response).to include({ 'type' => 'HIERARCHY', 'children' => { 'edges' => [] },
              'parent' => { 'id' => valid_parent.to_global_id.to_s } })
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

          context 'when updating relative position' do
            before_all do
              create(:parent_link, work_item_parent: valid_parent, work_item: valid_child1)
              create(:parent_link, work_item_parent: valid_parent, work_item: valid_child2)
            end

            context "when incomplete positioning arguments are given" do
              let(:input) { { hierarchyWidget: input_base.merge(child1_ref) } }

              it_behaves_like 'returns "relative position is not valid" error message'
            end

            context 'when moving after adjacent' do
              let(:input) { { hierarchyWidget: input_base.merge(child1_ref).merge(relativePosition: 'AFTER') } }

              it_behaves_like 'updates work item parent and sets the relative position'
            end

            context 'when moving before adjacent' do
              let(:input) { { hierarchyWidget: input_base.merge(child2_ref).merge(relativePosition: 'BEFORE') } }

              it_behaves_like 'updates work item parent and sets the relative position'
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

      context 'when reordering existing child' do
        let_it_be(:work_item, reload: true) { create(:work_item, :task, project: project) }

        context "when parent is already assigned" do
          before_all do
            create(:parent_link, work_item_parent: valid_parent, work_item: work_item)
            create(:parent_link, work_item_parent: valid_parent, work_item: valid_child1)
            create(:parent_link, work_item_parent: valid_parent, work_item: valid_child2)
          end

          context "when incomplete positioning arguments are given" do
            let(:input) { { hierarchyWidget: child1_ref } }

            it_behaves_like 'returns "relative position is not valid" error message'
          end

          context 'when moving after adjacent' do
            let(:input) { { hierarchyWidget: child1_ref.merge(relativePosition: 'AFTER') } }

            it_behaves_like 'sets the relative position and does not update work item parent'
          end

          context 'when moving before adjacent' do
            let(:input) { { hierarchyWidget: child2_ref.merge(relativePosition: 'BEFORE') } }

            it_behaves_like 'sets the relative position and does not update work item parent'
          end
        end
      end

      context 'when updating children' do
        let_it_be(:invalid_child) { create(:work_item, project: project) }

        let(:input) { { 'hierarchyWidget' => { 'childrenIds' => children_ids } } }
        let(:error) do
          "#{invalid_child.to_reference} cannot be added: it's not allowed to add this type of parent item"
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
                'children' => { 'edges' => match_array([
                  { 'node' => { 'id' => valid_child2.to_global_id.to_s } },
                  { 'node' => { 'id' => valid_child1.to_global_id.to_s } }
                ]) },
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
            title
            workItemType { name }
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
              ... on WorkItemWidgetDescription {
                description
              }
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

      context 'when using quick action' do
        context 'when assigning a user' do
          let(:input) { { 'descriptionWidget' => { 'description' => "/assign @#{developer.username}" } } }

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

        context 'when unassigning a user' do
          let(:input) { { 'descriptionWidget' => { 'description' => "/unassign @#{developer.username}" } } }

          before do
            work_item.update!(assignee_ids: [developer.id])
          end

          it 'updates the work item assignee' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to change(work_item, :assignee_ids).from([developer.id]).to([])

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['workItem']['widgets']).to include(
              'type' => 'ASSIGNEES',
              'assignees' => {
                'nodes' => []
              }
            )
          end
        end

        context 'when changing work item type' do
          let_it_be(:work_item) { create(:work_item, :task, project: project) }
          let(:description) { "/type issue" }

          let(:input) { { 'descriptionWidget' => { 'description' => description } } }

          context 'with multiple commands' do
            let_it_be(:work_item) { create(:work_item, :task, project: project) }

            let(:description) { "Updating work item\n/type issue\n/due tomorrow\n/title Foo" }

            it 'updates the work item type and other attributes' do
              tomorrow = 1.day.from_now.to_date

              expect { post_graphql_mutation(mutation, current_user: current_user) }
                .to change { work_item.reload.work_item_type.base_type }.from('task').to('issue')
                .and change { work_item.dates_source&.due_date }.to(tomorrow)
                .and change { work_item.due_date }.to(tomorrow)

              expect(response).to have_gitlab_http_status(:success)
              expect(mutation_response['workItem']['workItemType']['name']).to eq('Issue')
              expect(mutation_response['workItem']['title']).to eq('Foo')
              expect(mutation_response['workItem']['widgets']).to include(
                'type' => 'START_AND_DUE_DATE',
                'dueDate' => Date.tomorrow.iso8601,
                'startDate' => nil
              )
            end
          end

          context 'when conversion is not permitted' do
            let_it_be(:work_item) { create(:work_item, :task, project: project) }
            let_it_be(:issue) { create(:work_item, project: project) }
            let_it_be(:link) { create(:parent_link, work_item_parent: issue, work_item: work_item) }

            let(:error_msg) { 'Work item type cannot be changed to issue when linked to a parent issue.' }

            it 'does not update the work item type' do
              expect { post_graphql_mutation(mutation, current_user: current_user) }
                .not_to change { work_item.reload.work_item_type.base_type }

              expect(response).to have_gitlab_http_status(:success)
              expect(mutation_response['errors']).to include(error_msg)
            end
          end

          context 'when new type does not support a widget' do
            before do
              (work_item.dates_source || work_item.build_dates_source)
                .update!(start_date: Date.current, due_date: Date.tomorrow)

              WorkItems::Type.default_by_type(:issue).widget_definitions
                .find_by_widget_type(:start_and_due_date).update!(disabled: true)
            end

            it 'updates the work item type and clear widget attributes' do
              expect { post_graphql_mutation(mutation, current_user: current_user) }
                .to change { work_item.reload.work_item_type.base_type }.from('task').to('issue')
                .and change { work_item.due_date }.to(nil)
                .and change { work_item.dates_source&.due_date }.to(nil)
                .and change { work_item.start_date }.to(nil)
                .and change { work_item.dates_source&.start_date }.to(nil)

              expect(response).to have_gitlab_http_status(:success)
              expect(mutation_response['workItem']['workItemType']['name']).to eq('Issue')
              expect(mutation_response['workItem']['widgets']).to include(
                {
                  'type' => 'START_AND_DUE_DATE',
                  'startDate' => nil,
                  'dueDate' => nil
                }
              )
            end
          end
        end
      end

      context 'when the work item type does not support the assignees widget' do
        let_it_be(:work_item) { create(:work_item, :task, project: project) }

        let(:input) do
          { 'descriptionWidget' => { 'description' => "Updating assignee.\n/assign @#{developer.username}" } }
        end

        before do
          WorkItems::Type.default_by_type(:task).widget_definitions
            .find_by_widget_type(:assignees).update!(disabled: true)
        end

        it 'ignores the quick action' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.not_to change(work_item, :assignee_ids)

          expect(mutation_response['workItem']['widgets']).to include({
            'description' => "Updating assignee.",
            'type' => 'DESCRIPTION'
          }
                                                                     )
          expect(mutation_response['workItem']['widgets']).not_to include({ 'type' => 'ASSIGNEES' })
        end
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

    context 'when updating notifications subscription' do
      let_it_be(:current_user) { guest }
      let(:input) { { 'notificationsWidget' => { 'subscribed' => desired_state } } }

      let(:fields) do
        <<~FIELDS
          workItem {
            widgets {
              type
              ... on WorkItemWidgetNotifications {
                subscribed
              }
            }
          }
          errors
        FIELDS
      end

      subject(:update_work_item) { post_graphql_mutation(mutation, current_user: current_user) }

      shared_examples 'subscription updated successfully' do
        let_it_be(:subscription) do
          create(
            :subscription, project: project,
            user: current_user,
            subscribable: work_item,
            subscribed: !desired_state
          )
        end

        it "updates existing work item's subscription state" do
          expect do
            update_work_item
            subscription.reload
          end.to change(subscription, :subscribed).to(desired_state)
            .and(change { work_item.reload.subscribed?(guest, project) }.to(desired_state))

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['workItem']['widgets']).to include(
            {
              'subscribed' => desired_state,
              'type' => 'NOTIFICATIONS'
            }
          )
        end
      end

      shared_examples 'subscription update ignored' do
        context 'when user is subscribed with a subscription record' do
          let_it_be(:subscription) do
            create(
              :subscription, project: project,
              user: current_user,
              subscribable: work_item,
              subscribed: !desired_state
            )
          end

          it 'ignores the update request' do
            expect do
              update_work_item
              subscription.reload
            end.to not_change(subscription, :subscribed)
              .and(not_change { work_item.subscribed?(current_user, project) })

            expect(response).to have_gitlab_http_status(:success)
          end
        end

        context 'when user is subscribed by being a participant' do
          let_it_be(:current_user) { author }

          it 'ignores the update request' do
            expect do
              update_work_item
            end.to not_change(Subscription, :count)
              .and(not_change { work_item.subscribed?(current_user, project) })

            expect(response).to have_gitlab_http_status(:success)
          end
        end
      end

      context 'when work item update fails' do
        let_it_be(:desired_state) { false }
        let(:input) { { 'title' => nil, 'notificationsWidget' => { 'subscribed' => desired_state } } }

        it_behaves_like 'subscription update ignored'
      end

      context 'when user cannot update work item' do
        let_it_be(:desired_state) { false }

        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?)
            .with(current_user, :update_subscription, work_item).and_return(false)
        end

        it_behaves_like 'subscription update ignored'
      end

      context 'when user can update work item' do
        context 'when subscribing to notifications' do
          let_it_be(:desired_state) { true }

          it_behaves_like 'subscription updated successfully'
        end

        context 'when unsubscribing from notifications' do
          let_it_be(:desired_state) { false }

          it_behaves_like 'subscription updated successfully'

          context 'when user is subscribed by being a participant' do
            let_it_be(:current_user) { author }

            it 'creates a subscription with desired state' do
              expect { update_work_item }.to change(Subscription, :count).by(1)
                .and(change { work_item.reload.subscribed?(author, project) }.to(desired_state))

              expect(response).to have_gitlab_http_status(:success)
              expect(mutation_response['workItem']['widgets']).to include(
                {
                  'subscribed' => desired_state,
                  'type' => 'NOTIFICATIONS'
                }
              )
            end
          end
        end
      end
    end

    context 'when updating currentUserTodos' do
      let_it_be(:current_user) { guest }

      let(:fields) do
        <<~FIELDS
          workItem {
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
          }
          errors
        FIELDS
      end

      subject(:update_work_item) { post_graphql_mutation(mutation, current_user: current_user) }

      context 'when adding a new todo' do
        let(:input) { { 'currentUserTodosWidget' => { 'action' => 'ADD' } } }

        context 'when user can create todos' do
          it 'adds a new todo for the user on the work item' do
            expect { update_work_item }.to change { current_user.todos.count }.by(1)

            created_todo = current_user.todos.last

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['workItem']['widgets']).to include(
              {
                'type' => 'CURRENT_USER_TODOS',
                'currentUserTodos' => {
                  'nodes' => [
                    { 'id' => created_todo.to_global_id.to_s, 'state' => 'pending' }
                  ]
                }
              }
            )
          end

          context 'when a base attribute is present' do
            before do
              input.merge!('title' => 'new title')
            end

            it_behaves_like 'a mutation that returns top-level errors', errors: [
              'The resource that you are attempting to access does not exist or you don\'t have permission to ' \
              'perform this action'
            ]
          end
        end

        context 'when user has no access' do
          let_it_be(:current_user) { create(:user) }

          it 'does not create a new todo' do
            expect { update_work_item }.to change { Todo.count }.by(0)

            expect(response).to have_gitlab_http_status(:success)
          end
        end
      end

      context 'when marking all todos of the work item as done' do
        let_it_be(:pending_todo1) do
          create(:todo, target: work_item, target_type: 'WorkItem', user: current_user, state: :pending)
        end

        let_it_be(:pending_todo2) do
          create(:todo, target: work_item, target_type: 'WorkItem', user: current_user, state: :pending)
        end

        let(:input) { { 'currentUserTodosWidget' => { 'action' => 'MARK_AS_DONE' } } }

        context 'when user has access' do
          it 'marks all todos of the user on the work item as done' do
            expect { update_work_item }.to change { current_user.todos.done.count }.by(2)

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['workItem']['widgets']).to include(
              {
                'type' => 'CURRENT_USER_TODOS',
                'currentUserTodos' => {
                  'nodes' => match_array([
                    { 'id' => pending_todo1.to_global_id.to_s, 'state' => 'done' },
                    { 'id' => pending_todo2.to_global_id.to_s, 'state' => 'done' }
                  ])
                }
              }
            )
          end
        end

        context 'when user has no access' do
          let_it_be(:current_user) { create(:user) }

          it 'does not mark todos as done' do
            expect { update_work_item }.to change { Todo.done.count }.by(0)

            expect(response).to have_gitlab_http_status(:success)
          end
        end
      end

      context 'when marking one todo of the work item as done' do
        let_it_be(:pending_todo1) do
          create(:todo, target: work_item, target_type: 'WorkItem', user: current_user, state: :pending)
        end

        let_it_be(:pending_todo2) do
          create(:todo, target: work_item, target_type: 'WorkItem', user: current_user, state: :pending)
        end

        let(:input) do
          { 'currentUserTodosWidget' => { 'action' => 'MARK_AS_DONE', todo_id: global_id_of(pending_todo1) } }
        end

        context 'when user has access' do
          it 'marks the todo of the work item as done' do
            expect { update_work_item }.to change { current_user.todos.done.count }.by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['workItem']['widgets']).to include(
              {
                'type' => 'CURRENT_USER_TODOS',
                'currentUserTodos' => {
                  'nodes' => match_array([
                    { 'id' => pending_todo1.to_global_id.to_s, 'state' => 'done' },
                    { 'id' => pending_todo2.to_global_id.to_s, 'state' => 'pending' }
                  ])
                }
              }
            )
          end
        end

        context 'when user has no access' do
          let_it_be(:current_user) { create(:user) }

          it 'does not mark the todo as done' do
            expect { update_work_item }.to change { Todo.done.count }.by(0)

            expect(response).to have_gitlab_http_status(:success)
          end
        end
      end
    end

    context 'when updating awardEmoji' do
      let_it_be(:current_user) { work_item.author }
      let_it_be(:upvote) { create(:award_emoji, :upvote, awardable: work_item, user: current_user) }
      let(:award_action) { 'ADD' }
      let(:award_name) { 'star' }
      let(:input) { { 'awardEmojiWidget' => { 'action' => award_action, 'name' => award_name } } }

      let(:fields) do
        <<~FIELDS
          workItem {
            widgets {
              type
              ... on WorkItemWidgetAwardEmoji {
                upvotes
                downvotes
                awardEmoji {
                  nodes {
                    name
                    user { id }
                  }
                }
              }
            }
          }
          errors
        FIELDS
      end

      subject(:update_work_item) { post_graphql_mutation(mutation, current_user: current_user) }

      context 'when user cannot award work item' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?)
                        .with(current_user, :award_emoji, work_item).and_return(false)
        end

        it 'ignores the update request' do
          expect do
            update_work_item
          end.to not_change(AwardEmoji, :count)

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors']).to be_empty
          expect(graphql_errors).to be_blank
        end
      end

      context 'when user can award work item' do
        shared_examples 'request that removes emoji' do
          it "updates work item's award emoji" do
            expect do
              update_work_item
            end.to change(AwardEmoji, :count).by(-1)

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['workItem']['widgets']).to include(
              {
                'upvotes' => 0,
                'downvotes' => 0,
                'awardEmoji' => { 'nodes' => [] },
                'type' => 'AWARD_EMOJI'
              }
            )
          end
        end

        shared_examples 'request that adds emoji' do
          it "updates work item's award emoji" do
            expect do
              update_work_item
            end.to change(AwardEmoji, :count).by(1)

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['workItem']['widgets']).to include(
              {
                'upvotes' => 1,
                'downvotes' => 0,
                'awardEmoji' => { 'nodes' => [
                  { 'name' => AwardEmoji::THUMBS_UP, 'user' => { 'id' => current_user.to_gid.to_s } },
                  { 'name' => award_name, 'user' => { 'id' => current_user.to_gid.to_s } }
                ] },
                'type' => 'AWARD_EMOJI'
              }
            )
          end
        end

        context 'when adding award emoji' do
          it_behaves_like 'request that adds emoji'

          context 'when the emoji name is not valid' do
            let(:award_name) { 'xxqq' }

            it_behaves_like 'request with error', 'Name is not a valid emoji name'
          end
        end

        context 'when removing award emoji' do
          let(:award_action) { 'REMOVE' }

          context 'when emoji was awarded by current user' do
            let(:award_name) { AwardEmoji::THUMBS_UP }

            it_behaves_like 'request that removes emoji'
          end

          context 'when emoji was awarded by a different user' do
            let(:award_name) { 'thumbsdown' }

            before do
              create(:award_emoji, :downvote, awardable: work_item)
            end

            it_behaves_like 'request with error',
              "User has not awarded emoji of type #{AwardEmoji::THUMBS_DOWN} on the awardable"
          end
        end

        context 'when toggling award emoji' do
          let(:award_action) { 'TOGGLE' }

          context 'when emoji award is present' do
            let(:award_name) { AwardEmoji::THUMBS_UP }

            it_behaves_like 'request that removes emoji'
          end

          context 'when emoji award is not present' do
            it_behaves_like 'request that adds emoji'
          end
        end
      end
    end

    context 'with notes widget input' do
      let(:discussion_locked) { true }
      let(:input) { { 'notesWidget' => { 'discussionLocked' => true } } }

      let(:fields) do
        <<~FIELDS
          workItem {
            widgets {
              type
              ... on WorkItemWidgetNotes {
                discussionLocked
              }
            }
          }
          errors
        FIELDS
      end

      shared_examples 'work item is not updated' do
        it 'ignores the update' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.not_to change(&work_item_change)
        end
      end

      it_behaves_like 'work item is not updated' do
        let(:current_user) { guest }
        let(:work_item_change) { -> { work_item.discussion_locked } }
      end

      context 'when user has permissions to update the work item' do
        let(:current_user) { reporter }

        it 'updates work item discussion locked attribute on notes widget' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            work_item.reload
          end.to change { work_item.discussion_locked }.from(nil).to(true)

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['workItem']['widgets']).to include(
            {
              'discussionLocked' => true,
              'type' => 'NOTES'
            }
          )
        end

        context 'when using quick action' do
          let(:input) { { 'descriptionWidget' => { 'description' => "/lock" } } }

          it 'updates work item discussion locked attribute on notes widget' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to change { work_item.discussion_locked }.from(nil).to(true)

            expect(response).to have_gitlab_http_status(:success)
            expect(mutation_response['workItem']['widgets']).to include(
              {
                'discussionLocked' => true,
                'type' => 'NOTES'
              }
            )
          end

          context 'when unlocking discussion' do
            let(:input) { { 'descriptionWidget' => { 'description' => "/unlock" } } }

            before do
              work_item.update!(discussion_locked: true)
            end

            it 'updates work item discussion locked attribute on notes widget' do
              expect do
                post_graphql_mutation(mutation, current_user: current_user)
                work_item.reload
              end.to change { work_item.discussion_locked }.from(true).to(false)

              expect(response).to have_gitlab_http_status(:success)
            end
          end

          context 'when the work item type does not support the notes widget' do
            let(:input) do
              { 'descriptionWidget' => { 'description' => "Updating notes discussion locked.\n/lock" } }
            end

            before do
              WorkItems::Type.default_by_type(:issue).widget_definitions
                .find_by_widget_type(:notes).update!(disabled: true)
            end

            it_behaves_like 'work item is not updated' do
              let(:work_item_change) { -> { work_item.discussion_locked } }
            end
          end
        end
      end
    end

    context 'with time tracking widget input', time_travel_to: "2024-02-20" do
      shared_examples 'mutation updating work item with time tracking data' do
        it 'updates time tracking' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            mutation_work_item.reload
          end.to change { mutation_work_item.time_estimate }.from(0).to(12.hours.to_i).and(
            change { mutation_work_item.total_time_spent }.from(0).to(2.hours.to_i)
          )

          expect(mutation_response['workItem']['widgets']).to include(
            'timeEstimate' => expected_result[:time_estimate],
            'totalTimeSpent' => expected_result[:time_spent],
            'timelogs' => {
              'nodes' => [
                {
                  'timeSpent' => expected_result[:time_spent],
                  'spentAt' => expected_result[:spent_at],
                  'summary' => expected_result[:summary],
                  'user' => { "username" => current_user.username }
                }
              ]
            },
            'type' => 'TIME_TRACKING'
          )

          expect(mutation_response['workItem']['widgets']).to include(
            'description' => expected_result[:description],
            'type' => 'DESCRIPTION'
          )
        end
      end

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
                    spentAt
                    summary
                    user {
                      username
                    }
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

      let_it_be_with_reload(:group_work_item) { create(:work_item, :task, :group_level, namespace: group) }

      context 'when adding time estimate and time spent' do
        context 'when mutating the work item' do
          let(:spent_at) { 2.days.ago.to_date }
          let(:summary) { "doing testing" }
          let(:input) do
            {
              'timeTrackingWidget' => {
                'timeEstimate' => "12h",
                'timelog' => {
                  'timeSpent' => "2h",
                  'spentAt' => spent_at.strftime("%F"),
                  'summary' => "doing testing"
                }
              }
            }
          end

          let(:expected_result) do
            {
              time_estimate: 12.hours.to_i,
              time_spent: 2.hours.to_i,
              spent_at: spent_at.to_time.utc.strftime("%FT%TZ"),
              summary: summary,
              description: nil
            }
          end

          context 'when work item belongs to a project' do
            it_behaves_like 'mutation updating work item with time tracking data'
          end

          context 'when work item belongs to a group', if: Gitlab.ee? do
            let(:mutation_work_item) { group_work_item }

            before do
              stub_licensed_features(epics: true)
            end

            it_behaves_like 'mutation updating work item with time tracking data'

            context 'without group level work item license' do
              before do
                stub_licensed_features(epics: false)
              end

              it_behaves_like 'a mutation that returns top-level errors', errors: [
                "The resource that you are attempting to access does not exist or you don't have " \
                  "permission to perform this action"
              ]
            end
          end

          context 'when time estimate format is invalid' do
            let(:input) { { 'timeTrackingWidget' => { 'timeEstimate' => "12abc" } } }

            it_behaves_like 'request with error', 'Time estimate must be formatted correctly. For example: 1h 30m.'
          end

          context 'when time spent format is invalid' do
            let(:input) { { 'timeTrackingWidget' => { 'timelog' => { 'timeSpent' => "2abc" } } } }

            it_behaves_like 'request with error', 'Time spent must be formatted correctly. For example: 1h 30m.'
          end
        end

        context 'with quick action' do
          let(:input) { { 'descriptionWidget' => { 'description' => "some description\n\n/estimate 12h\n/spend 2h" } } }
          let(:spent_at) { Date.current }
          let(:expected_result) do
            {
              time_estimate: 12.hours.to_i,
              time_spent: 2.hours.to_i,
              spent_at: spent_at.strftime("%FT%TZ"),
              summary: nil,
              description: "some description"
            }
          end

          context 'when work item belongs to a project' do
            it_behaves_like 'mutation updating work item with time tracking data'
          end

          context 'when work item belongs to a group', if: Gitlab.ee? do
            let(:mutation_work_item) { group_work_item }

            before do
              stub_licensed_features(epics: true)
            end

            it_behaves_like 'mutation updating work item with time tracking data'

            context 'without group level work item license' do
              before do
                stub_licensed_features(epics: false)
              end

              it_behaves_like 'a mutation that returns top-level errors', errors: [
                "The resource that you are attempting to access does not exist or you don't have " \
                  "permission to perform this action"
              ]
            end
          end
        end
      end

      context 'when the work item type does not support time tracking widget' do
        context 'with quick action' do
          let_it_be(:work_item) { create(:work_item, :task, project: project) }

          let(:spent_at) { Date.current }
          let(:input) { { 'descriptionWidget' => { 'description' => "some description\n\n/estimate 12h\n/spend 2h" } } }
          let(:expected_result) do
            {
              time_estimate: 12.hours.to_i,
              time_spent: 2.hours.to_i,
              spent_at: spent_at.strftime("%FT%TZ"),
              summary: nil,
              description: "some description"
            }
          end

          before do
            WorkItems::Type.default_by_type(:task).widget_definitions
              .find_by_widget_type(:time_tracking).update!(disabled: true)
          end

          it 'ignores the quick action' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.not_to change { work_item.time_estimate }

            expect(mutation_response['workItem']['widgets']).to include(
              'description' => "some description",
              'type' => 'DESCRIPTION'
            )
            expect(mutation_response['workItem']['widgets']).not_to include(
              'type' => 'TIME_TRACKING'
            )
          end
        end
      end
    end

    context 'with CRM contacts widget input' do
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

      context 'when adding contacts' do
        let(:input) do
          {
            'crmContactsWidget' => {
              'contactIds' => [global_id_of(contact)]
            }
          }
        end

        it 'updates contacts' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            mutation_work_item.reload
          end.to change { mutation_work_item.customer_relations_contacts.to_a }.from([]).to([
            contact
          ])

          expect(mutation_response['workItem']['widgets']).to include(
            'contacts' => {
              'nodes' => [
                {
                  'id' => global_id_of(contact).to_s,
                  'firstName' => contact.first_name
                }
              ]
            },
            'type' => 'CRM_CONTACTS'
          )
        end
      end

      context 'when clearing contacts' do
        before do
          mutation_work_item.issue_customer_relations_contacts.create!(contact: contact)
        end

        let(:input) do
          {
            'crmContactsWidget' => {
              'contactIds' => []
            }
          }
        end

        it 'updates contacts' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            mutation_work_item.reload
          end.to change { mutation_work_item.customer_relations_contacts.to_a }.from([contact]).to([])

          expect(mutation_response['workItem']['widgets']).to include(
            'contacts' => {
              'nodes' => []
            },
            'type' => 'CRM_CONTACTS'
          )
        end
      end
    end

    context 'when unsupported widget input is sent' do
      let_it_be(:work_item) { create(:work_item, :test_case, project: project) }

      let(:input) do
        {
          'assigneesWidget' => { 'assigneeIds' => [developer.to_gid.to_s] }
        }
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ["Following widget keys are not supported by Test Case type: [:assignees_widget]"]
    end
  end
end
