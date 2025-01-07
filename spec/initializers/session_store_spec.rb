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
    it 'initialized as a redis_store with a proper servers configuration' do
      expect(subject).to receive(:session_store).with(
        Gitlab::Sessions::RedisStore,
        a_hash_including(
          redis_server: Gitlab::Redis::Sessions.params.merge(
            namespace: Gitlab::Redis::Sessions::SESSION_NAMESPACE,
            serializer: Gitlab::Sessions::RedisStoreSerializer
          )
        )
      )

      load_session_store
    end
  end
end
