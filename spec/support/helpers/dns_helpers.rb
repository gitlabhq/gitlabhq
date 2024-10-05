# frozen_string_literal: true

module DnsHelpers
  include ViteHelper
  # strong_memoize is used in a class method, so we extend it instead of including it.
  extend Gitlab::Utils::StrongMemoize

  def block_dns!
    stub_all_dns!
    stub_invalid_dns!
    permit_local_dns!
    permit_postgresql!
    permit_redis!
    permit_vite!
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

  def self.redis_hosts
    # This needs to be a class method so that the memoization sticks across different specs.
    # Without memoization, this adds a considerable amount of time to each spec execution.
    strong_memoize(:redis_hosts) do
      Gitlab::Redis::ALL_CLASSES.flat_map do |redis_instance|
        redis_instance.params[:host] || redis_instance.params[:nodes]&.map { |n| n[:host] }
      end.uniq.compact
    end
  end

  def permit_redis!
    # https://github.com/redis-rb/redis-client/blob/v0.11.2/lib/redis_client/ruby_connection.rb#L51 uses Socket.tcp that
    # calls Addrinfo.getaddrinfo internally.

    DnsHelpers.redis_hosts.each do |host|
      allow(Addrinfo).to receive(:getaddrinfo).with(host, anything, nil, :STREAM, anything, anything, any_args).and_call_original
    end
  end

  def permit_vite!
    # https://github.com/ElMassimo/vite_ruby/blob/7d2f558c9760802e5d763bfa40efe87607eb166a/vite_ruby/lib/vite_ruby.rb#L91
    # uses Socket.tcp to connect to vite dev server - this won't necessarily be localhost
    return unless vite_enabled?

    allow(Addrinfo).to receive(:getaddrinfo).with(ViteRuby.instance.config.host, ViteRuby.instance.config.port, nil, :STREAM, anything, anything, any_args).and_call_original
  end

  def stub_resolver(stubbed_lookups = {})
    resolver = instance_double('Resolv::DNS')
    allow(resolver).to receive(:timeouts=)

    expect(Resolv::DNS).to receive(:open).and_yield(resolver)

    allow(resolver).to receive(:getresources).and_return([])
    stubbed_lookups.each do |domain, records|
      records = Array(records).map { |txt| Resolv::DNS::Resource::IN::TXT.new(txt) }
      # Append '.' to domain_name, indicating absolute FQDN
      allow(resolver).to receive(:getresources).with("#{domain}.", Resolv::DNS::Resource::IN::TXT) { records }
    end

    resolver
  end
end
