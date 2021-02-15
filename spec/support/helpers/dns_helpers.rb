# frozen_string_literal: true

module DnsHelpers
  def block_dns!
    stub_all_dns!
    stub_invalid_dns!
    permit_local_dns!
  end

  def permit_dns!
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
  end

  def stub_all_dns!
    allow(Addrinfo).to receive(:getaddrinfo).and_return([])
  end

  def stub_invalid_dns!
    invalid_addresses = %r{
      \A
        (?:
          foobar\.\w |
          (?:\d{1,3}\.){4,}\d{1,3}
        )
      \z
    }ix

    allow(Addrinfo).to receive(:getaddrinfo)
      .with(invalid_addresses, any_args)
      .and_raise(SocketError, 'getaddrinfo: Name or service not known')
  end

  def permit_local_dns!
    local_addresses = %r{
      \A
        (?:
          (?:127|10)\.0\.0\.\d{1,3} |
          (?:192\.168|172\.16)\.\d{1,3}\.\d{1,3} |
          0\.0\.0\.0 |
          localhost
        )
      \z
    }ix

    allow(Addrinfo).to receive(:getaddrinfo)
      .with(local_addresses, any_args)
      .and_call_original
  end
end
