shared_context 'enable unique ips sign in limit' do
  include StubENV
  before(:each) do
    Gitlab::Redis.with(&:flushall)
  end

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

    current_application_settings.update!(
      unique_ips_limit_enabled: true,
      unique_ips_limit_time_window: 10000
    )
  end

  def change_ip(ip)
    allow(Gitlab::RequestContext).to receive(:client_ip).and_return(ip)
  end
end

shared_examples 'user login operation with unique ip limit' do
  include_context 'enable unique ips sign in limit' do
    before { current_application_settings.update!(unique_ips_limit_per_user: 1) }

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

shared_examples 'user login request with unique ip limit' do
  include_context 'enable unique ips sign in limit' do
    before { current_application_settings.update!(unique_ips_limit_per_user: 1) }

    it 'allows user authenticating from the same ip' do
      change_ip('ip')
      request
      expect(response).to have_http_status(200)

      request
      expect(response).to have_http_status(200)
    end

    it 'blocks user authenticating from two distinct ips' do
      change_ip('ip')
      request
      expect(response).to have_http_status(200)

      change_ip('ip2')
      request
      expect(response).to have_http_status(403)
    end
  end
end
