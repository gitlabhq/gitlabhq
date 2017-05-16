require 'rails_helper'

describe Gitlab::DependencyLinker, lib: true do
  describe '.link' do
    it 'links using GemfileLinker' do
      blob_name = 'Gemfile'

      expect(described_class::GemfileLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using GemspecLinker' do
      blob_name = 'gitlab_git.gemspec'

      expect(described_class::GemspecLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using PackageJsonLinker' do
      blob_name = 'package.json'

      expect(described_class::PackageJsonLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using ComposerJsonLinker' do
      blob_name = 'composer.json'

      expect(described_class::ComposerJsonLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using PodfileLinker' do
      blob_name = 'Podfile'

      expect(described_class::PodfileLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using PodspecLinker' do
      blob_name = 'Reachability.podspec'

      expect(described_class::PodspecLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end
  end
end
