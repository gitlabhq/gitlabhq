# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Session initializer for GitLab' do
  subject { Gitlab::Application.config }

  let(:load_session_store) do
    load Rails.root.join('config/initializers/session_store.rb')
  end

  describe 'config#session_store' do
    context 'when the GITLAB_USE_REDIS_SESSIONS_STORE env is not set' do
      before do
        stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', nil)
      end

      it 'initialized with Multistore as ENV var defaults to true' do
        expect(subject).to receive(:session_store).with(:redis_store, a_hash_including(redis_store: kind_of(::Redis::Store)))

        load_session_store
      end
    end

    context 'when the GITLAB_USE_REDIS_SESSIONS_STORE env is disabled' do
      before do
        stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', false)
      end

      it 'initialized as a redis_store with a proper servers configuration' do
        expect(subject).to receive(:session_store).with(:redis_store, a_hash_including(redis_store: kind_of(Redis::Store)))

        load_session_store
      end
    end

    context 'when the GITLAB_USE_REDIS_SESSIONS_STORE env is enabled' do
      before do
        stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', true)
      end

      it 'initialized as a redis_store with a proper servers configuration' do
        expect(subject).to receive(:session_store).with(:redis_store, a_hash_including(redis_store: kind_of(::Redis::Store)))

        load_session_store
      end
    end
  end
end
