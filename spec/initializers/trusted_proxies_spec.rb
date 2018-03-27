require 'spec_helper'

describe 'trusted_proxies' do
  context 'with default config' do
    before do
      set_trusted_proxies([])
    end

    it 'preserves private IPs' do
      request = stub_request('HTTP_X_FORWARDED_FOR' => '10.1.5.89')
      expect(request.remote_ip).to eq('10.1.5.89')
      expect(request.ip).to eq('10.1.5.89')
    end

    it 'filters out localhost' do
      request = stub_request('HTTP_X_FORWARDED_FOR' => '1.1.1.1, 10.1.5.89, 127.0.0.1')
      expect(request.remote_ip).to eq('10.1.5.89')
      expect(request.ip).to eq('10.1.5.89')
    end

    it 'filters out bad values' do
      request = stub_request('HTTP_X_FORWARDED_FOR' => '(null), 10.1.5.89')
      expect(request.remote_ip).to eq('10.1.5.89')
      expect(request.ip).to eq('10.1.5.89')
    end
  end

  context 'with private IP ranges added' do
    before do
      set_trusted_proxies(["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"])
    end

    it 'filters out private and local IPs' do
      request = stub_request('HTTP_X_FORWARDED_FOR' => '1.2.3.6, 1.1.1.1, 10.1.5.89, 127.0.0.1')
      expect(request.remote_ip).to eq('1.1.1.1')
      expect(request.ip).to eq('1.1.1.1')
    end
  end

  context 'with proxy IP added' do
    before do
      set_trusted_proxies(["60.98.25.47"])
    end

    it 'filters out proxy IP' do
      request = stub_request('HTTP_X_FORWARDED_FOR' => '1.2.3.6, 1.1.1.1, 60.98.25.47, 127.0.0.1')
      expect(request.remote_ip).to eq('1.1.1.1')
      expect(request.ip).to eq('1.1.1.1')
    end

    it 'handles invalid ip addresses' do
      request = stub_request('HTTP_X_FORWARDED_FOR' => '(null), 1.1.1.1:12345, 1.1.1.1')
      expect(request.remote_ip).to eq('1.1.1.1')
      expect(request.ip).to eq('1.1.1.1')
    end
  end

  def stub_request(headers = {})
    ActionDispatch::RemoteIp.new(proc { }, false, Rails.application.config.action_dispatch.trusted_proxies).call(headers)
    ActionDispatch::Request.new(headers)
  end

  def set_trusted_proxies(proxies = [])
    stub_config_setting('trusted_proxies' => proxies)
    load File.join(__dir__, '../../config/initializers/trusted_proxies.rb')
  end
end
