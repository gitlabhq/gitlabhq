# frozen_string_literal: true

module SessionHelpers
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
end
