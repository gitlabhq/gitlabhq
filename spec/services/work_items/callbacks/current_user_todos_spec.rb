# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Callbacks::CurrentUserTodos, feature_category: :notifications do
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: reporter) }
  let_it_be(:current_user) { reporter }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let_it_be(:pending_todo1) do
    create(:todo, state: :pending, target: work_item, target_type: work_item.class.name, user: current_user)
  end

  let_it_be(:pending_todo2) do
    create(:todo, state: :pending, target: work_item, target_type: work_item.class.name, user: current_user)
  end

  let_it_be(:done_todo) do
    create(:todo, state: :done, target: work_item, target_type: work_item.class.name, user: current_user)
  end

  let_it_be(:other_work_item_todo) { create(:todo, state: :pending, target: create(:work_item), user: current_user) }
  let_it_be(:other_user_todo) do
    create(:todo, state: :pending, target: work_item, target_type: work_item.class.name, user: create(:user))
  end

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Callbacks::CurrentUserTodos) } }

  describe '#before_update_in_transaction' do
    subject(:service) do
      described_class.new(issuable: work_item, current_user: current_user, params: params)
        .before_update
    end

    context 'when adding a todo' do
      let(:params) { { action: "add" } }

      context 'when user has no access' do
        let(:current_user) { create(:user) }

        it 'does add a todo' do
          expect { service }.not_to change { Todo.count }
        end
      end

      context 'when user has access' do
        let(:params) { { action: "add" } }

        it 'creates a new todo for the user and the work item' do
          expect { service }.to change { current_user.todos.count }.by(1)

          todo = current_user.todos.last

          expect(todo.target.id).to eq(work_item.id)
          expect(todo).to be_pending
        end
      end
    end

    context 'when marking as done' do
      let(:params) { { action: "mark_as_done" } }

      context 'when user has no access' do
        let(:current_user) { create(:user) }

        it 'does not change todo status' do
          service

          expect(pending_todo1.reload).to be_pending
          expect(pending_todo2.reload).to be_pending
          expect(other_work_item_todo.reload).to be_pending
          expect(other_user_todo.reload).to be_pending
        end
      end

      context 'when resolving all todos of the work item', :aggregate_failures do
        it 'resolves todos of the user for the work item' do
          service

          expect(pending_todo1.reload).to be_done
          expect(pending_todo2.reload).to be_done
          expect(other_work_item_todo.reload).to be_pending
          expect(other_user_todo.reload).to be_pending
        end
      end

      context 'when resolving a specific todo', :aggregate_failures do
        let(:params) { { action: "mark_as_done", todo_id: pending_todo1.id } }

        it 'resolves todos of the user for the work item' do
          service

          expect(pending_todo1.reload).to be_done
          expect(pending_todo2.reload).to be_pending
          expect(other_work_item_todo.reload).to be_pending
          expect(other_user_todo.reload).to be_pending
        end
      end
    end
  end
end
