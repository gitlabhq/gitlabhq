# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::IpRateLimiter, :use_clean_rails_memory_store_caching do
  let(:ip) { '10.2.2.3' }
  let(:whitelist) { ['127.0.0.1'] }
  let(:options) do
    {
      enabled: true,
      ip_whitelist: whitelist,
      bantime: 1.minute,
      findtime: 1.minute,
      maxretry: 2
    }
  end

  # Both keys are written by Rack::Attack::Cache through Gitlab::RackAttack::Store.
  # The counter is bucketed by wall-clock window, the ban is not.
  let(:ban_key) { "cache:gitlab:rack::attack:allow2ban:ban:#{ip}" }

  subject(:rate_limiter) { described_class.new(ip) }

  before do
    stub_rack_attack_setting(options)
    Gitlab::Redis::RateLimiting.with(&:flushdb)
    Rack::Attack.clear_configuration
    Gitlab::RackAttack.configure(Rack::Attack)
  end

  after do
    rate_limiter.reset!
  end

  def count_key
    window = Time.now.to_i / options[:findtime].to_i
    "cache:gitlab:rack::attack:#{window}:allow2ban:count:#{ip}"
  end

  def redis_ttl(key)
    Gitlab::Redis::RateLimiting.with { |redis| redis.ttl(key) }
  end

  describe '#register_fail!' do
    it 'bans on the attempt that reaches maxretry', :aggregate_failures do
      expect(rate_limiter.banned?).to be_falsey

      rate_limiter.register_fail!

      expect(rate_limiter.banned?).to be_falsey

      rate_limiter.register_fail!

      expect(rate_limiter.banned?).to be_truthy
    end

    it 'returns false on the attempt that writes the ban, true only afterwards', :aggregate_failures do
      expect(rate_limiter.register_fail!).to be_falsey
      expect(rate_limiter.register_fail!).to be_falsey
      expect(rate_limiter.register_fail!).to be_truthy
    end

    # The ban gets bantime exactly. The counter cannot: Rack::Attack buckets it
    # by wall clock and expires it at the end of the current bucket, so its TTL
    # is anywhere in 1..findtime+1 depending on where in the window we landed.
    it 'gives the counter a bucket-bounded TTL and the ban exactly bantime', :aggregate_failures do
      freeze_time do
        rate_limiter.register_fail!

        expect(redis_ttl(count_key)).to be_between(1, options[:findtime].to_i + 1)

        rate_limiter.register_fail!

        expect(redis_ttl(ban_key)).to eq(options[:bantime].to_i)
      end
    end

    shared_examples 'whitelisted IPs' do
      it 'does not ban after max retry limit' do
        expect(rate_limiter.banned?).to be_falsey

        3.times { rate_limiter.register_fail! }

        expect(rate_limiter.banned?).to be_falsey
      end
    end

    context 'with a whitelisted netmask' do
      before do
        options[:ip_whitelist] = ['bad1', '127.0.0.1', '10.2.2.0/24', 'bad2']
        stub_rack_attack_setting(options)
      end

      it_behaves_like 'whitelisted IPs'
    end

    context 'with a whitelisted IP' do
      before do
        options[:ip_whitelist] = ['10.2.2.3']
        stub_rack_attack_setting(options)
      end

      it_behaves_like 'whitelisted IPs'
    end
  end

  describe '#reset!' do
    # Frozen because count_key is derived from the current wall-clock bucket:
    # a rollover mid-example would assert against a different key than the one
    # the failures wrote to.
    it 'clears the ban and the failure counter', :aggregate_failures do
      freeze_time do
        2.times { rate_limiter.register_fail! }

        expect(rate_limiter.banned?).to be_truthy

        rate_limiter.reset!

        expect(rate_limiter.banned?).to be_falsey
        expect(redis_ttl(count_key)).to eq(-2)
      end
    end
  end

  describe 'ban metrics' do
    let(:counter) { instance_double(Prometheus::Client::Counter, increment: nil) }

    before do
      allow(Gitlab::Metrics).to receive(:counter).and_call_original
      allow(Gitlab::Metrics).to receive(:counter)
        .with(:gitlab_rate_limiter_git_basic_auth_ban_events_total, anything, anything)
        .and_return(counter)
    end

    it 'counts each failure, and the ban the last one creates', :aggregate_failures do
      expect(counter).to receive(:increment).with(event: :failure).twice
      expect(counter).to receive(:increment).with(event: :ban).once

      2.times { rate_limiter.register_fail! }
    end

    it 'counts a request refused by an existing ban' do
      2.times { rate_limiter.register_fail! }

      expect(counter).to receive(:increment).with(event: :blocked)

      rate_limiter.banned?
    end

    it 'counts a reset' do
      expect(counter).to receive(:increment).with(event: :reset)

      rate_limiter.reset!
    end

    # Only reachable when another request banned the IP between this request's
    # pre-auth check and its failure registration, which is also the only case
    # that reaches the "threshold exceeded" auth log.
    it 'counts a failure registered against an already banned IP' do
      3.times { rate_limiter.register_fail! }

      expect(counter).to receive(:increment).with(event: :already_banned)

      rate_limiter.register_fail!
    end
  end

  shared_examples 'skips the rate limiter' do
    it 'does not call Rack::Attack::Allow2Ban.reset' do
      expect(Rack::Attack::Allow2Ban).not_to receive(:reset)

      rate_limiter.reset!
    end

    it 'does not emit ban metrics' do
      expect(Gitlab::Metrics)
        .not_to receive(:counter).with(:gitlab_rate_limiter_git_basic_auth_ban_events_total, anything, anything)

      rate_limiter.reset!
      rate_limiter.banned?
      rate_limiter.register_fail!
    end

    it 'does not call Rack::Attack::Allow2Ban.banned?' do
      expect(Rack::Attack::Allow2Ban).not_to receive(:banned?)

      rate_limiter.banned?
    end

    it 'does not call Rack::Attack::Allow2Ban.filter' do
      expect(Rack::Attack::Allow2Ban).not_to receive(:filter)

      rate_limiter.register_fail!
    end
  end

  context 'when IP is allow listed' do
    let(:ip) { '127.0.0.1' }

    it_behaves_like 'skips the rate limiter'
  end

  context 'when rate limiter is disabled' do
    let(:options) { { enabled: false } }

    it_behaves_like 'skips the rate limiter'
  end

  # The labkit path is exercised in detail in git_basic_auth_ban_spec.rb. What
  # matters here is that the flag routes to it and that the metrics, which are
  # the point of the comparison, keep firing on both paths.
  context 'when use_labkit_git_basic_auth_ban is enabled', :clean_gitlab_redis_rate_limiting do
    before do
      stub_feature_flags(use_labkit_git_basic_auth_ban: true)
      Gitlab::Auth::GitBasicAuthBan.reset_limiter!
    end

    after do
      Gitlab::Auth::GitBasicAuthBan.reset_limiter!
    end

    it 'does not touch Rack::Attack::Allow2Ban', :aggregate_failures do
      expect(Rack::Attack::Allow2Ban).not_to receive(:filter)
      expect(Rack::Attack::Allow2Ban).not_to receive(:banned?)
      expect(Rack::Attack::Allow2Ban).not_to receive(:reset)

      rate_limiter.register_fail!
      rate_limiter.banned?
      rate_limiter.reset!
    end

    it 'bans one attempt later than the Allow2Ban path did', :aggregate_failures do
      2.times { rate_limiter.register_fail! }

      expect(rate_limiter.banned?).to be(false)

      rate_limiter.register_fail!

      expect(rate_limiter.banned?).to be(true)
    end

    it 'clears the ban on reset', :aggregate_failures do
      3.times { rate_limiter.register_fail! }
      expect(rate_limiter.banned?).to be(true)

      rate_limiter.reset!

      expect(rate_limiter.banned?).to be(false)
    end

    it 'still skips allowlisted IPs' do
      allow(rate_limiter).to receive(:trusted_ip?).and_return(true)

      expect(Gitlab::Auth::GitBasicAuthBan).not_to receive(:register_fail!)

      expect(rate_limiter.register_fail!).to be(false)
    end

    describe 'metrics' do
      let(:counter) { instance_double(Prometheus::Client::Counter, increment: nil) }

      before do
        allow(Gitlab::Metrics).to receive(:counter).and_call_original
        allow(Gitlab::Metrics).to receive(:counter)
          .with(:gitlab_rate_limiter_git_basic_auth_ban_events_total, anything, anything)
          .and_return(counter)
      end

      it 'counts failures and the resulting ban', :aggregate_failures do
        expect(counter).to receive(:increment).with(event: :failure).exactly(3).times
        expect(counter).to receive(:increment).with(event: :ban).once

        3.times { rate_limiter.register_fail! }
      end

      # labkit counts and bans in one call and suppresses counting while banned,
      # so it cannot separate "already banned" from "banned by this attempt".
      # That event disappears on this path; those requests report :ban instead.
      it 'never emits already_banned' do
        expect(counter).not_to receive(:increment).with(event: :already_banned)

        4.times { rate_limiter.register_fail! }
      end

      # So :ban counts attempts blocked by a ban, not bans created. Getting here
      # with a live ban needs the race above, since Gitlab::Auth refuses a banned
      # caller before it authenticates.
      it 'keeps counting failure and ban on attempts against a live ban', :aggregate_failures do
        expect(counter).to receive(:increment).with(event: :failure).exactly(5).times
        expect(counter).to receive(:increment).with(event: :ban).exactly(3).times

        5.times { rate_limiter.register_fail! }
      end
    end
  end

  describe '#trusted_ip?' do
    subject { rate_limiter.trusted_ip? }

    context 'when ip is in the trusted list' do
      let(:ip) { '127.0.0.1' }

      it { is_expected.to be_truthy }
    end

    context 'when mapped ip is in the trusted list' do
      let(:ip) { '::ffff:127.0.0.1' }

      it { is_expected.to be_truthy }
    end

    context 'when ip is not in the trusted list' do
      let(:ip) { '10.0.0.1' }

      it { is_expected.to be_falsey }
    end

    context 'when mapped ip is not in the trusted list' do
      let(:ip) { '::ffff:10.0.0.1' }

      it { is_expected.to be_falsey }
    end
  end
end
