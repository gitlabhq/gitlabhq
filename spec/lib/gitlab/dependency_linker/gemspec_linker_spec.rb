# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DependencyLinker::GemspecLinker do
  describe '.support?' do
    it 'supports *.gemspec' do
      expect(described_class.support?('gitlab_git.gemspec')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('.gemspec.example')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "gitlab_git.gemspec" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        Gem::Specification.new do |s|
          s.name        = 'gitlab_git'
          s.version     = `cat VERSION`
          s.date        = Date.current.iso8601
          s.summary     = "Gitlab::Git library"
          s.description = "GitLab wrapper around git objects"
          s.authors     = ["Dmitriy Zaporozhets"]
          s.email       = 'dmitriy.zaporozhets@gmail.com'
          s.license     = 'MIT'
          s.files       = `git ls-files lib/`.split('\n') << 'VERSION'
          s.homepage    = 'https://gitlab.com/gitlab-org/gitlab_git'

          s.add_dependency('github-linguist', '~> 4.7.0')
          s.add_dependency('activesupport', '~> 4.0')
          s.add_dependency('rugged', '~> 0.24.0')
          s.add_runtime_dependency('charlock_holmes', '~> 0.7.3')
          s.add_development_dependency('listen', '~> 3.0.6')
        end
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %(<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>)
    end

    it 'does not link the gem name' do
      expect(subject).not_to include(link('gitlab_git', 'https://rubygems.org/gems/gitlab_git'))
    end

    it 'links the license' do
      expect(subject).to include(link('MIT', 'http://choosealicense.com/licenses/mit/'))
    end

    it 'links the homepage' do
      expect(subject).to include(link('https://gitlab.com/gitlab-org/gitlab_git', 'https://gitlab.com/gitlab-org/gitlab_git'))
    end

    it 'links dependencies' do
      expect(subject).to include(link('github-linguist', 'https://rubygems.org/gems/github-linguist'))
      expect(subject).to include(link('activesupport', 'https://rubygems.org/gems/activesupport'))
      expect(subject).to include(link('rugged', 'https://rubygems.org/gems/rugged'))
      expect(subject).to include(link('charlock_holmes', 'https://rubygems.org/gems/charlock_holmes'))
      expect(subject).to include(link('listen', 'https://rubygems.org/gems/listen'))
    end
  end
end
