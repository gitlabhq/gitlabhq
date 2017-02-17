shared_context 'limit login to only one ip' do
  before(:each) do
    Gitlab::Redis.with(&:flushall)
  end

  before do
    allow(Gitlab::Auth::UniqueIpsLimiter).to receive_message_chain(:config, :unique_ips_limit_enabled).and_return(true)
    allow(Gitlab::Auth::UniqueIpsLimiter).to receive_message_chain(:config, :unique_ips_limit_time_window).and_return(10000)
    allow(Gitlab::Auth::UniqueIpsLimiter).to receive_message_chain(:config, :unique_ips_limit_per_user).and_return(1)
  end

  def change_ip(ip)
    allow(Gitlab::RequestContext).to receive(:client_ip).and_return(ip)
  end
end

shared_examples 'user login operation with unique ip limit' do
  include_context 'limit login to only one ip' do
    it 'allows user authenticating from the same ip' do
      change_ip('ip')
      expect { operation }.not_to raise_error
      expect { operation }.not_to raise_error
    end

    it 'blocks user authenticating from two distinct ips' do
      change_ip('ip')
      expect { operation }.not_to raise_error

      change_ip('ip2')
      expect { operation }.to raise_error(Gitlab::Auth::TooManyIps)
    end
  end
end
