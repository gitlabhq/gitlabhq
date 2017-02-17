require 'spec_helper'

describe Gitlab::Auth::UniqueIpsLimiter, :redis, lib: true do
  let(:user) { create(:user) }

  describe '#count_unique_ips' do
    context 'non unique IPs' do
      it 'properly counts them' do
        expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, '192.168.1.1')).to eq(1)
        expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, '192.168.1.1')).to eq(1)
      end
    end

    context 'unique IPs' do
      it 'properly counts them' do
        expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, '192.168.1.2')).to eq(1)
        expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, '192.168.1.3')).to eq(2)
      end
    end

    it 'resets count after specified time window' do
      cur_time = Time.now
      allow(Time).to receive(:now).and_return(cur_time)

      expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, '192.168.1.2')).to eq(1)
      expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, '192.168.1.3')).to eq(2)

      allow(Time).to receive(:now).and_return(cur_time + Gitlab::Auth::UniqueIpsLimiter.config.unique_ips_limit_time_window)

      expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, '192.168.1.4')).to eq(1)
      expect(Gitlab::Auth::UniqueIpsLimiter.count_unique_ips(user.id, '192.168.1.5')).to eq(2)
    end
  end

  describe '#limit_user!' do
    context 'when unique ips limit is enabled' do
      before do
        allow(Gitlab::Auth::UniqueIpsLimiter).to receive_message_chain(:config, :unique_ips_limit_enabled).and_return(true)
        allow(Gitlab::Auth::UniqueIpsLimiter).to receive_message_chain(:config, :unique_ips_limit_time_window).and_return(10)
      end

      context 'when ip limit is set to 1' do
        before do
          allow(Gitlab::Auth::UniqueIpsLimiter).to receive_message_chain(:config, :unique_ips_limit_per_user).and_return(1)
        end

        it 'blocks user trying to login from second ip' do
          allow(Gitlab::RequestContext).to receive(:client_ip).and_return('192.168.1.1')
          expect(Gitlab::Auth::UniqueIpsLimiter.limit_user! { user }).to eq(user)

          allow(Gitlab::RequestContext).to receive(:client_ip).and_return('192.168.1.2')
          expect { Gitlab::Auth::UniqueIpsLimiter.limit_user! { user } }.to raise_error(Gitlab::Auth::TooManyIps)
        end

        it 'allows user trying to login from the same ip twice' do
          allow(Gitlab::RequestContext).to receive(:client_ip).and_return('192.168.1.1')
          expect(Gitlab::Auth::UniqueIpsLimiter.limit_user! { user }).to eq(user)
          expect(Gitlab::Auth::UniqueIpsLimiter.limit_user! { user }).to eq(user)
        end
      end

      context 'when ip limit is set to 2' do
        before do
          allow(Gitlab::Auth::UniqueIpsLimiter).to receive_message_chain(:config, :unique_ips_limit_per_user).and_return(2)
        end

        it 'blocks user trying to login from third ip' do
          allow(Gitlab::RequestContext).to receive(:client_ip).and_return('192.168.1.1')
          expect(Gitlab::Auth::UniqueIpsLimiter.limit_user! { user }).to eq(user)

          allow(Gitlab::RequestContext).to receive(:client_ip).and_return('192.168.1.2')
          expect(Gitlab::Auth::UniqueIpsLimiter.limit_user! { user }).to eq(user)

          allow(Gitlab::RequestContext).to receive(:client_ip).and_return('192.168.1.3')
          expect { Gitlab::Auth::UniqueIpsLimiter.limit_user! { user } }.to raise_error(Gitlab::Auth::TooManyIps)
        end
      end
    end
  end
end
