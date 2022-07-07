# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::HierarchyService::UpdateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:parent_work_item) { create(:work_item, project: project) }
  let_it_be(:child_work_item) { create(:work_item, :task, project: project) }
  let_it_be(:existing_link) { create(:parent_link, work_item: child_work_item, work_item_parent: work_item) }

  let(:widget) { work_item.widgets.find {|widget| widget.is_a?(WorkItems::Widgets::Hierarchy) } }
  let(:not_found_error) { 'No matching task found. Make sure that you are adding a valid task ID.' }

  shared_examples 'raises a WidgetError' do
    it { expect { subject }.to raise_error(described_class::WidgetError, message) }
  end

  describe '#update' do
    subject { described_class.new(widget: widget, current_user: user).before_update_in_transaction(params: params) }

    context 'when parent_id and children_ids params are present' do
      let(:params) { { parent_id: parent_work_item.id, children_ids: [child_work_item.id] } }

      it_behaves_like 'raises a WidgetError' do
        let(:message) { 'A Work Item can be a parent or a child, but not both.' }
      end
    end

    context 'when updating children' do
      let_it_be(:child_work_item2) { create(:work_item, :task, project: project) }
      let_it_be(:child_work_item3) { create(:work_item, :task, project: project) }
      let_it_be(:child_work_item4) { create(:work_item, :task, project: project) }

      context 'when work_items_hierarchy feature flag is disabled' do
        let(:params) { { children_ids: [child_work_item4.id] }}

        before do
          stub_feature_flags(work_items_hierarchy: false)
        end

        it_behaves_like 'raises a WidgetError' do
          let(:message) { '`work_items_hierarchy` feature flag disabled for this project' }
        end
      end

      context 'when user has insufficient permissions to link work items' do
        let(:params) { { children_ids: [child_work_item4.id] }}

        it_behaves_like 'raises a WidgetError' do
          let(:message) { not_found_error }
        end
      end

      context 'when user has sufficient permissions to link work item' do
        before do
          project.add_developer(user)
        end

        context 'with valid params' do
          let(:params) { { children_ids: [child_work_item2.id, child_work_item3.id] }}

          it 'correctly sets work item parent' do
            subject

            expect(work_item.reload.work_item_children)
              .to contain_exactly(child_work_item, child_work_item2, child_work_item3)
          end
        end

        context 'when child is already assigned' do
          let(:params) { { children_ids: [child_work_item.id] }}

          it_behaves_like 'raises a WidgetError' do
            let(:message) { 'Task(s) already assigned' }
          end
        end

        context 'when child type is invalid' do
          let_it_be(:child_issue) { create(:work_item, project: project) }

          let(:params) { { children_ids: [child_issue.id] }}

          it_behaves_like 'raises a WidgetError' do
            let(:message) do
              "#{child_issue.to_reference} cannot be added: Only Task can be assigned as a child in hierarchy."
            end
          end
        end
      end
    end

    context 'when updating parent' do
      let_it_be(:work_item) { create(:work_item, :task, project: project) }

      let(:params) {{ parent_id: parent_work_item.id } }

      context 'when work_items_hierarchy feature flag is disabled' do
        before do
          stub_feature_flags(work_items_hierarchy: false)
        end

        it_behaves_like 'raises a WidgetError' do
          let(:message) { '`work_items_hierarchy` feature flag disabled for this project' }
        end
      end

      context 'when parent_id does not match an existing work item' do
        let(:invalid_id) { non_existing_record_iid }
        let(:params) {{ parent_id: invalid_id } }

        it_behaves_like 'raises a WidgetError' do
          let(:message) { "No Work Item found with ID: #{invalid_id}." }
        end
      end

      context 'when user has insufficient permissions to link work items' do
        it_behaves_like 'raises a WidgetError' do
          let(:message) { not_found_error }
        end
      end

      context 'when user has sufficient permissions to link work item' do
        before do
          project.add_developer(user)
        end

        it 'correctly sets work item parent' do
          subject

          expect(work_item.work_item_parent).to eq(parent_work_item)
        end

        context 'when type is invalid' do
          let_it_be(:parent_task) { create(:work_item, :task, project: project)}

          let(:params) {{ parent_id: parent_task.id } }

          it_behaves_like 'raises a WidgetError' do
            let(:message) { "#{work_item.to_reference} cannot be added: Only Issue can be parent of Task." }
          end
        end
      end
    end
  end
end
