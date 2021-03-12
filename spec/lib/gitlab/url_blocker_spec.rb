# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UrlBlocker, :stub_invalid_dns_only do
  include StubRequests

  describe '#validate!' do
    subject { described_class.validate!(import_url) }

    shared_examples 'validates URI and hostname' do
      it 'runs the url validations' do
        uri, hostname = subject

        expect(uri).to eq(Addressable::URI.parse(expected_uri))
        expect(hostname).to eq(expected_hostname)
      end
    end

    context 'when URI is nil' do
      let(:import_url) { nil }

      it_behaves_like 'validates URI and hostname' do
        let(:expected_uri) { nil }
        let(:expected_hostname) { nil }
      end
    end

    context 'when URI is internal' do
      let(:import_url) { 'http://localhost' }

      before do
        stub_dns(import_url, ip_address: '127.0.0.1')
      end

      it_behaves_like 'validates URI and hostname' do
        let(:expected_uri) { 'http://127.0.0.1' }
        let(:expected_hostname) { 'localhost' }
      end
    end

    context 'when the URL hostname is a domain' do
      context 'when domain can be resolved' do
        let(:import_url) { 'https://example.org' }

        before do
          stub_dns(import_url, ip_address: '93.184.216.34')
        end

        it_behaves_like 'validates URI and hostname' do
          let(:expected_uri) { 'https://93.184.216.34' }
          let(:expected_hostname) { 'example.org' }
        end
      end

      context 'when domain cannot be resolved' do
        let(:import_url) { 'http://foobar.x' }

        it 'raises an error' do
          stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')

          expect { subject }.to raise_error(described_class::BlockedUrlError)
        end
      end

      context 'when domain is too long' do
        let(:import_url) { 'https://example' + 'a' * 1024 + '.com' }

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::BlockedUrlError)
        end
      end
    end

    context 'when the URL hostname is an IP address' do
      let(:import_url) { 'https://93.184.216.34' }

      it_behaves_like 'validates URI and hostname' do
        let(:expected_uri) { import_url }
        let(:expected_hostname) { nil }
      end

      context 'when the address is invalid' do
        let(:import_url) { 'http://1.1.1.1.1' }

        it 'raises an error' do
          stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')

          expect { subject }.to raise_error(described_class::BlockedUrlError)
        end
      end
    end

    context 'DNS rebinding protection with IP allowed' do
      let(:import_url) { 'http://a.192.168.0.120.3times.127.0.0.1.1time.repeat.rebind.network:9121/scrape?target=unix:///var/opt/gitlab/redis/redis.socket&amp;check-keys=*' }

      before do
        stub_dns(import_url, ip_address: '192.168.0.120')

        allow(Gitlab::UrlBlockers::UrlAllowlist).to receive(:ip_allowed?).and_return(true)
      end

      it_behaves_like 'validates URI and hostname' do
        let(:expected_uri) { 'http://192.168.0.120:9121/scrape?target=unix:///var/opt/gitlab/redis/redis.socket&amp;check-keys=*' }
        let(:expected_hostname) { 'a.192.168.0.120.3times.127.0.0.1.1time.repeat.rebind.network' }
      end
    end

    context 'disabled DNS rebinding protection' do
      subject { described_class.validate!(import_url, dns_rebind_protection: false) }

      context 'when URI is internal' do
        let(:import_url) { 'http://localhost' }

        it_behaves_like 'validates URI and hostname' do
          let(:expected_uri) { import_url }
          let(:expected_hostname) { nil }
        end
      end

      context 'when the URL hostname is a domain' do
        let(:import_url) { 'https://example.org' }

        before do
          stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')
        end

        context 'when domain can be resolved' do
          it_behaves_like 'validates URI and hostname' do
            let(:expected_uri) { import_url }
            let(:expected_hostname) { nil }
          end
        end

        context 'when domain cannot be resolved' do
          let(:import_url) { 'http://foobar.x' }

          it_behaves_like 'validates URI and hostname' do
            let(:expected_uri) { import_url }
            let(:expected_hostname) { nil }
          end
        end
      end

      context 'when the URL hostname is an IP address' do
        let(:import_url) { 'https://93.184.216.34' }

        it_behaves_like 'validates URI and hostname' do
          let(:expected_uri) { import_url }
          let(:expected_hostname) { nil }
        end

        context 'when it is invalid' do
          let(:import_url) { 'http://1.1.1.1.1' }

          it_behaves_like 'validates URI and hostname' do
            let(:expected_uri) { import_url }
            let(:expected_hostname) { nil }
          end
        end
      end
    end
  end

  describe '#blocked_url?' do
    let(:ports) { Project::VALID_IMPORT_PORTS }

    it 'allows imports from configured web host and port' do
      import_url = "http://#{Gitlab.host_with_port}/t.git"
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
      web_url = "javascript://#{Gitlab.host_with_port}/t.git%0aalert(1)"
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

      shared_examples 'allows local requests' do |url_blocker_attributes|
        it 'does not block urls from private networks' do
          local_ips.each do |ip|
            stub_domain_resolv(fake_domain, ip) do
              expect(described_class).not_to be_blocked_url("http://#{fake_domain}", **url_blocker_attributes)
            end

            expect(described_class).not_to be_blocked_url("http://#{ip}", **url_blocker_attributes)
          end
        end

        it 'allows localhost endpoints' do
          expect(described_class).not_to be_blocked_url('http://0.0.0.0', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://localhost', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://127.0.0.1', **url_blocker_attributes)
        end

        it 'allows loopback endpoints' do
          expect(described_class).not_to be_blocked_url('http://127.0.0.2', **url_blocker_attributes)
        end

        it 'allows IPv4 link-local endpoints' do
          expect(described_class).not_to be_blocked_url('http://169.254.169.254', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://169.254.168.100', **url_blocker_attributes)
        end

        it 'allows IPv6 link-local endpoints' do
          expect(described_class).not_to be_blocked_url('http://[0:0:0:0:0:ffff:169.254.169.254]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[::ffff:169.254.169.254]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[::ffff:a9fe:a9fe]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[0:0:0:0:0:ffff:169.254.168.100]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[::ffff:169.254.168.100]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[::ffff:a9fe:a864]', **url_blocker_attributes)
          expect(described_class).not_to be_blocked_url('http://[fe80::c800:eff:fe74:8]', **url_blocker_attributes)
        end
      end

      context 'true (default)' do
        it_behaves_like 'allows local requests', { allow_localhost: true, allow_local_network: true }
      end

      context 'false' do
        it 'blocks urls from private networks' do
          local_ips.each do |ip|
            stub_domain_resolv(fake_domain, ip) do
              expect(described_class).to be_blocked_url("http://#{fake_domain}", allow_local_network: false)
            end

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

        context 'when local domain/IP is allowed' do
          let(:url_blocker_attributes) do
            {
              allow_localhost: false,
              allow_local_network: false
            }
          end

          before do
            allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
            stub_application_setting(outbound_local_requests_whitelist: allowlist)
          end

          context 'with IPs in allowlist' do
            let(:allowlist) do
              [
                '0.0.0.0',
                '127.0.0.1',
                '127.0.0.2',
                '192.168.1.1',
                '192.168.1.2',
                '0:0:0:0:0:ffff:192.168.1.2',
                '::ffff:c0a8:102',
                '10.0.0.2',
                '0:0:0:0:0:ffff:10.0.0.2',
                '::ffff:a00:2',
                '172.16.0.2',
                '0:0:0:0:0:ffff:172.16.0.2',
                '::ffff:ac10:20',
                'feef::1',
                'fee2::',
                'fc00:bf8b:e62c:abcd:abcd:aaaa:aaaa:aaaa',
                '0:0:0:0:0:ffff:169.254.169.254',
                '::ffff:a9fe:a9fe',
                '::ffff:169.254.168.100',
                '::ffff:a9fe:a864',
                'fe80::c800:eff:fe74:8',

                # garbage IPs
                '45645632345',
                'garbage456:more345gar:bage'
              ]
            end

            it_behaves_like 'allows local requests', { allow_localhost: false, allow_local_network: false }

            it 'allows IP when dns_rebind_protection is disabled' do
              url = "http://example.com"
              attrs = url_blocker_attributes.merge(dns_rebind_protection: false)

              stub_domain_resolv('example.com', '192.168.1.2') do
                expect(described_class).not_to be_blocked_url(url, **attrs)
              end

              stub_domain_resolv('example.com', '192.168.1.3') do
                expect(described_class).to be_blocked_url(url, **attrs)
              end
            end
          end

          context 'with domains in allowlist' do
            let(:allowlist) do
              [
                'www.example.com',
                'example.com',
                'xn--itlab-j1a.com',
                'garbage$^$%#$^&$'
              ]
            end

            it 'allows domains present in allowlist' do
              domain = 'example.com'
              subdomain1 = 'www.example.com'
              subdomain2 = 'subdomain.example.com'

              stub_domain_resolv(domain, '192.168.1.1') do
                expect(described_class).not_to be_blocked_url("http://#{domain}",
                  **url_blocker_attributes)
              end

              stub_domain_resolv(subdomain1, '192.168.1.1') do
                expect(described_class).not_to be_blocked_url("http://#{subdomain1}",
                  **url_blocker_attributes)
              end

              # subdomain2 is not part of the allowlist so it should be blocked
              stub_domain_resolv(subdomain2, '192.168.1.1') do
                expect(described_class).to be_blocked_url("http://#{subdomain2}",
                  **url_blocker_attributes)
              end
            end

            it 'works with unicode and idna encoded domains' do
              unicode_domain = 'ğitlab.com'
              idna_encoded_domain = 'xn--itlab-j1a.com'

              stub_domain_resolv(unicode_domain, '192.168.1.1') do
                expect(described_class).not_to be_blocked_url("http://#{unicode_domain}",
                  **url_blocker_attributes)
              end

              stub_domain_resolv(idna_encoded_domain, '192.168.1.1') do
                expect(described_class).not_to be_blocked_url("http://#{idna_encoded_domain}",
                  **url_blocker_attributes)
              end
            end

            shared_examples 'dns rebinding checks' do
              shared_examples 'allowlists the domain' do
                let(:allowlist) { [domain] }
                let(:url) { "http://#{domain}" }

                before do
                  stub_env('RSPEC_ALLOW_INVALID_URLS', 'false')
                end

                it do
                  expect(described_class).not_to be_blocked_url(url, dns_rebind_protection: dns_rebind_value)
                end
              end

              context 'when dns_rebinding_setting is' do
                context 'enabled' do
                  let(:dns_rebind_value) { true }

                  it_behaves_like 'allowlists the domain'
                end

                context 'disabled' do
                  let(:dns_rebind_value) { false }

                  it_behaves_like 'allowlists the domain'
                end
              end
            end

            context 'when the domain cannot be resolved' do
              let(:domain) { 'foobar.x' }

              it_behaves_like 'dns rebinding checks'
            end

            context 'when the domain can be resolved' do
              let(:domain) { 'example.com' }

              before do
                stub_dns(url, ip_address: '93.184.216.34')
              end

              it_behaves_like 'dns rebinding checks'
            end
          end

          context 'with ports' do
            let(:allowlist) do
              ["127.0.0.1:2000"]
            end

            it 'allows domain with port when resolved ip has port allowed' do
              stub_domain_resolv("www.resolve-domain.com", '127.0.0.1') do
                expect(described_class).not_to be_blocked_url("http://www.resolve-domain.com:2000", **url_blocker_attributes)
              end
            end
          end
        end
      end

      def stub_domain_resolv(domain, ip, port = 80, &block)
        address = instance_double(Addrinfo,
          ip_address: ip,
          ipv4_private?: true,
          ipv6_linklocal?: false,
          ipv4_loopback?: false,
          ipv6_loopback?: false,
          ipv4?: false,
          ip_port: port
        )
        allow(Addrinfo).to receive(:getaddrinfo).with(domain, port, any_args).and_return([address])
        allow(address).to receive(:ipv6_v4mapped?).and_return(false)

        yield

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

  describe '#validate_hostname' do
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
        expect { described_class.send(:validate_hostname, ip) }.not_to raise_error
      end
    end
  end
end
