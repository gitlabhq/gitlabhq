# coding: utf-8
require 'spec_helper'

describe Gitlab::UrlBlocker do
  describe '#validate!' do
    context 'when URI is nil' do
      let(:import_url) { nil }

      it 'returns no URI and hostname' do
        uri, hostname = described_class.validate!(import_url)

        expect(uri).to be(nil)
        expect(hostname).to be(nil)
      end
    end

    context 'when URI is internal' do
      let(:import_url) { 'http://localhost' }

      it 'returns URI and no hostname' do
        uri, hostname = described_class.validate!(import_url)

        expect(uri).to eq(Addressable::URI.parse('http://[::1]'))
        expect(hostname).to eq('localhost')
      end
    end

    context 'when the URL hostname is a domain' do
      let(:import_url) { 'https://example.org' }

      it 'returns URI and hostname' do
        uri, hostname = described_class.validate!(import_url)

        expect(uri).to eq(Addressable::URI.parse('https://93.184.216.34'))
        expect(hostname).to eq('example.org')
      end
    end

    context 'when the URL hostname is an IP address' do
      let(:import_url) { 'https://93.184.216.34' }

      it 'returns URI and no hostname' do
        uri, hostname = described_class.validate!(import_url)

        expect(uri).to eq(Addressable::URI.parse('https://93.184.216.34'))
        expect(hostname).to be(nil)
      end
    end

    context 'disabled DNS rebinding protection' do
      context 'when URI is internal' do
        let(:import_url) { 'http://localhost' }

        it 'returns URI and no hostname' do
          uri, hostname = described_class.validate!(import_url, dns_rebind_protection: false)

          expect(uri).to eq(Addressable::URI.parse('http://localhost'))
          expect(hostname).to be(nil)
        end
      end

      context 'when the URL hostname is a domain' do
        let(:import_url) { 'https://example.org' }

        it 'returns URI and no hostname' do
          uri, hostname = described_class.validate!(import_url, dns_rebind_protection: false)

          expect(uri).to eq(Addressable::URI.parse('https://example.org'))
          expect(hostname).to eq(nil)
        end

        context 'when it cannot be resolved' do
          let(:import_url) { 'http://foobar.x' }

          it 'raises error' do
            stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')

            expect { described_class.validate!(import_url) }.to raise_error(described_class::BlockedUrlError)
          end
        end
      end

      context 'when the URL hostname is an IP address' do
        let(:import_url) { 'https://93.184.216.34' }

        it 'returns URI and no hostname' do
          uri, hostname = described_class.validate!(import_url, dns_rebind_protection: false)

          expect(uri).to eq(Addressable::URI.parse('https://93.184.216.34'))
          expect(hostname).to be(nil)
        end

        context 'when it is invalid' do
          let(:import_url) { 'http://1.1.1.1.1' }

          it 'raises an error' do
            stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')

            expect { described_class.validate!(import_url) }.to raise_error(described_class::BlockedUrlError)
          end
        end
      end
    end
  end

  describe '#blocked_url?' do
    let(:ports) { Project::VALID_IMPORT_PORTS }

    it 'allows imports from configured web host and port' do
      import_url = "http://#{Gitlab.config.gitlab.host}:#{Gitlab.config.gitlab.port}/t.git"
      expect(described_class.blocked_url?(import_url)).to be false
    end

    it 'allows mirroring from configured SSH host and port' do
      import_url = "ssh://#{Gitlab.config.gitlab_shell.ssh_host}:#{Gitlab.config.gitlab_shell.ssh_port}/t.git"
      expect(described_class.blocked_url?(import_url)).to be false
    end

    it 'returns true for bad localhost hostname' do
      expect(described_class.blocked_url?('https://localhost:65535/foo/foo.git')).to be true
    end

    it 'returns true for bad port' do
      expect(described_class.blocked_url?('https://gitlab.com:25/foo/foo.git', ports: ports)).to be true
    end

    it 'returns true for bad scheme' do
      expect(described_class.blocked_url?('https://gitlab.com/foo/foo.git', schemes: ['https'])).to be false
      expect(described_class.blocked_url?('https://gitlab.com/foo/foo.git')).to be false
      expect(described_class.blocked_url?('https://gitlab.com/foo/foo.git', schemes: ['http'])).to be true
    end

    it 'returns true for bad protocol on configured web/SSH host and ports' do
      web_url = "javascript://#{Gitlab.config.gitlab.host}:#{Gitlab.config.gitlab.port}/t.git%0aalert(1)"
      expect(described_class.blocked_url?(web_url)).to be true

      ssh_url = "javascript://#{Gitlab.config.gitlab_shell.ssh_host}:#{Gitlab.config.gitlab_shell.ssh_port}/t.git%0aalert(1)"
      expect(described_class.blocked_url?(ssh_url)).to be true
    end

    it 'returns true for localhost IPs' do
      expect(described_class.blocked_url?('https://[0:0:0:0:0:0:0:0]/foo/foo.git')).to be true
      expect(described_class.blocked_url?('https://0.0.0.0/foo/foo.git')).to be true
      expect(described_class.blocked_url?('https://[::]/foo/foo.git')).to be true
    end

    it 'returns true for loopback IP' do
      expect(described_class.blocked_url?('https://127.0.0.2/foo/foo.git')).to be true
      expect(described_class.blocked_url?('https://127.0.0.1/foo/foo.git')).to be true
      expect(described_class.blocked_url?('https://[::1]/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (0177.1)' do
      expect(described_class.blocked_url?('https://0177.1:65535/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (017700000001)' do
      expect(described_class.blocked_url?('https://017700000001:65535/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (0x7f.1)' do
      expect(described_class.blocked_url?('https://0x7f.1:65535/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (0x7f.0.0.1)' do
      expect(described_class.blocked_url?('https://0x7f.0.0.1:65535/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (0x7f000001)' do
      expect(described_class.blocked_url?('https://0x7f000001:65535/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (2130706433)' do
      expect(described_class.blocked_url?('https://2130706433:65535/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (127.000.000.001)' do
      expect(described_class.blocked_url?('https://127.000.000.001:65535/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (127.0.1)' do
      expect(described_class.blocked_url?('https://127.0.1:65535/foo/foo.git')).to be true
    end

    context 'with ipv6 mapped address' do
      it 'returns true for localhost IPs' do
        expect(described_class.blocked_url?('https://[0:0:0:0:0:ffff:0.0.0.0]/foo/foo.git')).to be true
        expect(described_class.blocked_url?('https://[::ffff:0.0.0.0]/foo/foo.git')).to be true
        expect(described_class.blocked_url?('https://[::ffff:0:0]/foo/foo.git')).to be true
      end

      it 'returns true for loopback IPs' do
        expect(described_class.blocked_url?('https://[0:0:0:0:0:ffff:127.0.0.1]/foo/foo.git')).to be true
        expect(described_class.blocked_url?('https://[::ffff:127.0.0.1]/foo/foo.git')).to be true
        expect(described_class.blocked_url?('https://[::ffff:7f00:1]/foo/foo.git')).to be true
        expect(described_class.blocked_url?('https://[0:0:0:0:0:ffff:127.0.0.2]/foo/foo.git')).to be true
        expect(described_class.blocked_url?('https://[::ffff:127.0.0.2]/foo/foo.git')).to be true
        expect(described_class.blocked_url?('https://[::ffff:7f00:2]/foo/foo.git')).to be true
      end
    end

    it 'returns true for a non-alphanumeric hostname' do
      aggregate_failures do
        expect(described_class).to be_blocked_url('ssh://-oProxyCommand=whoami/a')

        # The leading character here is a Unicode "soft hyphen"
        expect(described_class).to be_blocked_url('ssh://­oProxyCommand=whoami/a')

        # Unicode alphanumerics are allowed
        expect(described_class).not_to be_blocked_url('ssh://ğitlab.com/a')
      end
    end

    it 'returns true for invalid URL' do
      expect(described_class.blocked_url?('http://:8080')).to be true
    end

    it 'returns false for legitimate URL' do
      expect(described_class.blocked_url?('https://gitlab.com/foo/foo.git')).to be false
    end

    context 'when allow_local_network is' do
      let(:local_ips) do
        [
          '192.168.1.2',
          '[0:0:0:0:0:ffff:192.168.1.2]',
          '[::ffff:c0a8:102]',
          '10.0.0.2',
          '[0:0:0:0:0:ffff:10.0.0.2]',
          '[::ffff:a00:2]',
          '172.16.0.2',
          '[0:0:0:0:0:ffff:172.16.0.2]',
          '[::ffff:ac10:20]',
          '[feef::1]',
          '[fee2::]',
          '[fc00:bf8b:e62c:abcd:abcd:aaaa:aaaa:aaaa]'
        ]
      end
      let(:fake_domain) { 'www.fakedomain.fake' }

      context 'true (default)' do
        it 'does not block urls from private networks' do
          local_ips.each do |ip|
            stub_domain_resolv(fake_domain, ip)

            expect(described_class).not_to be_blocked_url("http://#{fake_domain}")

            unstub_domain_resolv

            expect(described_class).not_to be_blocked_url("http://#{ip}")
          end
        end

        it 'allows localhost endpoints' do
          expect(described_class).not_to be_blocked_url('http://0.0.0.0', allow_localhost: true)
          expect(described_class).not_to be_blocked_url('http://localhost', allow_localhost: true)
          expect(described_class).not_to be_blocked_url('http://127.0.0.1', allow_localhost: true)
        end

        it 'allows loopback endpoints' do
          expect(described_class).not_to be_blocked_url('http://127.0.0.2', allow_localhost: true)
        end

        it 'allows IPv4 link-local endpoints' do
          expect(described_class).not_to be_blocked_url('http://169.254.169.254')
          expect(described_class).not_to be_blocked_url('http://169.254.168.100')
        end

        it 'allows IPv6 link-local endpoints' do
          expect(described_class).not_to be_blocked_url('http://[0:0:0:0:0:ffff:169.254.169.254]')
          expect(described_class).not_to be_blocked_url('http://[::ffff:169.254.169.254]')
          expect(described_class).not_to be_blocked_url('http://[::ffff:a9fe:a9fe]')
          expect(described_class).not_to be_blocked_url('http://[0:0:0:0:0:ffff:169.254.168.100]')
          expect(described_class).not_to be_blocked_url('http://[::ffff:169.254.168.100]')
          expect(described_class).not_to be_blocked_url('http://[::ffff:a9fe:a864]')
          expect(described_class).not_to be_blocked_url('http://[fe80::c800:eff:fe74:8]')
        end
      end

      context 'false' do
        it 'blocks urls from private networks' do
          local_ips.each do |ip|
            stub_domain_resolv(fake_domain, ip)

            expect(described_class).to be_blocked_url("http://#{fake_domain}", allow_local_network: false)

            unstub_domain_resolv

            expect(described_class).to be_blocked_url("http://#{ip}", allow_local_network: false)
          end
        end

        it 'blocks IPv4 link-local endpoints' do
          expect(described_class).to be_blocked_url('http://169.254.169.254', allow_local_network: false)
          expect(described_class).to be_blocked_url('http://169.254.168.100', allow_local_network: false)
        end

        it 'blocks IPv6 link-local endpoints' do
          expect(described_class).to be_blocked_url('http://[0:0:0:0:0:ffff:169.254.169.254]', allow_local_network: false)
          expect(described_class).to be_blocked_url('http://[::ffff:169.254.169.254]', allow_local_network: false)
          expect(described_class).to be_blocked_url('http://[::ffff:a9fe:a9fe]', allow_local_network: false)
          expect(described_class).to be_blocked_url('http://[0:0:0:0:0:ffff:169.254.168.100]', allow_local_network: false)
          expect(described_class).to be_blocked_url('http://[::ffff:169.254.168.100]', allow_local_network: false)
          expect(described_class).to be_blocked_url('http://[::ffff:a9fe:a864]', allow_local_network: false)
          expect(described_class).to be_blocked_url('http://[fe80::c800:eff:fe74:8]', allow_local_network: false)
        end
      end

      def stub_domain_resolv(domain, ip)
        address = double(ip_address: ip, ipv4_private?: true, ipv6_link_local?: false, ipv4_loopback?: false, ipv6_loopback?: false, ipv4?: false)
        allow(Addrinfo).to receive(:getaddrinfo).with(domain, any_args).and_return([address])
        allow(address).to receive(:ipv6_v4mapped?).and_return(false)
      end

      def unstub_domain_resolv
        allow(Addrinfo).to receive(:getaddrinfo).and_call_original
      end
    end

    context 'when enforce_user is' do
      context 'false (default)' do
        it 'does not block urls with a non-alphanumeric username' do
          expect(described_class).not_to be_blocked_url('ssh://-oProxyCommand=whoami@example.com/a')

          # The leading character here is a Unicode "soft hyphen"
          expect(described_class).not_to be_blocked_url('ssh://­oProxyCommand=whoami@example.com/a')

          # Unicode alphanumerics are allowed
          expect(described_class).not_to be_blocked_url('ssh://ğitlab@example.com/a')
        end
      end

      context 'true' do
        it 'blocks urls with a non-alphanumeric username' do
          aggregate_failures do
            expect(described_class).to be_blocked_url('ssh://-oProxyCommand=whoami@example.com/a', enforce_user: true)

            # The leading character here is a Unicode "soft hyphen"
            expect(described_class).to be_blocked_url('ssh://­oProxyCommand=whoami@example.com/a', enforce_user: true)

            # Unicode alphanumerics are allowed
            expect(described_class).not_to be_blocked_url('ssh://ğitlab@example.com/a', enforce_user: true)
          end
        end
      end
    end

    context 'when ascii_only is true' do
      it 'returns true for unicode domain' do
        expect(described_class.blocked_url?('https://𝕘itⅼαƄ.com/foo/foo.bar', ascii_only: true)).to be true
      end

      it 'returns true for unicode tld' do
        expect(described_class.blocked_url?('https://gitlab.ᴄοｍ/foo/foo.bar', ascii_only: true)).to be true
      end

      it 'returns true for unicode path' do
        expect(described_class.blocked_url?('https://gitlab.com/𝒇οο/𝒇οο.Ƅαꮁ', ascii_only: true)).to be true
      end

      it 'returns true for IDNA deviations' do
        expect(described_class.blocked_url?('https://mißile.com/foo/foo.bar', ascii_only: true)).to be true
        expect(described_class.blocked_url?('https://miςςile.com/foo/foo.bar', ascii_only: true)).to be true
        expect(described_class.blocked_url?('https://git‍lab.com/foo/foo.bar', ascii_only: true)).to be true
        expect(described_class.blocked_url?('https://git‌lab.com/foo/foo.bar', ascii_only: true)).to be true
      end
    end

    it 'blocks urls with invalid ip address' do
      stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')

      expect(described_class).to be_blocked_url('http://8.8.8.8.8')
    end

    it 'blocks urls whose hostname cannot be resolved' do
      stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')

      expect(described_class).to be_blocked_url('http://foobar.x')
    end
  end

  describe '#validate_hostname!' do
    let(:ip_addresses) do
      [
        '2001:db8:1f70::999:de8:7648:6e8',
        'FE80::C800:EFF:FE74:8',
        '::ffff:127.0.0.1',
        '::ffff:169.254.168.100',
        '::ffff:7f00:1',
        '0:0:0:0:0:ffff:0.0.0.0',
        'localhost',
        '127.0.0.1',
        '127.000.000.001',
        '0x7f000001',
        '0x7f.0.0.1',
        '0x7f.0.0.1',
        '017700000001',
        '0177.1',
        '2130706433',
        '::',
        '::1'
      ]
    end

    it 'does not raise error for valid Ip addresses' do
      ip_addresses.each do |ip|
        expect { described_class.send(:validate_hostname!, ip) }.not_to raise_error
      end
    end
  end
end
