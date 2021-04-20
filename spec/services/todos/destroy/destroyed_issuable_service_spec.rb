# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::Destroy::DestroyedIssuableService do
  describe '#execute' do
    let_it_be(:target) { create(:merge_request) }
    let_it_be(:pending_todo) { create(:todo, :pending, project: target.project, target: target, user: create(:user)) }
    let_it_be(:done_todo) { create(:todo, :done, project: target.project, target: target, user: create(:user)) }

    def execute
      described_class.new(target.id, target.class.name).execute
    end

    it 'deletes todos for specified target ID and type' do
      control_count = ActiveRecord::QueryRecorder.new { execute }.count

      # Create more todos for the target
      create(:todo, :pending, project: target.project, target: target, user: create(:user))
      create(:todo, :pending, project: target.project, target: target, user: create(:user))
      create(:todo, :done, project: target.project, target: target, user: create(:user))
      create(:todo, :done, project: target.project, target: target, user: create(:user))

      expect { execute }.not_to exceed_query_limit(control_count)
      expect(target.reload.todos.count).to eq(0)
    end

    it 'invalidates todos cache counts of todo users', :use_clean_rails_redis_caching do
      expect { execute }
        .to change { pending_todo.user.todos_pending_count }.from(1).to(0)
        .and change { done_todo.user.todos_done_count }.from(1).to(0)
    end
  end
end
