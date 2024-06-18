# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Components::Usages::Aggregators::Cursor, :clean_gitlab_redis_shared_state,
  feature_category: :pipeline_composition do
  let(:redis_key) { 'my_redis_key:cursor' }
  let(:target_model) { class_double(Ci::Catalog::Resource, maximum: max_target_id) }
  let(:max_target_id) { initial_redis_attributes[:target_id] }

  let(:usage_window) { described_class::Window.new(Date.parse('2024-01-08'), Date.parse('2024-01-14')) }
  let(:initial_redis_usage_window) { usage_window }

  let(:initial_redis_attributes) do
    {
      target_id: 1,
      usage_window: initial_redis_usage_window.to_h,
      last_used_by_project_id: 100,
      last_usage_count: 10
    }
  end

  subject(:cursor) { described_class.new(redis_key: redis_key, target_model: target_model, usage_window: usage_window) }

  before do
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(redis_key, initial_redis_attributes.to_json)
    end
  end

  describe '.new' do
    it 'fetches and parses the attributes from Redis' do
      expect(cursor.attributes).to include(initial_redis_attributes)
    end

    context 'when Redis usage_window is different than the given usage_window' do
      let(:initial_redis_usage_window) do
        described_class::Window.new(Date.parse('2024-01-01'), Date.parse('2024-01-07'))
      end

      it 'resets last usage attributes' do
        expect(cursor.attributes).to include({
          target_id: initial_redis_attributes[:target_id],
          usage_window: usage_window.to_h,
          last_used_by_project_id: 0,
          last_usage_count: 0
        })
      end
    end

    context 'when cursor does not exist in Redis' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.del(redis_key)
        end
      end

      it 'sets target_id and last usage attributes to zero' do
        expect(cursor.attributes).to include({
          target_id: 0,
          usage_window: usage_window.to_h,
          last_used_by_project_id: 0,
          last_usage_count: 0
        })
      end
    end
  end

  describe '#interrupt!' do
    it 'updates last usage attributes and sets interrupted? to true' do
      expect(cursor.interrupted?).to eq(false)

      cursor.interrupt!(
        last_used_by_project_id: initial_redis_attributes[:last_used_by_project_id] + 1,
        last_usage_count: initial_redis_attributes[:last_usage_count] + 1
      )

      expect(cursor.interrupted?).to eq(true)
      expect(cursor.attributes).to include({
        target_id: initial_redis_attributes[:target_id],
        usage_window: usage_window.to_h,
        last_used_by_project_id: initial_redis_attributes[:last_used_by_project_id] + 1,
        last_usage_count: initial_redis_attributes[:last_usage_count] + 1
      })
    end
  end

  describe '#target_id=(target_id)' do
    context 'when new target_id is different from cursor target_id' do
      it 'sets new target_id and resets last usage attributes' do
        cursor.target_id = initial_redis_attributes[:target_id] + 1

        expect(cursor.attributes).to include({
          target_id: initial_redis_attributes[:target_id] + 1,
          usage_window: usage_window.to_h,
          last_used_by_project_id: 0,
          last_usage_count: 0
        })
      end
    end

    context 'when new target_id is the same as cursor target_id' do
      it 'does not change cursor attributes' do
        expect(cursor.attributes).to include(initial_redis_attributes)
      end
    end
  end

  describe '#advance' do
    context 'when cursor target_id is less than max_target_id' do
      let(:max_target_id) { initial_redis_attributes[:target_id] + 100 }

      it 'increments cursor target_id and resets last usage attributes' do
        cursor.advance

        expect(cursor.attributes).to eq({
          target_id: initial_redis_attributes[:target_id] + 1,
          usage_window: usage_window.to_h,
          last_used_by_project_id: 0,
          last_usage_count: 0,
          max_target_id: max_target_id
        })
      end
    end

    context 'when cursor target_id is equal to or greater than max_target_id' do
      it 'resets cursor target_id and last usage attributes' do
        cursor.advance

        expect(cursor.attributes).to eq({
          target_id: 0,
          usage_window: usage_window.to_h,
          last_used_by_project_id: 0,
          last_usage_count: 0,
          max_target_id: max_target_id
        })
      end
    end
  end

  describe '#save!' do
    it 'saves cursor attributes except max_target_id to Redis as JSON' do
      cursor.target_id = 11
      cursor.interrupt!(
        last_used_by_project_id: 33,
        last_usage_count: 22
      )

      cursor.save!
      data = Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }

      expect(data).to eq('{"target_id":11,"usage_window":{"start_date":"2024-01-08","end_date":"2024-01-14"},' \
                         '"last_used_by_project_id":33,"last_usage_count":22}')
    end
  end
end
