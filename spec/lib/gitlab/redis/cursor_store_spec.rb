# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::CursorStore, :clean_gitlab_redis_shared_state, feature_category: :shared do
  let(:namespace) { SecureRandom.uuid }
  let(:cache_key) { "CursorStore:#{namespace}" }
  let(:cursor_store) { described_class.new(namespace, ttl: 1.hour) }
  let(:payload) { { foo: namespace } }

  describe '#commit' do
    subject(:commit_cursor) { cursor_store.commit(payload) }

    it 'stores the given payload on redis' do
      expect { commit_cursor }.to change { data_on_redis }.from(nil).to(payload.to_json)
    end
  end

  describe '#cursor' do
    subject { cursor_store.cursor }

    context 'when there is no cursor stored' do
      it { is_expected.to eq({}) }
    end

    context 'when there is already a cursor stored' do
      before do
        Gitlab::Redis::SharedState.with { |redis| redis.set(cache_key, payload.to_json, ex: 24.hours.to_i) }
      end

      it { is_expected.to eq({ 'foo' => namespace }) }
    end
  end

  def data_on_redis
    Gitlab::Redis::SharedState.with { |redis| redis.get(cache_key) }
  end
end
