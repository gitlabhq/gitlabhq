# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Session initializer for GitLab' do
  subject { Gitlab::Application.config }

  let(:load_session_store) do
    load Rails.root.join('config/initializers/session_store.rb')
  end

  describe 'config#session_store' do
    it 'initialized as a redis_store with a proper servers configuration' do
      expect(subject).to receive(:session_store).with(:redis_store, a_hash_including(redis_store: kind_of(::Redis::Store)))

      load_session_store
    end
  end
end
