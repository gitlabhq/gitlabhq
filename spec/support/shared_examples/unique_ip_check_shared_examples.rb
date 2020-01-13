# frozen_string_literal: true

shared_context 'unique ips sign in limit' do
  include StubENV
  let(:request_context) { Gitlab::RequestContext.instance }

  before do
    Gitlab::Redis::Cache.with(&:flushall)
    Gitlab::Redis::Queues.with(&:flushall)
    Gitlab::Redis::SharedState.with(&:flushall)
  end

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

    Gitlab::CurrentSettings.update!(
      unique_ips_limit_enabled: true,
      unique_ips_limit_time_window: 10000
    )

    # Make sure we're working with the same reqeust context everywhere
    allow(Gitlab::RequestContext).to receive(:instance).and_return(request_context)
  end

  def change_ip(ip)
    allow(request_context).to receive(:client_ip).and_return(ip)
  end

  def request_from_ip(ip)
    change_ip(ip)
    request
    response
  end

  def operation_from_ip(ip)
    change_ip(ip)
    operation
  end
end

shared_examples 'user login operation with unique ip limit' do
  include_context 'unique ips sign in limit' do
    before do
      Gitlab::CurrentSettings.update!(unique_ips_limit_per_user: 1)
    end

    it 'allows user authenticating from the same ip' do
      expect { operation_from_ip('ip') }.not_to raise_error
      expect { operation_from_ip('ip') }.not_to raise_error
    end

    it 'blocks user authenticating from two distinct ips' do
      expect { operation_from_ip('ip') }.not_to raise_error
      expect { operation_from_ip('ip2') }.to raise_error(Gitlab::Auth::TooManyIps)
    end
  end
end

shared_examples 'user login request with unique ip limit' do |success_status = 200|
  include_context 'unique ips sign in limit' do
    before do
      Gitlab::CurrentSettings.update!(unique_ips_limit_per_user: 1)
    end

    it 'allows user authenticating from the same ip' do
      expect(request_from_ip('ip')).to have_gitlab_http_status(success_status)
      expect(request_from_ip('ip')).to have_gitlab_http_status(success_status)
    end

    it 'blocks user authenticating from two distinct ips' do
      expect(request_from_ip('ip')).to have_gitlab_http_status(success_status)
      expect(request_from_ip('ip2')).to have_gitlab_http_status(403)
    end
  end
end
