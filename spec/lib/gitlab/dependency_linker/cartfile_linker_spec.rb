# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DependencyLinker::CartfileLinker do
  describe '.support?' do
    it 'supports Cartfile' do
      expect(described_class.support?('Cartfile')).to be_truthy
    end

    it 'supports Cartfile.private' do
      expect(described_class.support?('Cartfile.private')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('test.Cartfile')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "Cartfile" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        # Require version 2.3.1 or later
        github "ReactiveCocoa/ReactiveCocoa" >= 2.3.1

        # Require version 1.x
        github "Mantle/Mantle" ~> 1.0    # (1.0 or later, but less than 2.0)

        # Require exactly version 0.4.1
        github "jspahrsummers/libextobjc" == 0.4.1

        # Use the latest version
        github "jspahrsummers/xcconfigs"

        # Use the branch
        github "jspahrsummers/xcconfigs" "branch"

        # Use a project from GitHub Enterprise
        github "https://enterprise.local/ghe/desktop/git-error-translations"

        # Use a project from any arbitrary server, on the "development" branch
        git "https://enterprise.local/desktop/git-error-translations2.git" "development"

        # Use a local project
        git "file:///directory/to/project" "branch"

        # A binary only framework
        binary "https://my.domain.com/release/MyFramework.json" ~> 2.3
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %(<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>)
    end

    it 'links dependencies' do
      expect(subject).to include(link('ReactiveCocoa/ReactiveCocoa', 'https://github.com/ReactiveCocoa/ReactiveCocoa'))
      expect(subject).to include(link('Mantle/Mantle', 'https://github.com/Mantle/Mantle'))
      expect(subject).to include(link('jspahrsummers/libextobjc', 'https://github.com/jspahrsummers/libextobjc'))
      expect(subject).to include(link('jspahrsummers/xcconfigs', 'https://github.com/jspahrsummers/xcconfigs'))
    end

    it 'links Git repos' do
      expect(subject).to include(link('https://enterprise.local/ghe/desktop/git-error-translations', 'https://enterprise.local/ghe/desktop/git-error-translations'))
      expect(subject).to include(link('https://enterprise.local/desktop/git-error-translations2.git', 'https://enterprise.local/desktop/git-error-translations2.git'))
    end

    it 'links binary-only frameworks' do
      expect(subject).to include(link('https://my.domain.com/release/MyFramework.json', 'https://my.domain.com/release/MyFramework.json'))
    end
  end
end
