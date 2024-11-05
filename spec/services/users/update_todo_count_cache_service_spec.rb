# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateTodoCountCacheService, feature_category: :notifications do
  describe '#execute' do
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }

    let_it_be(:todo1) { create(:todo, user: user1, state: :done) }
    let_it_be(:todo2) { create(:todo, user: user1, state: :done) }
    let_it_be(:todo3) { create(:todo, user: user1, state: :pending) }
    let_it_be(:todo4) { create(:todo, user: user2, state: :done) }
    let_it_be(:todo5) { create(:todo, user: user2, state: :pending) }
    let_it_be(:todo6) { create(:todo, user: user2, state: :pending) }

    def execute_all
      described_class.new([user1.id, user2.id]).execute
    end

    def execute_single
      described_class.new([user1.id]).execute
    end

    it 'updates the todos_counts for users', :use_clean_rails_memory_store_caching do
      Rails.cache.write(['users', user1.id, 'todos_done_count'], 0)
      Rails.cache.write(['users', user1.id, 'todos_pending_count'], 0)
      Rails.cache.write(['users', user2.id, 'todos_done_count'], 0)
      Rails.cache.write(['users', user2.id, 'todos_pending_count'], 0)

      expect { execute_all }
        .to change(user1, :todos_done_count).from(0).to(2)
        .and change(user1, :todos_pending_count).from(0).to(1)
        .and change(user2, :todos_done_count).from(0).to(1)
        .and change(user2, :todos_pending_count).from(0).to(2)

      Todo.delete_all

      expect { execute_all }
        .to change(user1, :todos_done_count).from(2).to(0)
        .and change(user1, :todos_pending_count).from(1).to(0)
        .and change(user2, :todos_done_count).from(1).to(0)
        .and change(user2, :todos_pending_count).from(2).to(0)
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new { execute_single }

      expect { execute_all }.not_to exceed_query_limit(control)
    end

    it 'executes one query per batch of users' do
      stub_const("#{described_class}::QUERY_BATCH_SIZE", 1)

      expect(ActiveRecord::QueryRecorder.new { execute_single }.count).to eq(1)
      expect(ActiveRecord::QueryRecorder.new { execute_all }.count).to eq(2)
    end

    it 'sets the correct cache expire time' do
      expect(Rails.cache).to receive(:write)
        .with(['users', user1.id, anything], anything, expires_in: User::COUNT_CACHE_VALIDITY_PERIOD)
        .twice

      execute_single
    end
  end
end
