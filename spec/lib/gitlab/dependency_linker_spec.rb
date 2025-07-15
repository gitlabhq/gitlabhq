# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DependencyLinker do
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

    it 'links using PodspecJsonLinker' do
      blob_name = 'AFNetworking.podspec.json'

      expect(described_class::PodspecJsonLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using CartfileLinker' do
      blob_name = 'Cartfile'

      expect(described_class::CartfileLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using GodepsJsonLinker' do
      blob_name = 'Godeps.json'

      expect(described_class::GodepsJsonLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using RequirementsTxtLinker' do
      blob_name = 'requirements.txt'

      expect(described_class::RequirementsTxtLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using CargoTomlLinker' do
      blob_name = 'Cargo.toml'

      expect(described_class::CargoTomlLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using GoModLinker' do
      blob_name = 'go.mod'

      expect(described_class::GoModLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'links using GoSumLinker' do
      blob_name = 'go.sum'

      expect(described_class::GoSumLinker).to receive(:link)

      described_class.link(blob_name, nil, nil)
    end

    it 'increments usage counter based on specified used_on', :prometheus do
      allow(described_class::GemfileLinker).to receive(:link)

      described_class.link('Gemfile', nil, nil, used_on: :diff)

      dependency_linker_usage_counter = Gitlab::Metrics.client.get(:dependency_linker_usage)

      expect(dependency_linker_usage_counter.get(used_on: :diff)).to eq(1)
      expect(dependency_linker_usage_counter.get(used_on: :blob)).to eq(0)
    end
  end
end
