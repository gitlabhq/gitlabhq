# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DependencyLinker::CargoTomlLinker, feature_category: :source_code_management do
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
        indicatif = { version = "0.17.5", features = ["rayon"] }

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

        # Dependencies with a custom location should be ignored
        path-ignored = { path = "local" }
        git-ignored = { git = "https://example.com/.git" }
        registry-ignored = { registry = "custom-registry" }

        [build-dependencies.bracked-ignored]
        path = "local"

        # Unless they specify a version and no registry
        [build-dependencies.rand]
        version = "0.8.5"
        path = "../rand"

        [build-dependencies.custom-rand]
        version = "0.8.5"
        path = "../custom-rand"
        registry = "custom-registry"
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %(<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>)
    end

    it 'links dependencies' do
      expect(subject).to include(link('chrono', 'https://crates.io/crates/chrono'))
      expect(subject).to include(link('xml-rs', 'https://crates.io/crates/xml-rs'))
      expect(subject).to include(link('memchr', 'https://crates.io/crates/memchr'))
      expect(subject).to include(link('commandspec', 'https://crates.io/crates/commandspec'))
      expect(subject).to include(link('thread_local', 'https://crates.io/crates/thread_local'))
    end

    it 'links dependencies that use an inline table' do
      expect(subject).to include(link('indicatif', 'https://crates.io/crates/indicatif'))
    end

    it 'links dependencies that include a version but no registry' do
      expect(subject).to include(link('rand', 'https://crates.io/crates/rand'))
    end

    it 'does not contain metadata identified as package' do
      expect(subject).not_to include(link('version', 'https://crates.io/crates/version'))
    end

    it 'does not link dependencies without a version' do
      expect(subject).not_to include(link('path-ignored', 'https://crates.io/crates/path-ignored'))
      expect(subject).not_to include(link('git-ignored', 'https://crates.io/crates/git-ignored'))
      expect(subject).not_to include(link('bracked-ignored', 'https://crates.io/crates/bracked-ignored'))
    end

    it 'does not link dependencies with a custom registry' do
      expect(subject).not_to include(link('registry-ignored', 'https://crates.io/crates/registry-ignored'))
      expect(subject).not_to include(link('custom-rand', 'https://crates.io/crates/custom-rand'))
    end

    context 'when file contents contain special regular expressions' do
      let(:file_content) do
        <<-CONTENT.strip_heredoc
          [dependencies]
          chrono = "0.4.7"
          ".*((a|a)+|c)+"= { version = "0.17.5", path = ["aaaaaaaaaaaaaaaaaaa"] }
          ".*((a|a)+|d)+"="aaaaaaaaaaaaaaaaaaa"

          [dependencies.".*((a|a)+|e)+"]
          version = "1.2.3"
          path = "aaaaaaaaaaaaaaaaaaa"
        CONTENT
      end

      it 'protects against malicious backtracking' do
        expect do
          Timeout.timeout(Gitlab::OtherMarkup::RENDER_TIMEOUT.seconds) { subject }
        end.not_to raise_error
        expect(subject).to include(link('chrono', 'https://crates.io/crates/chrono'))
      end
    end
  end
end
