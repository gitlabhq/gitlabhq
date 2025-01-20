# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Session initializer for GitLab' do
  subject { Gitlab::Application.config }

  before do
    allow(subject).to receive_message_chain(:middleware, :insert_after)
  end

  let(:load_session_store) do
    load Rails.root.join('config/initializers/session_store.rb')
  end

  describe 'config#session_store' do
    it 'initialized as a redis_store with Gitlab::Sessions::CacheStore' do
      expect(subject).to receive(:session_store).with(
        ::Gitlab::Sessions::CacheStore,
        a_hash_including(
          cache: ActiveSupport::Cache::RedisCacheStore
        )
      )

      load_session_store
    end

    context 'when cell.id is configured' do
      before do
        stub_config(cell: { id: 1 })
      end

      it 'initialized as a `redis_store` with session cookies prefix that includes cell id' do
        expect(subject).to receive(:session_store).with(
          ::Gitlab::Sessions::CacheStore,
          a_hash_including(
            cache: ActiveSupport::Cache::RedisCacheStore,
            session_cookie_token_prefix: 'cell-1'
          )
        )

        load_session_store
      end
    end

    context 'when cell.id is not configured' do
      before do
        stub_config(cell: { id: nil })
      end

      it 'initialized as a `redis_store` with empty session cookie prefix' do
        expect(subject).to receive(:session_store).with(
          ::Gitlab::Sessions::CacheStore,
          a_hash_including(
            cache: ActiveSupport::Cache::RedisCacheStore,
            session_cookie_token_prefix: ''
          )
        )

        load_session_store
      end
    end
  end
end
