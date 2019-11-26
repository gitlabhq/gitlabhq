# frozen_string_literal: true

shared_examples 'a request using Gitlab::UrlBlocker' do
  # Written to test internal patches against 3rd party libraries
  #
  # Expects the following to be available in the example contexts:
  #
  #   make_request(uri): Wraps the request we want to test goes through Gitlab::HTTP
  #   http_method: :get, :post etc
  #   url_blocked_error_class: Probably just Gitlab::HTTP::BlockedUrlError

  include StubRequests

  context 'when local requests are not allowed' do
    it 'allows an external request with http' do
      request_stub = stub_full_request('http://example.com', method: http_method, ip_address: '93.184.216.34')

      make_request('http://example.com/')

      expect(request_stub).to have_been_requested
    end

    it 'allows an external request with https' do
      request_stub = stub_full_request('https://example.com', method: http_method, ip_address: '93.184.216.34')

      make_request('https://example.com/')

      expect(request_stub).to have_been_requested
    end

    it 'raises error when it is a request that resolves to a local address' do
      stub_full_request('https://example.com', method: http_method, ip_address: '172.16.0.0')

      expect { make_request('https://example.com') }
        .to raise_error(url_blocked_error_class,
                        "URL 'https://example.com' is blocked: Requests to the local network are not allowed")
    end

    it 'raises error when it is a request that resolves to a localhost address' do
      stub_full_request('https://example.com', method: http_method, ip_address: '127.0.0.1')

      expect { make_request('https://example.com') }
        .to raise_error(url_blocked_error_class,
                        "URL 'https://example.com' is blocked: Requests to localhost are not allowed")
    end

    it 'raises error when it is a request to local address' do
      expect { make_request('http://172.16.0.0') }
        .to raise_error(url_blocked_error_class,
                        "URL 'http://172.16.0.0' is blocked: Requests to the local network are not allowed")
    end

    it 'raises error when it is a request to localhost address' do
      expect { make_request('http://127.0.0.1') }
        .to raise_error(url_blocked_error_class,
                        "URL 'http://127.0.0.1' is blocked: Requests to localhost are not allowed")
    end
  end

  context 'when port different from URL scheme is used' do
    it 'allows the request' do
      request_stub = stub_full_request('https://example.com:8080', method: http_method, ip_address: '93.184.216.34')

      make_request('https://example.com:8080/')

      expect(request_stub).to have_been_requested
    end

    it 'raises error when it is a request to local address' do
      expect { make_request('https://172.16.0.0:8080') }
        .to raise_error(url_blocked_error_class,
                        "URL 'https://172.16.0.0:8080' is blocked: Requests to the local network are not allowed")
    end

    it 'raises error when it is a request to localhost address' do
      expect { make_request('https://127.0.0.1:8080') }
        .to raise_error(url_blocked_error_class,
                        "URL 'https://127.0.0.1:8080' is blocked: Requests to localhost are not allowed")
    end
  end

  context 'when DNS rebinding protection is disabled' do
    before do
      stub_application_setting(dns_rebinding_protection_enabled: false)
    end

    it 'allows the request' do
      request_stub = stub_request(http_method, 'https://example.com')

      make_request('https://example.com/')

      expect(request_stub).to have_been_requested
    end
  end

  context 'when http(s) proxy environment variable is set' do
    before do
      stub_env('https_proxy' => 'https://my.proxy')
    end

    it 'allows the request' do
      request_stub = stub_request(http_method, 'https://example.com')

      make_request('https://example.com/')

      expect(request_stub).to have_been_requested
    end
  end

  context 'when local requests are allowed' do
    before do
      stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
    end

    it 'allows an external request' do
      request_stub = stub_full_request('https://example.com', method: http_method, ip_address: '93.184.216.34')

      make_request('https://example.com/')

      expect(request_stub).to have_been_requested
    end

    it 'allows an external request that resolves to a local address' do
      request_stub = stub_full_request('https://example.com', method: http_method, ip_address: '172.16.0.0')

      make_request('https://example.com/')

      expect(request_stub).to have_been_requested
    end

    it 'allows an external request that resolves to a localhost address' do
      request_stub = stub_full_request('https://example.com', method: http_method, ip_address: '127.0.0.1')

      make_request('https://example.com/')

      expect(request_stub).to have_been_requested
    end

    it 'allows a local address request' do
      request_stub = stub_request(http_method, 'http://172.16.0.0')

      make_request('http://172.16.0.0')

      expect(request_stub).to have_been_requested
    end

    it 'allows a localhost address request' do
      request_stub = stub_request(http_method, 'http://127.0.0.1')

      make_request('http://127.0.0.1')

      expect(request_stub).to have_been_requested
    end
  end
end
