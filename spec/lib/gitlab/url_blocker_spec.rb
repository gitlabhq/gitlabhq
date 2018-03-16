require 'spec_helper'

describe Gitlab::UrlBlocker do
  describe '#blocked_url?' do
    let(:valid_ports) { Project::VALID_IMPORT_PORTS }

    it 'allows imports from configured web host and port' do
      import_url = "http://#{Gitlab.config.gitlab.host}:#{Gitlab.config.gitlab.port}/t.git"
      expect(described_class.blocked_url?(import_url)).to be false
    end

    it 'allows imports from configured SSH host and port' do
      import_url = "http://#{Gitlab.config.gitlab_shell.ssh_host}:#{Gitlab.config.gitlab_shell.ssh_port}/t.git"
      expect(described_class.blocked_url?(import_url)).to be false
    end

    it 'returns true for bad localhost hostname' do
      expect(described_class.blocked_url?('https://localhost:65535/foo/foo.git')).to be true
    end

    it 'returns true for bad port' do
      expect(described_class.blocked_url?('https://gitlab.com:25/foo/foo.git', valid_ports: valid_ports)).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (0177.1)' do
      expect(described_class.blocked_url?('https://0177.1:65535/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (0x7f.1)' do
      expect(described_class.blocked_url?('https://0x7f.1:65535/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (2130706433)' do
      expect(described_class.blocked_url?('https://2130706433:65535/foo/foo.git')).to be true
    end

    it 'returns true for alternative version of 127.0.0.1 (127.000.000.001)' do
      expect(described_class.blocked_url?('https://127.000.000.001:65535/foo/foo.git')).to be true
    end

    it 'returns true for a non-alphanumeric hostname' do
      stub_resolv

      aggregate_failures do
        expect(described_class).to be_blocked_url('ssh://-oProxyCommand=whoami/a')

        # The leading character here is a Unicode "soft hyphen"
        expect(described_class).to be_blocked_url('ssh://­oProxyCommand=whoami/a')

        # Unicode alphanumerics are allowed
        expect(described_class).not_to be_blocked_url('ssh://ğitlab.com/a')
      end
    end

    it 'returns true for a non-alphanumeric username' do
      stub_resolv

      aggregate_failures do
        expect(described_class).to be_blocked_url('ssh://-oProxyCommand=whoami@example.com/a')

        # The leading character here is a Unicode "soft hyphen"
        expect(described_class).to be_blocked_url('ssh://­oProxyCommand=whoami@example.com/a')

        # Unicode alphanumerics are allowed
        expect(described_class).not_to be_blocked_url('ssh://ğitlab@example.com/a')
      end
    end

    it 'returns true for invalid URL' do
      expect(described_class.blocked_url?('http://:8080')).to be true
    end

    it 'returns false for legitimate URL' do
      expect(described_class.blocked_url?('https://gitlab.com/foo/foo.git')).to be false
    end

    context 'when allow_private_networks is' do
      let(:private_networks) { ['192.168.1.2', '10.0.0.2', '172.16.0.2'] }
      let(:fake_domain) { 'www.fakedomain.fake' }

      context 'true (default)' do
        it 'does not block urls from private networks' do
          private_networks.each do |ip|
            stub_domain_resolv(fake_domain, ip)

            expect(described_class).not_to be_blocked_url("http://#{fake_domain}")

            unstub_domain_resolv

            expect(described_class).not_to be_blocked_url("http://#{ip}")
          end
        end
      end

      context 'false' do
        it 'blocks urls from private networks' do
          private_networks.each do |ip|
            stub_domain_resolv(fake_domain, ip)

            expect(described_class).to be_blocked_url("http://#{fake_domain}", allow_private_networks: false)

            unstub_domain_resolv

            expect(described_class).to be_blocked_url("http://#{ip}", allow_private_networks: false)
          end
        end
      end

      def stub_domain_resolv(domain, ip)
        allow(Addrinfo).to receive(:getaddrinfo).with(domain, any_args).and_return([double(ip_address: ip, ipv4_private?: true)])
      end

      def unstub_domain_resolv
        allow(Addrinfo).to receive(:getaddrinfo).and_call_original
      end
    end
  end

  # Resolv does not support resolving UTF-8 domain names
  # See https://bugs.ruby-lang.org/issues/4270
  def stub_resolv
    allow(Resolv).to receive(:getaddresses).and_return([])
  end
end
