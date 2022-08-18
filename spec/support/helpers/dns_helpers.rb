# frozen_string_literal: true

module DnsHelpers
  def block_dns!
    stub_all_dns!
    stub_invalid_dns!
    permit_local_dns!
    permit_postgresql!
  end

  def permit_dns!
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
  end

  def stub_all_dns!
    allow(Addrinfo).to receive(:getaddrinfo).with(anything, anything, nil, :STREAM).and_return([])
    allow(Addrinfo).to receive(:getaddrinfo).with(anything, anything, nil, :STREAM, anything, anything).and_return([])
  end

  def stub_invalid_dns!
    allow(Addrinfo).to receive(:getaddrinfo).with(/\Afoobar\.\w|(\d{1,3}\.){4,}\d{1,3}\z/i, anything, nil, :STREAM) do
      raise SocketError, "getaddrinfo: Name or service not known"
    end
  end

  def permit_local_dns!
    local_addresses = %r{
      \A
      ::1? |                                          # IPV6
      (127|10)\.0\.0\.\d{1,3} |                       # 127.0.0.x or 10.0.0.x local network
      192\.168\.\d{1,3}\.\d{1,3}  |                   # 192.168.x.x local network
      172\.(1[6-9]|2[0-9]|3[0-1])\.\d{1,3}\.\d{1,3} | # 172.16.x.x - 172.31.x.x local network
      0\.0\.0\.0 |                                    # loopback
      localhost
      \z
    }xi
    allow(Addrinfo).to receive(:getaddrinfo).with(local_addresses, anything, nil, :STREAM).and_call_original
    allow(Addrinfo).to receive(:getaddrinfo).with(local_addresses, anything, nil, :STREAM, anything, anything, any_args).and_call_original
  end

  # pg v1.4.0, unlike v1.3.5, uses AddrInfo.getaddrinfo to resolve IPv4 and IPv6 addresses:
  # https://github.com/ged/ruby-pg/pull/459
  def permit_postgresql!
    db_hosts.each do |host|
      next if host.start_with?('/') # Exclude UNIX sockets

      # https://github.com/ged/ruby-pg/blob/252512608a814de16bbad55911f9bbcef0e73cb9/lib/pg/connection.rb#L720
      allow(Addrinfo).to receive(:getaddrinfo).with(host, anything, nil, :STREAM).and_call_original
    end
  end

  def db_hosts
    ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).map(&:host).compact.uniq
  end
end
