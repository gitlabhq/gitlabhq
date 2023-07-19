# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::CurrentUserTodos, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project, milestone: milestone) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:current_user_todos) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:current_user_todos) }
  end

  describe '.quick_action_params' do
    subject { described_class.quick_action_params }

    it { is_expected.to contain_exactly(:todo_event) }
  end

  describe '.quick_action_commands' do
    subject { described_class.quick_action_commands }

    it { is_expected.to contain_exactly(:todo, :done) }
  end

  describe '.process_quick_action_param' do
    subject { described_class.process_quick_action_param(param_name, param_value) }

    context 'when quick action param is todo_event' do
      let(:param_name) { :todo_event }

      context 'when param value is `done`' do
        let(:param_value) { 'done' }

        it { is_expected.to eq({ action: 'mark_as_done' }) }
      end

      context 'when param value is `add`' do
        let(:param_value) { 'add' }

        it { is_expected.to eq({ action: 'add' }) }
      end
    end

    context 'when quick action param is not todo_event' do
      let(:param_name) { :foo }
      let(:param_value) { 'foo' }

      it { is_expected.to eq({ foo: 'foo' }) }
    end
  end
end
