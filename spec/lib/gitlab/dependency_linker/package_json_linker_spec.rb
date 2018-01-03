require 'rails_helper'

describe Gitlab::DependencyLinker::PackageJsonLinker do
  describe '.support?' do
    it 'supports package.json' do
      expect(described_class.support?('package.json')).to be_truthy
    end

    it 'does not support other files' do
      expect(described_class.support?('package.json.example')).to be_falsey
    end
  end

  describe '#link' do
    let(:file_name) { "package.json" }

    let(:file_content) do
      <<-CONTENT.strip_heredoc
        {
          "name": "module-name",
          "version": "10.3.1",
          "repository": {
            "type": "git",
            "url": "https://github.com/vuejs/vue.git"
          },
          "homepage": "https://github.com/vuejs/vue#readme",
          "scripts": {
            "karma": "karma start config/karma.config.js --single-run"
          },
          "dependencies": {
            "primus": "*",
            "async": "~0.8.0",
            "express": "4.2.x",
            "bigpipe": "bigpipe/pagelet",
            "plates": "https://github.com/flatiron/plates/tarball/master",
            "karma": "^1.4.1"
          },
          "devDependencies": {
            "vows": "^0.7.0",
            "assume": "<1.0.0 || >=2.3.1 <2.4.5 || >=2.5.2 <3.0.0",
            "pre-commit": "*"
          },
          "license": "MIT"
        }
      CONTENT
    end

    subject { Gitlab::Highlight.highlight(file_name, file_content) }

    def link(name, url)
      %{<a href="#{url}" rel="nofollow noreferrer noopener" target="_blank">#{name}</a>}
    end

    it 'links the module name' do
      expect(subject).to include(link('module-name', 'https://npmjs.com/package/module-name'))
    end

    it 'links the homepage' do
      expect(subject).to include(link('https://github.com/vuejs/vue#readme', 'https://github.com/vuejs/vue#readme'))
    end

    it 'links the repository URL' do
      expect(subject).to include(link('https://github.com/vuejs/vue.git', 'https://github.com/vuejs/vue.git'))
    end

    it 'links the license' do
      expect(subject).to include(link('MIT', 'http://choosealicense.com/licenses/mit/'))
    end

    it 'links dependencies' do
      expect(subject).to include(link('primus', 'https://npmjs.com/package/primus'))
      expect(subject).to include(link('async', 'https://npmjs.com/package/async'))
      expect(subject).to include(link('express', 'https://npmjs.com/package/express'))
      expect(subject).to include(link('bigpipe', 'https://npmjs.com/package/bigpipe'))
      expect(subject).to include(link('plates', 'https://npmjs.com/package/plates'))
      expect(subject).to include(link('karma', 'https://npmjs.com/package/karma'))
      expect(subject).to include(link('vows', 'https://npmjs.com/package/vows'))
      expect(subject).to include(link('assume', 'https://npmjs.com/package/assume'))
      expect(subject).to include(link('pre-commit', 'https://npmjs.com/package/pre-commit'))
    end

    it 'links GitHub repos' do
      expect(subject).to include(link('bigpipe/pagelet', 'https://github.com/bigpipe/pagelet'))
    end

    it 'links Git repos' do
      expect(subject).to include(link('https://github.com/flatiron/plates/tarball/master', 'https://github.com/flatiron/plates/tarball/master'))
    end

    it 'does not link scripts with the same key as a package' do
      expect(subject).not_to include(link('karma start config/karma.config.js --single-run', 'https://github.com/karma start config/karma.config.js --single-run'))
    end
  end
end
