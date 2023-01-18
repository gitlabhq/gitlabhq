# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLinks::CreateService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:work_item) { create(:work_item, project: project) }
    let_it_be(:task) { create(:work_item, :task, project: project) }
    let_it_be(:task1) { create(:work_item, :task, project: project) }
    let_it_be(:task2) { create(:work_item, :task, project: project) }
    let_it_be(:guest_task) { create(:work_item, :task) }
    let_it_be(:invalid_task) { build_stubbed(:work_item, :task, id: non_existing_record_id) }
    let_it_be(:another_project) { (create :project) }
    let_it_be(:other_project_task) { create(:work_item, :task, iid: 100, project: another_project) }
    let_it_be(:existing_parent_link) { create(:parent_link, work_item: task, work_item_parent: work_item) }

    let(:parent_link_class) { WorkItems::ParentLink }
    let(:issuable_type) { :task }
    let(:params) { {} }

    before do
      project.add_reporter(user)
      project.add_guest(guest)
      guest_task.project.add_guest(user)
      another_project.add_reporter(user)
    end

    shared_examples 'returns not found error' do
      it 'returns error' do
        error = "No matching work item found. Make sure that you are adding a valid work item ID."

        is_expected.to eq(service_error(error))
      end

      it 'no relationship is created' do
        expect { subject }.not_to change(parent_link_class, :count)
      end
    end

    subject { described_class.new(work_item, user, params).execute }

    context 'when the reference list is empty' do
      let(:params) { { issuable_references: [] } }

      it_behaves_like 'returns not found error'
    end

    context 'when work item not found' do
      let(:params) { { issuable_references: [invalid_task] } }

      it_behaves_like 'returns not found error'
    end

    context 'when user has no permission to link work items' do
      let(:params) { { issuable_references: [guest_task] } }

      it_behaves_like 'returns not found error'
    end

    context 'child and parent are the same work item' do
      let(:params) { { issuable_references: [work_item] } }

      it 'no relationship is created' do
        expect { subject }.not_to change(parent_link_class, :count)
      end
    end

    context 'when there are tasks to relate' do
      let(:params) { { issuable_references: [task1, task2] } }

      it 'creates relationships', :aggregate_failures do
        expect { subject }.to change(parent_link_class, :count).by(2)

        tasks_parent = parent_link_class.where(work_item: [task1, task2]).map(&:work_item_parent).uniq
        expect(tasks_parent).to match_array([work_item])
      end

      it 'returns success status and created links', :aggregate_failures do
        expect(subject.keys).to match_array([:status, :created_references])
        expect(subject[:status]).to eq(:success)
        expect(subject[:created_references].map(&:work_item_id)).to match_array([task1.id, task2.id])
      end

      it 'creates notes', :aggregate_failures do
        subject

        work_item_notes = work_item.notes.last(2)
        expect(work_item_notes.first.note).to eq("added #{task1.to_reference} as child task")
        expect(work_item_notes.last.note).to eq("added #{task2.to_reference} as child task")
        expect(task1.notes.last.note).to eq("added #{work_item.to_reference} as parent issue")
        expect(task2.notes.last.note).to eq("added #{work_item.to_reference} as parent issue")
      end

      context 'when task is already assigned' do
        let(:params) { { issuable_references: [task, task2] } }

        it 'creates links only for non related tasks', :aggregate_failures do
          expect { subject }.to change(parent_link_class, :count).by(1)

          expect(subject[:created_references].map(&:work_item_id)).to match_array([task2.id])
          expect(work_item.notes.last.note).to eq("added #{task2.to_reference} as child task")
          expect(task2.notes.last.note).to eq("added #{work_item.to_reference} as parent issue")
          expect(task.notes).to be_empty
        end
      end

      context 'when there are invalid children' do
        let_it_be(:issue) { create(:work_item, project: project) }

        let(:params) { { issuable_references: [task1, issue, other_project_task] } }

        it 'creates links only for valid children' do
          expect { subject }.to change { parent_link_class.count }.by(1)
        end

        it 'returns error status' do
          error = "#{issue.to_reference} cannot be added: is not allowed to add this type of parent. " \
            "#{other_project_task.to_reference} cannot be added: parent must be in the same project as child."

          is_expected.to eq(service_error(error, http_status: 422))
        end

        it 'creates notes for valid links' do
          subject

          expect(work_item.notes.last.note).to eq("added #{task1.to_reference} as child task")
          expect(task1.notes.last.note).to eq("added #{work_item.to_reference} as parent issue")
          expect(issue.notes).to be_empty
          expect(other_project_task.notes).to be_empty
        end
      end

      context 'when parent type is invalid' do
        let(:work_item) { create :work_item, :task, project: project }

        let(:params) { { target_issuable: task1 } }

        it 'returns error status' do
          error = "#{task1.to_reference} cannot be added: is not allowed to add this type of parent"

          is_expected.to eq(service_error(error, http_status: 422))
        end
      end

      context 'when max depth is reached' do
        let(:params) { { issuable_references: [task2] } }

        before do
          stub_const("#{parent_link_class}::MAX_CHILDREN", 1)
        end

        it 'returns error status' do
          error = "#{task2.to_reference} cannot be added: parent already has maximum number of children."

          is_expected.to eq(service_error(error, http_status: 422))
        end
      end

      context 'when params include invalid ids' do
        let(:params) { { issuable_references: [task1, invalid_task] } }

        it 'creates links only for valid IDs' do
          expect { subject }.to change(parent_link_class, :count).by(1)
        end
      end

      context 'when user is a guest' do
        let(:user) { guest }

        it_behaves_like 'returns not found error'
      end

      context 'when user is a guest assigned to the work item' do
        let(:user) { guest }

        before do
          work_item.assignees = [guest]
        end

        it_behaves_like 'returns not found error'
      end
    end
  end

  def service_error(message, http_status: 404)
    {
      message: message,
      status: :error,
      http_status: http_status
    }
  end
end
