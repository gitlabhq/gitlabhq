require 'spec_helper'

describe Gitlab::Auth::UniqueIpsLimiter, :clean_gitlab_redis_shared_state do
  include_context 'unique ips sign in limit'
  let(:user) { create(:user) }

  describe '#count_unique_ips' do
    context 'non unique IPs' do
      it 'properly counts them' do
        expect(described_class.update_and_return_ips_count(user.id, 'ip1')).to eq(1)
        expect(described_class.update_and_return_ips_count(user.id, 'ip1')).to eq(1)
      end
    end

    context 'unique IPs' do
      it 'properly counts them' do
        expect(described_class.update_and_return_ips_count(user.id, 'ip2')).to eq(1)
        expect(described_class.update_and_return_ips_count(user.id, 'ip3')).to eq(2)
      end
    end

    it 'resets count after specified time window' do
      Timecop.freeze do
        expect(described_class.update_and_return_ips_count(user.id, 'ip2')).to eq(1)
        expect(described_class.update_and_return_ips_count(user.id, 'ip3')).to eq(2)

        Timecop.travel(Time.now.utc + described_class.config.unique_ips_limit_time_window) do
          expect(described_class.update_and_return_ips_count(user.id, 'ip4')).to eq(1)
          expect(described_class.update_and_return_ips_count(user.id, 'ip5')).to eq(2)
        end
      end
    end
  end

  describe '#limit_user!' do
    include_examples 'user login operation with unique ip limit' do
      def operation
        described_class.limit_user! { user }
      end
    end

    context 'allow 2 unique ips' do
      before do
        Gitlab::CurrentSettings.current_application_settings.update!(unique_ips_limit_per_user: 2)
      end

      it 'blocks user trying to login from third ip' do
        change_ip('ip1')
        expect(described_class.limit_user! { user }).to eq(user)

        change_ip('ip2')
        expect(described_class.limit_user! { user }).to eq(user)

        change_ip('ip3')
        expect { described_class.limit_user! { user } }.to raise_error(Gitlab::Auth::TooManyIps)
      end
    end
  end
end
