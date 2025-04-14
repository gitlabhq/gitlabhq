# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::CursorStore, :clean_gitlab_redis_shared_state, feature_category: :shared do
  let(:namespace) { SecureRandom.uuid }
  let(:cursor_store) { described_class.new(namespace, ttl: 1.hour) }
  let(:payload) { { foo: namespace } }

  describe '#commit' do
    subject(:commit_cursor) { cursor_store.commit(payload) }

    it 'stores the given payload on redis' do
      expect { commit_cursor }.to change { data_on_redis }.from({}).to({ 'foo' => namespace, 'ex' => '3600' })
    end
  end

  describe '#cursor' do
    subject { cursor_store.cursor }

    before do
      Gitlab::Redis::SharedState.with { |redis| redis.hset(namespace, payload, ex: 24.hours.to_i) }
    end

    it { is_expected.to eq({ 'foo' => namespace }) }
  end

  def data_on_redis
    Gitlab::Redis::SharedState.with { |redis| redis.hgetall(namespace) }
  end
end
