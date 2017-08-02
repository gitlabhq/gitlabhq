require 'spec_helper'

describe Gitlab::UrlBlocker do
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

    it 'returns true for invalid URL' do
      expect(described_class.blocked_url?('http://:8080')).to be true
    end

    it 'returns false for legitimate URL' do
      expect(described_class.blocked_url?('https://gitlab.com/foo/foo.git')).to be false
    end
  end
end
