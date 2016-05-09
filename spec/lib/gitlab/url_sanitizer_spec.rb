require 'spec_helper'

describe Gitlab::UrlSanitizer, lib: true do
  let(:credentials) { { user: 'blah', password: 'password' } }
  let(:url_sanitizer) do
    described_class.new("https://github.com/me/project.git", credentials: credentials)
  end

  describe '#full_url' do
    it { expect(url_sanitizer.full_url).to eq("https://blah:password@github.com/me/project.git") }
  end

  describe '#sanitized_url' do
    it { expect(url_sanitizer.sanitized_url).to eq("https://github.com/me/project.git") }
  end

  describe '#credentials' do
    it { expect(url_sanitizer.credentials).to eq(credentials) }
  end

  describe '.sanitize' do
    let(:filtered_content) do
      described_class.sanitize(%Q{remote: Not Found
         fatal: repository 'http://user:pass@test.com/root/repoC.git/' not found
         remote: Not Found
         fatal: repository 'https://user:pass@test.com/root/repoA.git/' not found
         remote: Not Found
         ssh://user@host.test/path/to/repo.git
         remote: Not Found
         git://host.test/path/to/repo.git
      })
    end

    it 'remove credentials from HTTP URLs' do
      expect(filtered_content).to include("http://test.com/root/repoC.git/")
    end

    it 'remove credentials from HTTPS URLs' do
      expect(filtered_content).to include("https://test.com/root/repoA.git/")
    end

    it 'remove credentials from SSH URLs' do
      expect(filtered_content).to include("ssh://host.test/path/to/repo.git")
    end

    it 'does not modify Git URLs' do
      # git protocol does not support authentication
      expect(filtered_content).to include("git://host.test/path/to/repo.git")
    end
  end
end
