# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::SnoozingService, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let(:service) { described_class.new }

  describe '#snooze_todo' do
    let_it_be(:time1) { Time.utc(2024, 9, 12, 19, 0, 0) }
    let_it_be(:time2) { Time.utc(2024, 9, 13, 3, 0, 0) }

    context 'when the todo has not been snoozed yet' do
      let!(:todo) { create(:todo, :pending, user: user) }

      it 'snoozes the todo until the provided time' do
        expect do
          service.snooze_todo(todo, time1)
          todo.reload
        end.to change { todo.snoozed_until }.to(time1)
      end
    end

    context 'when the todo is already snoozed' do
      let!(:todo) { create(:todo, :pending, snoozed_until: time1, user: user) }

      it 'changes the snoozed_until timestamp' do
        service.snooze_todo(todo, time2)
        todo.reload

        expect(todo.snoozed_until).to eq(time2)
      end
    end

    context 'when the update fails' do
      let!(:todo) { create(:todo, :pending, user: user) }

      before do
        allow(todo).to receive(:update).and_return(false)

        errors = ActiveModel::Errors.new(todo)
        errors.add(:base, 'An error occurred')
        allow(todo).to receive(:errors).and_return(errors)
      end

      it 'raises an error' do
        response = service.snooze_todo(todo, time1)

        expect(response).to be_error
        expect(response.message).to eq(["An error occurred"])
      end
    end
  end

  describe '#un_snooze_todo' do
    let_it_be(:snoozed_until) { Time.utc(2024, 9, 12, 19, 0, 0) }
    let!(:todo) { create(:todo, :pending, snoozed_until: snoozed_until, user: user) }

    context 'when the todo is snoozed' do
      it 'un-snoozes the todo' do
        expect do
          service.un_snooze_todo(todo)
          todo.reload
        end.to change { todo.snoozed_until }.to(nil)
      end
    end

    context 'when the update fails' do
      before do
        allow(todo).to receive(:update).and_return(false)

        errors = ActiveModel::Errors.new(todo)
        errors.add(:base, 'An error occurred')
        allow(todo).to receive(:errors).and_return(errors)
      end

      it 'raises an error' do
        response = service.un_snooze_todo(todo)

        expect(response).to be_error
        expect(response.message).to eq(["An error occurred"])
      end
    end
  end

  describe '#snooze_todos' do
    let_it_be(:time) { 8.hours.from_now }
    let_it_be(:todo1) { create(:todo, :pending, user: user) }
    let_it_be(:todo2) { create(:todo, :pending, user: user, snoozed_until: 1.hour.ago) }
    let(:todos) { Todo.where(id: [todo1.id, todo2.id]) }

    it 'snoozes all todos until the provided time' do
      service.snooze_todos(todos, time)

      expect(todo1.reload.snoozed_until).to be_within(1.second).of(time)
      expect(todo2.reload.snoozed_until).to be_within(1.second).of(time)
    end

    it 'responds with the updated todo ids' do
      response = service.snooze_todos(todos, time)

      expect(response).to match_array [todo1.id, todo2.id]
    end
  end

  describe '#unsnooze_todos' do
    let_it_be(:todo1) { create(:todo, :pending, user: user, snoozed_until: 1.day.from_now) }
    let_it_be(:todo2) { create(:todo, :pending, user: user, snoozed_until: nil) }
    let(:todos) { Todo.where(id: [todo1.id, todo2.id]) }

    it 'unsnoozes all todos' do
      service.unsnooze_todos(todos)

      expect(todo1.reload.snoozed_until).to be_nil
      expect(todo2.reload.snoozed_until).to be_nil
    end

    it 'responds with the updated todo ids' do
      response = service.unsnooze_todos(todos)

      expect(response).to match_array [todo1.id, todo2.id]
    end
  end
end
