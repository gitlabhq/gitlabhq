# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UpdateService, feature_category: :team_planning do
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:parent) { create(:work_item, project: project) }
  let_it_be_with_reload(:work_item) { create(:work_item, project: project, assignees: [developer]) }

  let(:widget_params) { {} }
  let(:opts) { {} }
  let(:current_user) { developer }

  before do
    project.add_developer(developer)
    project.add_guest(guest)
  end

  describe '#execute' do
    let(:service) do
      described_class.new(
        container: project,
        current_user: current_user,
        params: opts,
        widget_params: widget_params
      )
    end

    subject(:update_work_item) { service.execute(work_item) }

    shared_examples 'update service that triggers graphql dates updated subscription' do
      it 'triggers graphql subscription issueableDatesUpdated' do
        expect(GraphqlTriggers).to receive(:issuable_dates_updated).with(work_item).and_call_original

        update_work_item
      end
    end

    shared_examples 'publish WorkItems::WorkItemUpdatedEvent event' do |attributes: nil, widgets: nil|
      it do
        expect { expect(update_work_item[:status]).to eq(:success) }
          .to publish_event(WorkItems::WorkItemUpdatedEvent)
          .with({
            id: work_item.id,
            namespace_id: work_item.namespace.id,
            updated_attributes: attributes,
            updated_widgets: widgets
          }.tap(&:compact_blank!))
      end
    end

    shared_examples 'do not publish WorkItems::WorkItemUpdatedEvent event' do
      it do
        expect { update_work_item }.not_to publish_event(WorkItems::WorkItemUpdatedEvent)
      end
    end

    it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event'

    context 'when applying quick actions' do
      let(:opts) { { description: "/shrug" } }

      it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
        attributes: %w[
          description
          description_html
          last_edited_at
          last_edited_by_id
          lock_version
          updated_at
          updated_by_id
        ]

      context 'when work item type is not the default Issue' do
        before do
          task_type = WorkItems::Type.default_by_type(:task)
          work_item.update_columns(work_item_type_id: task_type.id)
        end

        it 'does not apply the quick action' do
          expect do
            update_work_item
          end.to change(work_item, :description).to('/shrug')
        end
      end

      context 'when work item type is the default Issue' do
        let(:issue) { create(:work_item, description: '') }

        it 'applies the quick action' do
          expect do
            update_work_item
          end.to change(work_item, :description).to('¯\＿(ツ)＿/¯')
        end
      end

      it_behaves_like 'issuable record that supports quick actions' do
        let(:opts) { params }
        let(:current_user) { user }
        let(:work_item) { create(:work_item, project: project, description: "some random description") }
        let(:issuable) { update_work_item[:work_item] }
      end

      it_behaves_like 'issuable record that supports quick actions', with_widgets: true do
        let(:opts) { params }
        let(:current_user) { user }
        let(:work_item) { create(:work_item, project: project, description: "some random description") }
        let(:issuable) { update_work_item[:work_item] }
      end

      it_behaves_like 'issuable record does not run quick actions when not editing description' do
        let(:label) { create(:label, project: project) }
        let(:assignee) { create(:user, maintainer_of: project) }
        let(:work_item) { create(:work_item, project: project, description: old_description) }
        let(:opts) { params }
        let(:updated_issuable) { update_work_item[:work_item] }
      end

      it_behaves_like 'issuable record does not run quick actions when not editing description', with_widgets: true do
        let(:label) { create(:label, project: project) }
        let(:assignee) { create(:user, maintainer_of: project) }
        let(:work_item) { create(:work_item, project: project, description: old_description) }
        let(:opts) { params }
        let(:updated_issuable) { update_work_item[:work_item] }
      end

      context 'when work item type is not default issue' do
        # when quick actions are passed in `description` param those are not interpreted and just saved into description
        # as plain text
        #
        # it_behaves_like 'issuable record that does not supports quick actions' do
        #   let(:opts) { params }
        #   let(:current_user) { user }
        #   let(:work_item) { create(:work_item, :task, project: project, description: "some random description") }
        #   let(:issuable) { update_work_item[:work_item] }
        # end

        it_behaves_like 'issuable record that supports quick actions', with_widgets: true do
          let(:opts) { params }
          let(:current_user) { user }
          let(:work_item) { create(:work_item, :task, project: project, description: "some random description") }
          let(:issuable) { update_work_item[:work_item] }
        end
      end

      context 'when work item labels widget is disabled' do
        before do
          widget_definitions = WorkItems::Type.default_by_type(:issue).widget_definitions
          widget_definitions.find_by_widget_type(:labels).update!(disabled: true)
          widget_definitions.find_by_widget_type(:assignees).update!(disabled: true)
        end

        it_behaves_like 'issuable record that does not supports quick actions' do
          let(:opts) { params }
          let(:current_user) { user }
          let(:work_item) { create(:work_item, project: project, description: "some random description") }
          let(:issuable) { update_work_item[:work_item] }
        end

        it_behaves_like 'issuable record that does not supports quick actions', with_widgets: true do
          let(:opts) { params }
          let(:current_user) { user }
          let(:work_item) { create(:work_item, project: project, description: "some random description") }
          let(:issuable) { update_work_item[:work_item] }
        end
      end
    end

    context 'when title is changed' do
      let(:opts) { { title: 'changed' } }

      it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
        attributes: %w[
          lock_version
          title
          title_html
          updated_at
          updated_by_id
        ]

      it 'triggers issuable_title_updated graphql subscription' do
        expect(GraphqlTriggers).to receive(:issuable_title_updated).with(work_item).and_call_original
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).to receive(:track_work_item_title_changed_action).with(author: current_user)
        # During the work item transition we also want to track work items as issues
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_title_changed_action)
        expect(update_work_item[:status]).to eq(:success)
      end

      it_behaves_like 'internal event tracking' do
        let(:event) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_TITLE_CHANGED }
        let(:user) { current_user }
        let(:namespace) { project.namespace }
        subject(:service_action) { update_work_item[:status] }
      end

      it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
        subject(:execute_service) { update_work_item }
      end
    end

    context 'when title is not changed' do
      let(:opts) { { description: 'changed' } }

      it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
        attributes: %w[
          description
          description_html
          last_edited_at
          last_edited_by_id
          lock_version
          updated_at
          updated_by_id
        ]

      it 'does not trigger issuable_title_updated graphql subscription' do
        expect(GraphqlTriggers).not_to receive(:issuable_title_updated)
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).not_to receive(:track_work_item_title_changed_action)
        expect(update_work_item[:status]).to eq(:success)
      end

      it 'does not emit Snowplow event', :snowplow do
        expect_no_snowplow_event

        update_work_item
      end
    end

    context 'when dates are changed' do
      let(:opts) { { start_date: Date.today } }

      it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
        attributes: %w[
          start_date
          updated_at
          updated_by_id
        ]

      it 'tracks users updating work item dates' do
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).to receive(:track_work_item_date_changed_action).with(author: current_user)

        update_work_item
      end

      it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
        subject(:execute_service) { update_work_item }
      end
    end

    context 'when description is changed' do
      let(:opts) { { description: 'description changed' } }

      it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
        attributes: %w[
          description
          description_html
          last_edited_at
          last_edited_by_id
          lock_version
          updated_at
          updated_by_id
        ]

      it 'triggers GraphQL description updated subscription' do
        expect(GraphqlTriggers).to receive(:issuable_description_updated).with(work_item).and_call_original

        update_work_item
      end

      it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
        subject(:execute_service) { update_work_item }
      end
    end

    context 'when description is not changed' do
      let(:opts) { { title: 'title changed' } }

      it 'does not trigger GraphQL description updated subscription' do
        expect(GraphqlTriggers).not_to receive(:issuable_description_updated)

        update_work_item
      end
    end

    context 'when updating state_event' do
      context 'when state_event is close' do
        let(:opts) { { state_event: 'close' } }

        it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
          attributes: %w[
            closed_at
            closed_by_id
            state_id
            updated_at
          ]

        it 'closes the work item' do
          expect do
            update_work_item
            work_item.reload
          end.to change(work_item, :state).from('opened').to('closed')
        end
      end

      context 'when state_event is reopen' do
        let(:opts) { { state_event: 'reopen' } }

        before do
          work_item.close!
        end

        it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
          attributes: %w[
            closed_at
            state_id
            updated_at
          ]

        it 'reopens the work item' do
          expect do
            update_work_item
            work_item.reload
          end.to change(work_item, :state).from('closed').to('opened')
        end
      end
    end

    it_behaves_like 'work item widgetable service' do
      let(:widget_params) do
        {
          hierarchy_widget: { parent: parent },
          description_widget: { description: 'foo' }
        }
      end

      let(:service) do
        described_class.new(
          container: project,
          current_user: current_user,
          params: opts,
          widget_params: widget_params
        )
      end

      let(:service_execute) { service.execute(work_item) }

      let(:supported_widgets) do
        [
          { klass: WorkItems::Callbacks::Description, callback: :after_initialize },
          { klass: WorkItems::Widgets::HierarchyService::UpdateService, callback: :before_update_in_transaction, params: { parent: parent } }
        ]
      end
    end

    context 'when updating widgets' do
      let(:widget_service_class) { WorkItems::Callbacks::Description }
      let(:widget_params) { { description_widget: { description: 'changed' } } }

      context 'when widget service is not present' do
        before do
          allow(widget_service_class).to receive(:new).and_return(nil)
        end

        it 'ignores widget param' do
          expect { update_work_item }.not_to change(work_item, :description)
        end
      end

      context 'when the widget does not support update callback' do
        before do
          allow_next_instance_of(widget_service_class) do |instance|
            allow(instance)
              .to receive(:after_initialize)
              .and_return(nil)
          end
        end

        it 'ignores widget param' do
          expect { update_work_item }.not_to change(work_item, :description)
        end
      end

      context 'for the description widget' do
        it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
          attributes: %w[
            description
            description_html
            last_edited_at
            last_edited_by_id
            lock_version
            updated_at
            updated_by_id
          ],
          widgets: %w[
            description_widget
          ]

        it 'updates the description of the work item' do
          update_work_item

          expect(work_item.description).to eq('changed')
        end

        it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
          subject(:execute_service) { update_work_item }
        end

        context 'with mentions', :mailer, :sidekiq_might_not_need_inline do
          shared_examples 'creates the todo and sends email' do |attribute|
            it 'creates a todo and sends email' do
              expect { perform_enqueued_jobs { update_work_item } }.to change(Todo, :count).by(1)
              expect(work_item.reload.attributes[attribute.to_s]).to eq("mention #{guest.to_reference}")
              should_email(guest)
            end
          end

          context 'when description contains a user mention' do
            let(:widget_params) { { description_widget: { description: "mention #{guest.to_reference}" } } }

            it_behaves_like 'creates the todo and sends email', :description
          end

          context 'when title contains a user mention' do
            let(:opts) { { title: "mention #{guest.to_reference}" } }

            it_behaves_like 'creates the todo and sends email', :title
          end
        end

        context 'when work item validation fails' do
          let(:opts) { { title: '' } }

          it 'returns validation errors' do
            expect(update_work_item[:message]).to contain_exactly("Title can't be blank")
          end

          it 'does not execute after-update widgets', :aggregate_failures do
            expect(service).to receive(:update).and_call_original
            expect(service).not_to receive(:execute_widgets).with(callback: :update, widget_params: widget_params)

            expect do
              update_work_item
              work_item.reload
            end.not_to change(work_item, :description)
          end
        end
      end

      context 'for start and due date widget' do
        let(:updated_date) { 1.week.from_now.to_date }

        it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
          attributes: %w[
            description
            description_html
            last_edited_at
            last_edited_by_id
            lock_version
            updated_at
            updated_by_id
          ],
          widgets: %w[
            description_widget
          ]

        context 'when due_date is updated' do
          let(:widget_params) { { start_and_due_date_widget: { due_date: updated_date } } }

          it_behaves_like 'update service that triggers graphql dates updated subscription'
        end

        context 'when start_date is updated' do
          let(:widget_params) { { start_and_due_date_widget: { start_date: updated_date } } }

          it_behaves_like 'update service that triggers graphql dates updated subscription'
        end

        context 'when no date param is updated' do
          let(:opts) { { title: 'should not trigger' } }

          it 'does not trigger date updated subscription' do
            expect(GraphqlTriggers).not_to receive(:issuable_dates_updated)

            update_work_item
          end
        end
      end

      context 'for the hierarchy widget' do
        let(:opts) { { title: 'changed' } }
        let_it_be(:child_work_item) { create(:work_item, :task, project: project) }

        let(:widget_params) { { hierarchy_widget: { children: [child_work_item] } } }

        it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
          attributes: %w[
            title
            title_html
            lock_version
            updated_at
            updated_by_id
          ],
          widgets: %w[
            hierarchy_widget
          ]

        it 'updates the children of the work item' do
          expect do
            update_work_item
            work_item.reload
          end.to change(WorkItems::ParentLink, :count).by(1)

          expect(work_item.work_item_children).to include(child_work_item)
        end

        it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
          subject(:execute_service) { update_work_item }
        end

        context 'when child type is invalid' do
          let_it_be(:child_work_item) { create(:work_item, project: project) }

          it 'returns error status' do
            expect(subject[:status]).to be(:error)
            expect(subject[:message])
              .to match("#{child_work_item.to_reference} cannot be added: is not allowed to add this type of parent")
          end

          it 'does not update work item attributes' do
            expect do
              update_work_item
              work_item.reload
            end.to not_change(WorkItems::ParentLink, :count).and(not_change(work_item, :title))
          end
        end

        context 'when work item validation fails' do
          let(:opts) { { title: '' } }

          it_behaves_like 'do not publish WorkItems::WorkItemUpdatedEvent event'

          it 'returns validation errors' do
            expect(update_work_item[:message]).to contain_exactly("Title can't be blank")
          end

          it 'does not execute after-update widgets', :aggregate_failures do
            expect(service).to receive(:update).and_call_original
            expect(service).not_to receive(:execute_widgets).with(callback: :before_update_in_transaction, widget_params: widget_params)
            expect(work_item.work_item_children).not_to include(child_work_item)

            update_work_item
          end
        end
      end

      context 'for milestone widget' do
        let_it_be(:milestone) { create(:milestone, project: project) }

        let(:widget_params) { { milestone_widget: { milestone_id: milestone.id } } }

        it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
          attributes: %w[
            milestone_id
            updated_at
            updated_by_id
          ],
          widgets: %w[
            milestone_widget
          ]

        context 'when milestone is updated' do
          it "triggers 'issuableMilestoneUpdated'" do
            expect(work_item.milestone).to eq(nil)
            expect(GraphqlTriggers).to receive(:issuable_milestone_updated).with(work_item).and_call_original

            update_work_item
          end

          it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
            subject(:execute_service) { update_work_item }
          end
        end

        context 'when milestone remains unchanged' do
          before do
            update_work_item
          end

          it "does not trigger 'issuableMilestoneUpdated'" do
            expect(work_item.milestone).to eq(milestone)
            expect(GraphqlTriggers).not_to receive(:issuable_milestone_updated)

            update_work_item
          end
        end
      end

      context 'for current user todos widget' do
        let_it_be(:user_todo) { create(:todo, target: work_item, user: developer, project: project, state: :pending) }
        let_it_be(:other_todo) { create(:todo, target: work_item, user: create(:user), project: project, state: :pending) }

        it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
          attributes: %w[
            description
            description_html
            last_edited_at
            last_edited_by_id
            lock_version
            updated_at
            updated_by_id
          ],
          widgets: %w[
            description_widget
          ]

        context 'when action is mark_as_done' do
          let(:widget_params) { { current_user_todos_widget: { action: 'mark_as_done' } } }

          it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
            attributes: %w[
              updated_at
              updated_by_id
            ],
            widgets: %w[
              current_user_todos_widget
            ]

          it 'marks current user todo as done' do
            expect do
              update_work_item
              user_todo.reload
              other_todo.reload
            end.to change(user_todo, :state).from('pending').to('done').and not_change { other_todo.state }
          end

          it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
            subject(:execute_service) { update_work_item }
          end
        end

        context 'when action is add' do
          let(:widget_params) { { current_user_todos_widget: { action: 'add' } } }

          it 'adds a ToDo for the work item' do
            expect do
              update_work_item
              work_item.reload
            end.to change(Todo, :count).by(1)
          end
        end
      end
    end

    describe 'label updates' do
      let_it_be(:label1) { create(:label, project: project) }
      let_it_be(:label2) { create(:label, project: project) }

      context 'when labels are changed' do
        let(:label) { create(:label, project: project) }
        let(:opts) { { label_ids: [label1.id] } }

        it_behaves_like 'publish WorkItems::WorkItemUpdatedEvent event',
          attributes: %w[
            updated_at
            updated_by_id
          ]

        it 'tracks users updating work item labels' do
          expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).to receive(:track_work_item_labels_changed_action).with(author: current_user)

          update_work_item
        end

        it_behaves_like 'update service that triggers GraphQL work_item_updated subscription' do
          subject(:execute_service) { update_work_item }
        end

        it_behaves_like 'broadcasting issuable labels updates' do
          let(:issuable) { work_item }
          let(:label_a) { label1 }
          let(:label_b) { label2 }

          def update_issuable(update_params)
            described_class.new(
              container: project,
              current_user: current_user,
              params: update_params,
              widget_params: widget_params
            ).execute(work_item)
          end
        end
      end

      context 'when labels are not changed' do
        shared_examples 'work item update that does not track label updates' do
          it 'does not track users updating work item labels' do
            expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).not_to receive(:track_work_item_labels_changed_action)

            update_work_item
          end
        end

        context 'when labels param is not provided' do
          let(:opts) { { title: 'not updating labels' } }

          it_behaves_like 'work item update that does not track label updates'
        end

        context 'when labels param is provided but labels remain unchanged' do
          let(:opts) { { label_ids: [] } }

          it_behaves_like 'work item update that does not track label updates'
        end

        context 'when labels param is provided invalid values' do
          let(:opts) { { label_ids: [non_existing_record_id] } }

          it_behaves_like 'work item update that does not track label updates'
        end
      end
    end
  end
end
