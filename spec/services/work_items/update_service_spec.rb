# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UpdateService do
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project).tap { |proj| proj.add_developer(developer) } }
  let_it_be(:parent) { create(:work_item, project: project) }
  let_it_be_with_reload(:work_item) { create(:work_item, project: project, assignees: [developer]) }

  let(:spam_params) { double }
  let(:widget_params) { {} }
  let(:opts) { {} }
  let(:current_user) { developer }

  describe '#execute' do
    let(:service) do
      described_class.new(
        project: project,
        current_user: current_user,
        params: opts,
        spam_params: spam_params,
        widget_params: widget_params
      )
    end

    subject(:update_work_item) { service.execute(work_item) }

    before do
      stub_spam_services
    end

    context 'when title is changed' do
      let(:opts) { { title: 'changed' } }

      it 'triggers issuable_title_updated graphql subscription' do
        expect(GraphqlTriggers).to receive(:issuable_title_updated).with(work_item).and_call_original
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).to receive(:track_work_item_title_changed_action).with(author: current_user)
        # During the work item transition we also want to track work items as issues
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_title_changed_action)
        expect(update_work_item[:status]).to eq(:success)
      end
    end

    context 'when title is not changed' do
      let(:opts) { { description: 'changed' } }

      it 'does not trigger issuable_title_updated graphql subscription' do
        expect(GraphqlTriggers).not_to receive(:issuable_title_updated)
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).not_to receive(:track_work_item_title_changed_action)
        expect(update_work_item[:status]).to eq(:success)
      end
    end

    context 'when updating state_event' do
      context 'when state_event is close' do
        let(:opts) { { state_event: 'close' } }

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
          project: project,
          current_user: current_user,
          params: opts,
          spam_params: spam_params,
          widget_params: widget_params
        )
      end

      let(:service_execute) { service.execute(work_item) }

      let(:supported_widgets) do
        [
          { klass: WorkItems::Widgets::DescriptionService::UpdateService, callback: :update, params: { description: 'foo' } },
          { klass: WorkItems::Widgets::HierarchyService::UpdateService, callback: :before_update_in_transaction, params: { parent: parent } }
        ]
      end
    end

    context 'when updating widgets' do
      let(:widget_service_class) { WorkItems::Widgets::DescriptionService::UpdateService }
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
              .to receive(:update)
              .with(params: { description: 'changed' }).and_return(nil)
          end
        end

        it 'ignores widget param' do
          expect { update_work_item }.not_to change(work_item, :description)
        end
      end

      context 'for the description widget' do
        it 'updates the description of the work item' do
          update_work_item

          expect(work_item.description).to eq('changed')
        end

        context 'when work item validation fails' do
          let(:opts) { { title: '' } }

          it 'returns validation errors' do
            expect(update_work_item[:message]).to contain_exactly("Title can't be blank")
          end

          it 'does not execute after-update widgets', :aggregate_failures do
            expect(service).to receive(:update).and_call_original
            expect(service).not_to receive(:execute_widgets).with(callback: :update, widget_params: widget_params)

            expect { update_work_item }.not_to change(work_item, :description)
          end
        end
      end

      context 'for the hierarchy widget' do
        let(:opts) { { title: 'changed' } }
        let_it_be(:child_work_item) { create(:work_item, :task, project: project) }

        let(:widget_params) { { hierarchy_widget: { children: [child_work_item] } } }

        it 'updates the children of the work item' do
          expect do
            update_work_item
            work_item.reload
          end.to change(WorkItems::ParentLink, :count).by(1)

          expect(work_item.work_item_children).to include(child_work_item)
        end

        context 'when child type is invalid' do
          let_it_be(:child_work_item) { create(:work_item, project: project) }

          it 'returns error status' do
            expect(subject[:status]).to be(:error)
            expect(subject[:message])
              .to match("#{child_work_item.to_reference} cannot be added: only Task can be assigned as a child in hierarchy.")
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
    end
  end
end
