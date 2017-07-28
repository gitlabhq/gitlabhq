require 'rails_helper'

describe Gitlab::DependencyLinker::GemfileLinker do
  describe '.support?' do
    it 'supports Gemfile' do
      expect(described_class.support?('Gemfile')).to be_truthy
    end

    it 'supports gems.rb' do
      expect(described_class.support?('gems.rb')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('Gemfile.lock')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { 'Gemfile' }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        source 'https://rubygems.org'

        gem "rails", '4.2.6', github: "rails/rails"
        gem 'rails-deprecated_sanitizer', '~> 1.0.3'
        gem 'responders', '~> 2.0', :github => 'rails/responders'
        gem 'sprockets', '~> 3.6.0', git: 'https://gitlab.example.com/gems/sprockets'
        gem 'default_value_for', '~> 3.0.0'
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %{<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>}
    end

    it 'links sources' do
      expect(subject).to include(link('https://rubygems.org', 'https://rubygems.org'))
    end

    it 'links dependencies' do
      expect(subject).to include(link('rails', 'https://rubygems.org/gems/rails'))
      expect(subject).to include(link('rails-deprecated_sanitizer', 'https://rubygems.org/gems/rails-deprecated_sanitizer'))
      expect(subject).to include(link('responders', 'https://rubygems.org/gems/responders'))
      expect(subject).to include(link('sprockets', 'https://rubygems.org/gems/sprockets'))
      expect(subject).to include(link('default_value_for', 'https://rubygems.org/gems/default_value_for'))
    end

    it 'links GitHub repos' do
      expect(subject).to include(link('rails/rails', 'https://github.com/rails/rails'))
      expect(subject).to include(link('rails/responders', 'https://github.com/rails/responders'))
    end

    it 'links Git repos' do
      expect(subject).to include(link('https://gitlab.example.com/gems/sprockets', 'https://gitlab.example.com/gems/sprockets'))
    end
  end
end
