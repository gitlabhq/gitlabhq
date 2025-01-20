# frozen_string_literal: true

module SessionHelpers
  # Stub a session in Redis, for use in request specs where we can't mock the session directly.
  # This also needs the :clean_gitlab_redis_sessions tag on the spec.
  def stub_session(session_data:, user_id: nil)
    unless RSpec.current_example.metadata[:clean_gitlab_redis_sessions]
      raise 'Add :clean_gitlab_redis_sessions to your spec!'
    end

    session_id = Rack::Session::SessionId.new(SecureRandom.hex)

    store = ActiveSupport::Cache::RedisCacheStore.new(
      namespace: Gitlab::Redis::Sessions::SESSION_NAMESPACE,
      redis: Gitlab::Redis::Sessions
    )
    store.write(session_id.private_id, session_data)

    Gitlab::Redis::Sessions.with do |redis|
      redis.sadd("session:lookup:user:gitlab:#{user_id}", [session_id.private_id]) if user_id
    end

    defined?(cookies) && cookies[Gitlab::Application.config.session_options[:key]] = session_id.public_id
  end

  def expect_single_session_with_authenticated_ttl
    expect_single_session_with_expiration(Settings.gitlab['session_expire_delay'] * 60)
  end

  def expect_single_session_with_short_ttl
    expect_single_session_with_expiration(Settings.gitlab['unauthenticated_session_expire_delay'])
  end

  def expect_single_session_with_expiration(expiration)
    session_keys = get_session_keys

    expect(session_keys.size).to eq(1)
    expect(get_ttl(session_keys.first)).to be_within(5).of(expiration)
  end

  def get_session_keys
    Gitlab::Redis::Sessions.with { |redis| redis.scan_each(match: 'session:gitlab:*').to_a }
  end

  def get_ttl(key)
    Gitlab::Redis::Sessions.with { |redis| redis.ttl(key) }
  end

  def expire_session
    get_session_keys.each do |key|
      ::Gitlab::Redis::Sessions.with { |redis| redis.expire(key, -1) }
    end
  end
end
