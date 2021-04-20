# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateTodoCountCacheService do
  describe '#execute' do
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }

    let_it_be(:todo1) { create(:todo, user: user1, state: :done) }
    let_it_be(:todo2) { create(:todo, user: user1, state: :done) }
    let_it_be(:todo3) { create(:todo, user: user1, state: :pending) }
    let_it_be(:todo4) { create(:todo, user: user2, state: :done) }
    let_it_be(:todo5) { create(:todo, user: user2, state: :pending) }
    let_it_be(:todo6) { create(:todo, user: user2, state: :pending) }

    it 'updates the todos_counts for users', :use_clean_rails_memory_store_caching do
      Rails.cache.write(['users', user1.id, 'todos_done_count'], 0)
      Rails.cache.write(['users', user1.id, 'todos_pending_count'], 0)
      Rails.cache.write(['users', user2.id, 'todos_done_count'], 0)
      Rails.cache.write(['users', user2.id, 'todos_pending_count'], 0)

      expect { described_class.new([user1, user2]).execute }
        .to change(user1, :todos_done_count).from(0).to(2)
        .and change(user1, :todos_pending_count).from(0).to(1)
        .and change(user2, :todos_done_count).from(0).to(1)
        .and change(user2, :todos_pending_count).from(0).to(2)

      Todo.delete_all

      expect { described_class.new([user1, user2]).execute }
        .to change(user1, :todos_done_count).from(2).to(0)
        .and change(user1, :todos_pending_count).from(1).to(0)
        .and change(user2, :todos_done_count).from(1).to(0)
        .and change(user2, :todos_pending_count).from(2).to(0)
    end

    it 'avoids N+1 queries' do
      control_count = ActiveRecord::QueryRecorder.new { described_class.new([user1]).execute }.count

      expect { described_class.new([user1, user2]).execute }.not_to exceed_query_limit(control_count)
    end

    it 'executes one query per batch of users' do
      stub_const("#{described_class}::QUERY_BATCH_SIZE", 1)

      expect(ActiveRecord::QueryRecorder.new { described_class.new([user1]).execute }.count).to eq(1)
      expect(ActiveRecord::QueryRecorder.new { described_class.new([user1, user2]).execute }.count).to eq(2)
    end

    it 'sets the cache expire time to the users count_cache_validity_period' do
      allow(user1).to receive(:count_cache_validity_period).and_return(1.minute)
      allow(user2).to receive(:count_cache_validity_period).and_return(1.hour)

      expect(Rails.cache).to receive(:write).with(['users', user1.id, anything], anything, expires_in: 1.minute).twice
      expect(Rails.cache).to receive(:write).with(['users', user2.id, anything], anything, expires_in: 1.hour).twice

      described_class.new([user1, user2]).execute
    end
  end
end
