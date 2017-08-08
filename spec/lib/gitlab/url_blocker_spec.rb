require 'spec_helper'

describe Gitlab::UrlBlocker, lib: true do
  describe '#blocked_url?' do
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
      expect(described_class.blocked_url?('https://gitlab.com:25/foo/foo.git')).to be true
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
  end

  # Resolv does not support resolving UTF-8 domain names
  # See https://bugs.ruby-lang.org/issues/4270
  def stub_resolv
    allow(Resolv).to receive(:getaddresses).and_return([])
  end
end
