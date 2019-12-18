# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::DependencyLinker::CargoTomlLinker do
  describe '.support?' do
    it 'supports Cargo.toml' do
      expect(described_class.support?('Cargo.toml')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('cargo.yaml')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "Cargo.toml" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        # See https://doc.rust-lang.org/cargo/reference/manifest.html
        [package]
        # Package shouldn't be matched
        name = "gitlab-test"
        version = "0.0.1"
        authors = ["Some User <some.user@example.org>"]
        description = "A GitLab test Cargo.toml."
        keywords = ["gitlab", "test", "rust", "crago"]
        readme = "README.md"

        [dependencies]
        # Default dependencies format with fixed version and version range
        chrono = "0.4.7"
        xml-rs = ">=0.8.0"

        [dependencies.memchr]
        # Specific dependency with optional info
        version = "2.2.1"
        optional = true

        [dev-dependencies]
        # Dev dependency with version modifier
        commandspec = "~0.12.2"

        [build-dependencies]
        # Build dependency with version wildcard
        thread_local = "0.3.*"
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %{<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>}
    end

    it 'links dependencies' do
      expect(subject).to include(link('chrono', 'https://crates.io/crates/chrono'))
      expect(subject).to include(link('xml-rs', 'https://crates.io/crates/xml-rs'))
      expect(subject).to include(link('memchr', 'https://crates.io/crates/memchr'))
      expect(subject).to include(link('commandspec', 'https://crates.io/crates/commandspec'))
      expect(subject).to include(link('thread_local', 'https://crates.io/crates/thread_local'))
    end

    it 'does not contain metadata identified as package' do
      expect(subject).not_to include(link('version', 'https://crates.io/crates/version'))
    end
  end
end
