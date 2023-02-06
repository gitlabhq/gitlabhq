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

  describe '#register_fail!' do
    it 'bans after 3 consecutive failures' do
      expect(subject.banned?).to be_falsey

      3.times { subject.register_fail! }

      expect(subject.banned?).to be_truthy
    end

    shared_examples 'whitelisted IPs' do
      it 'does not ban after max retry limit' do
        expect(subject.banned?).to be_falsey

        3.times { subject.register_fail! }

        expect(subject.banned?).to be_falsey
      end
    end

    context 'with a whitelisted netmask' do
      before do
        options[:ip_whitelist] = ['127.0.0.1', '10.2.2.0/24', 'bad']
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

  shared_examples 'skips the rate limiter' do
    it 'does not call Rack::Attack::Allow2Ban.reset!' do
      expect(Rack::Attack::Allow2Ban).not_to receive(:reset!)

      subject.reset!
    end

    it 'does not call Rack::Attack::Allow2Ban.banned?' do
      expect(Rack::Attack::Allow2Ban).not_to receive(:banned?)

      subject.banned?
    end

    it 'does not call Rack::Attack::Allow2Ban.filter' do
      expect(Rack::Attack::Allow2Ban).not_to receive(:filter)

      subject.register_fail!
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

  describe '#trusted_ip?' do
    subject { rate_limiter.trusted_ip? }

    context 'when ip is in the trusted list' do
      let(:ip) { '127.0.0.1' }

      it { is_expected.to be_truthy }
    end

    context 'when ip is not in the trusted list' do
      let(:ip) { '10.0.0.1' }

      it { is_expected.to be_falsey }
    end
  end
end
