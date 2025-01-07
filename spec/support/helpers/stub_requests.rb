# frozen_string_literal: true

module StubRequests
  IP_ADDRESS_STUB = '8.8.8.9'

  # Fully stubs a request using WebMock class. This class also
  # stubs the IP address the URL is translated to (DNS lookup).
  #
  # It expects the final request to go to the `ip_address` instead the given url.
  # That's primarily a DNS rebind attack prevention of Gitlab::HTTP
  # (see: Gitlab::HTTP_V2::UrlBlocker).
  #
  def stub_full_request(url, ip_address: IP_ADDRESS_STUB, port: 80, method: :get)
    stub_dns(url, ip_address: ip_address, port: port)

    url = stubbed_hostname(url, hostname: ip_address)
    WebMock.stub_request(method, url)
  end

  def stub_dns(url, ip_address:, port: 80)
    url = parse_url(url)
    socket = Socket.sockaddr_in(port, ip_address)
    addr = Addrinfo.new(socket)

    # See Gitlab::HTTP_V2::UrlBlocker
    allow(Addrinfo).to receive(:getaddrinfo)
                         .with(url.hostname, url.port, nil, :STREAM)
                         .and_return([addr])
  end

  def stub_all_dns(url, ip_address:)
    url = URI(url)
    port = 80 # arbitarily chosen, does not matter as we are not going to connect
    socket = Socket.sockaddr_in(port, ip_address)
    addr = Addrinfo.new(socket)

    # See Gitlab::HTTP_V2::UrlBlocker
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
    allow(Addrinfo).to receive(:getaddrinfo)
      .with(url.hostname, anything, nil, :STREAM)
      .and_return([addr])
  end

  def stubbed_hostname(url, hostname: IP_ADDRESS_STUB)
    url = parse_url(url)
    url.hostname = hostname
    url.to_s
  end

  def request_for_url(input_url)
    env = Rack::MockRequest.env_for(input_url)
    env['action_dispatch.parameter_filter'] = Gitlab::Application.config.filter_parameters

    ActionDispatch::Request.new(env)
  end

  private

  def parse_url(url)
    url.is_a?(URI) ? url : URI(url)
  end
end
