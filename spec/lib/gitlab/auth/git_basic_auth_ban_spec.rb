# frozen_string_literal: true

require 'spec_helper'

# These exercise the labkit ban against real Redis, so they need gitlab-labkit
# 4.6.0 or later for ban_for and Limiter#clear.
RSpec.describe Gitlab::Auth::GitBasicAuthBan, :clean_gitlab_redis_rate_limiting,
  feature_category: :system_access do
  let(:ip) { '10.2.2.3' }
  let(:options) do
    {
      enabled: true,
      ip_whitelist: ['127.0.0.1'],
      bantime: 15.minutes,
      findtime: 1.minute,
      maxretry: 2
    }
  end

  # The braces are the Redis Cluster hash tag: the counter and its ban must
  # share a slot because labkit reads and writes both in one Lua call.
  let(:counter_key) { "labkit:rl:{git_basic_auth:failed_auth_ban_by_ip:ip:#{ip}}" }
  let(:ban_key) { "labkit:rl:{git_basic_auth:failed_auth_ban_by_ip:ip:#{ip}}:ban" }

  before do
    stub_rack_attack_setting(options)
    described_class.reset_limiter!
  end

  after do
    described_class.reset_limiter!
  end

  def redis_ttl(key)
    Gitlab::Redis::RateLimiting.with { |redis| redis.ttl(key) }
  end

  describe '.register_fail!' do
    # Allow2Ban banned when the count reached maxretry; labkit blocks only once
    # the count is above the limit, so the ban lands one attempt later. Accepted
    # deliberately, to keep labkit's API consistent. Pinned here so a change is
    # a decision rather than an accident.
    it 'bans one attempt after maxretry is reached', :aggregate_failures do
      expect(described_class.register_fail!(ip)).to be(false)
      expect(described_class.register_fail!(ip)).to be(false)
      expect(described_class.register_fail!(ip)).to be(true)
    end

    it 'writes a ban that outlives the counting window', :aggregate_failures do
      3.times { described_class.register_fail!(ip) }

      expect(redis_ttl(ban_key)).to be_between(1, options[:bantime].to_i)
      expect(redis_ttl(ban_key)).to be > redis_ttl(counter_key)
    end

    it 'stops counting once the ban is in force, so retries cannot extend it' do
      3.times { described_class.register_fail!(ip) }
      counted = Gitlab::Redis::RateLimiting.with { |redis| redis.get(counter_key) }

      2.times { described_class.register_fail!(ip) }

      expect(Gitlab::Redis::RateLimiting.with { |redis| redis.get(counter_key) }).to eq(counted)
    end

    it 'bans one IP without affecting another', :aggregate_failures do
      3.times { described_class.register_fail!(ip) }

      expect(described_class.banned?(ip)).to be(true)
      expect(described_class.banned?('10.2.2.4')).to be(false)
    end
  end

  describe '.banned?' do
    it 'is false for an IP with no failures' do
      expect(described_class.banned?(ip)).to be(false)
    end

    it 'does not count, so peeking cannot ban an IP' do
      2.times { described_class.register_fail!(ip) }

      5.times { described_class.banned?(ip) }

      expect(described_class.banned?(ip)).to be(false)
    end
  end

  describe '.clear!' do
    it 'drops the counter and the ban, letting the IP through again', :aggregate_failures do
      3.times { described_class.register_fail!(ip) }
      expect(described_class.banned?(ip)).to be(true)

      described_class.clear!(ip)

      expect(described_class.banned?(ip)).to be(false)
      expect(redis_ttl(ban_key)).to eq(-2)
      expect(redis_ttl(counter_key)).to eq(-2)
    end

    it 'is harmless when there is nothing to clear' do
      expect { described_class.clear!(ip) }.not_to raise_error
    end
  end

  describe 'configuration' do
    # Read per check rather than at build time, so an operator editing
    # gitlab.yml does not need the limiter rebuilt.
    it 'picks up a changed maxretry without rebuilding the limiter' do
      described_class.register_fail!(ip)

      stub_rack_attack_setting(options.merge(maxretry: 1))

      expect(described_class.register_fail!(ip)).to be(true)
    end

    # bantime defaults to 1 hour, but that default is applied with ||= and 0 is
    # truthy in Ruby, so an operator can configure 0. Labkit rejects a ban
    # shorter than a second, which would fail the whole rule open and stop it
    # counting, so the rule is built without ban_for and stays an ordinary
    # windowed limit.
    context 'when bantime is configured below one second' do
      before do
        stub_rack_attack_setting(options.merge(bantime: 0))
        described_class.reset_limiter!
      end

      it 'still counts and still refuses the caller, and writes no ban key', :aggregate_failures do
        2.times { expect(described_class.register_fail!(ip)).to be(false) }

        expect(described_class.register_fail!(ip)).to be(true)

        # The point of dropping ban_for rather than failing: the caller is still
        # refused while the counter is over the limit, just not beyond it.
        expect(described_class.banned?(ip)).to be(true)

        expect(Gitlab::Redis::RateLimiting.with { |r| r.exists?(ban_key) }).to be(false)
        expect(Gitlab::Redis::RateLimiting.with { |r| r.get(counter_key).to_i }).to eq(3)
      end
    end
  end
end
