require 'spec_helper'

describe Gitlab::UrlSanitizer, lib: true do
  let(:credentials) { { user: 'blah', password: 'password' } }
  let(:url_sanitizer) do
    described_class.new("https://github.com/me/project.git", credentials: credentials)
  end

  describe '.sanitize' do
    def sanitize_url(url)
      # We want to try with multi-line content because is how error messages are formatted
      described_class.sanitize(%Q{
         remote: Not Found
         fatal: repository '#{url}' not found
      })
    end

    it 'mask the credentials from HTTP URLs' do
      filtered_content = sanitize_url('http://user:pass@test.com/root/repoC.git/')

      expect(filtered_content).to include("http://*****:*****@test.com/root/repoC.git/")
    end

    it 'mask the credentials from HTTPS URLs' do
      filtered_content = sanitize_url('https://user:pass@test.com/root/repoA.git/')

      expect(filtered_content).to include("https://*****:*****@test.com/root/repoA.git/")
    end

    it 'mask credentials from SSH URLs' do
      filtered_content = sanitize_url('ssh://user@host.test/path/to/repo.git')

      expect(filtered_content).to include("ssh://*****@host.test/path/to/repo.git")
    end

    it 'does not modify Git URLs' do
      # git protocol does not support authentication
      filtered_content = sanitize_url('git://host.test/path/to/repo.git')

      expect(filtered_content).to include("git://host.test/path/to/repo.git")
    end

    it 'does not modify scp-like URLs' do
      filtered_content = sanitize_url('user@server:project.git')

      expect(filtered_content).to include("user@server:project.git")
    end

    it 'returns an empty string for invalid URLs' do
      filtered_content = sanitize_url('ssh://')

      expect(filtered_content).to include("repository '' not found")
    end
  end

  describe '#sanitized_url' do
    it { expect(url_sanitizer.sanitized_url).to eq("https://github.com/me/project.git") }
  end

  describe '#credentials' do
    it { expect(url_sanitizer.credentials).to eq(credentials) }
  end

  describe '#full_url' do
    it { expect(url_sanitizer.full_url).to eq("https://blah:password@github.com/me/project.git") }

    it 'supports scp-like URLs' do
      sanitizer = described_class.new('user@server:project.git')

      expect(sanitizer.full_url).to eq('user@server:project.git')
    end
  end

  describe '.valid?' do
    it 'validates url strings' do
      expect(described_class.valid?(nil)).to be(false)
      expect(described_class.valid?('valid@project:url.git')).to be(true)
      expect(described_class.valid?('123://invalid:url')).to be(false)
    end
  end
end
