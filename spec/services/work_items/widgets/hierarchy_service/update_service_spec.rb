# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::HierarchyService::UpdateService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:parent_work_item) { create(:work_item, project: project) }
  let_it_be(:child_work_item) { create(:work_item, :task, project: project) }
  let_it_be(:existing_link) { create(:parent_link, work_item: child_work_item, work_item_parent: work_item) }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Hierarchy) } }
  let(:not_found_error) { 'No matching work item found. Make sure that you are adding a valid work item ID.' }

  shared_examples 'raises a WidgetError' do
    it { expect { subject }.to raise_error(described_class::WidgetError, message) }
  end

  describe '#update' do
    subject { described_class.new(widget: widget, current_user: user).before_update_in_transaction(params: params) }

    context 'when parent and children params are present' do
      let(:params) { { parent: parent_work_item, children: [child_work_item] } }

      it_behaves_like 'raises a WidgetError' do
        let(:message) { 'A Work Item can be a parent or a child, but not both.' }
      end
    end

    context 'when invalid params are present' do
      let(:params) { { other_parent: parent_work_item } }

      it_behaves_like 'raises a WidgetError' do
        let(:message) { 'One or more arguments are invalid: other_parent.' }
      end
    end

    context 'when updating children' do
      let_it_be(:child_work_item2) { create(:work_item, :task, project: project) }
      let_it_be(:child_work_item3) { create(:work_item, :task, project: project) }
      let_it_be(:child_work_item4) { create(:work_item, :task, project: project) }

      context 'when user has insufficient permissions to link work items' do
        let(:params) { { children: [child_work_item4] } }

        it_behaves_like 'raises a WidgetError' do
          let(:message) { not_found_error }
        end
      end

      context 'when user has sufficient permissions to link work item' do
        before do
          project.add_developer(user)
        end

        context 'with valid params' do
          let(:params) { { children: [child_work_item2, child_work_item3] } }

          it 'correctly sets work item parent' do
            subject

            expect(work_item.reload.work_item_children)
              .to contain_exactly(child_work_item, child_work_item2, child_work_item3)
          end
        end

        context 'when child is already assigned' do
          let(:params) { { children: [child_work_item] } }

          it_behaves_like 'raises a WidgetError' do
            let(:message) { 'Work item(s) already assigned' }
          end
        end

        context 'when child type is invalid' do
          let_it_be(:child_issue) { create(:work_item, project: project) }

          let(:params) { { children: [child_issue] } }

          it_behaves_like 'raises a WidgetError' do
            let(:message) do
              "#{child_issue.to_reference} cannot be added: is not allowed to add this type of parent"
            end
          end
        end
      end
    end

    context 'when updating parent' do
      let_it_be(:work_item) { create(:work_item, :task, project: project) }

      let(:params) { { parent: parent_work_item } }

      context 'when user has insufficient permissions to link work items' do
        it_behaves_like 'raises a WidgetError' do
          let(:message) { not_found_error }
        end
      end

      context 'when user has sufficient permissions to link work item' do
        before do
          project.add_developer(user)
        end

        it 'correctly sets new parent' do
          expect(subject[:status]).to eq(:success)
          expect(work_item.work_item_parent).to eq(parent_work_item)
        end

        context 'when parent is nil' do
          let(:params) { { parent: nil } }

          it 'removes the work item parent if present' do
            work_item.update!(work_item_parent: parent_work_item)

            expect do
              subject
              work_item.reload
            end.to change(work_item, :work_item_parent).from(parent_work_item).to(nil)
          end

          it 'returns success status if parent not present', :aggregate_failure do
            work_item.update!(work_item_parent: nil)

            expect(subject[:status]).to eq(:success)
            expect(work_item.reload.work_item_parent).to be_nil
          end
        end

        context 'when type is invalid' do
          let_it_be(:parent_task) { create(:work_item, :task, project: project) }

          let(:params) { { parent: parent_task } }

          it_behaves_like 'raises a WidgetError' do
            let(:message) do
              "#{work_item.to_reference} cannot be added: is not allowed to add this type of parent"
            end
          end
        end
      end
    end
  end
end
