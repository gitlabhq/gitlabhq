require 'spec_helper'

describe Gitlab::Auth::UniqueIpsLimiter, :redis, lib: true do
  include_context 'enable unique ips sign in limit'
  let(:user) { create(:user) }

  describe '#count_unique_ips' do
    context 'non unique IPs' do
      it 'properly counts them' do
        expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, 'ip1')).to eq(1)
        expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, 'ip1')).to eq(1)
      end
    end

    context 'unique IPs' do
      it 'properly counts them' do
        expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, 'ip2')).to eq(1)
        expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, 'ip3')).to eq(2)
      end
    end

    it 'resets count after specified time window' do
      cur_time = Time.now
      allow(Time).to receive(:now).and_return(cur_time)

      expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, 'ip2')).to eq(1)
      expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, 'ip3')).to eq(2)

      allow(Time).to receive(:now).and_return(cur_time + Gitlab::Auth::UniqueIpsLimiter.config.unique_ips_limit_time_window)

      expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, 'ip4')).to eq(1)
      expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, 'ip5')).to eq(2)
    end
  end

  describe '#limit_user!' do
    include_examples 'user login operation with unique ip limit' do
      def operation
        Gitlab::Auth::UniqueIpsLimiter.limit_user! { user }
      end
    end

    context 'allow 2 unique ips' do
      before { current_application_settings.update!(unique_ips_limit_per_user: 2) }

      it 'blocks user trying to login from third ip' do
        change_ip('ip1')
        expect(Gitlab::Auth::UniqueIpsLimiter.limit_user! { user }).to eq(user)

        change_ip('ip2')
        expect(Gitlab::Auth::UniqueIpsLimiter.limit_user! { user }).to eq(user)

        change_ip('ip3')
        expect { Gitlab::Auth::UniqueIpsLimiter.limit_user! { user } }.to raise_error(Gitlab::Auth::TooManyIps)
      end
    end
  end
end
