require 'rails_helper'

describe Gitlab::DependencyLinker::ComposerJsonLinker do
  describe '.support?' do
    it 'supports composer.json' do
      expect(described_class.support?('composer.json')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('composer.json.example')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "composer.json" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        {
          "name": "laravel/laravel",
          "homepage": "https://laravel.com/",
          "description": "The Laravel Framework.",
          "keywords": ["framework", "laravel"],
          "license": "MIT",
          "type": "project",
          "repositories": [
            {
              "type": "git",
              "url": "https://github.com/laravel/laravel.git"
            }
          ],
          "require": {
            "php": ">=5.5.9",
            "laravel/framework": "5.2.*"
          },
          "require-dev": {
            "fzaninotto/faker": "~1.4",
            "mockery/mockery": "0.9.*",
            "phpunit/phpunit": "~4.0",
            "symfony/css-selector": "2.8.*|3.0.*",
            "symfony/dom-crawler": "2.8.*|3.0.*"
          }
        }
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %{<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>}
    end

    it 'links the module name' do
      expect(subject).to include(link('laravel/laravel', 'https://packagist.org/packages/laravel/laravel'))
    end

    it 'links the homepage' do
      expect(subject).to include(link('https://laravel.com/', 'https://laravel.com/'))
    end

    it 'links the repository URL' do
      expect(subject).to include(link('https://github.com/laravel/laravel.git', 'https://github.com/laravel/laravel.git'))
    end

    it 'links the license' do
      expect(subject).to include(link('MIT', 'http://choosealicense.com/licenses/mit/'))
    end

    it 'links dependencies' do
      expect(subject).to include(link('laravel/framework', 'https://packagist.org/packages/laravel/framework'))
      expect(subject).to include(link('fzaninotto/faker', 'https://packagist.org/packages/fzaninotto/faker'))
      expect(subject).to include(link('mockery/mockery', 'https://packagist.org/packages/mockery/mockery'))
      expect(subject).to include(link('phpunit/phpunit', 'https://packagist.org/packages/phpunit/phpunit'))
      expect(subject).to include(link('symfony/css-selector', 'https://packagist.org/packages/symfony/css-selector'))
      expect(subject).to include(link('symfony/dom-crawler', 'https://packagist.org/packages/symfony/dom-crawler'))
    end

    it 'does not link core dependencies' do
      expect(subject).not_to include(link('php', 'https://packagist.org/packages/php'))
    end
  end
end
