require 'spec_helper'

describe Gitlab::Upgrader do
  let(:upgrader) { described_class.new }
  let(:current_version) { Gitlab::VERSION }

  describe 'current_version_raw' do
    it { expect(upgrader.current_version_raw).to eq(current_version) }
  end

  describe 'latest_version?' do
    it 'is true if newest version' do
      allow(upgrader).to receive(:latest_version_raw).and_return(current_version)
      expect(upgrader.latest_version?).to be_truthy
    end
  end

  describe 'latest_version_raw' do
    it 'is the latest version for GitLab 5' do
      allow(upgrader).to receive(:current_version_raw).and_return("5.3.0")
      expect(upgrader.latest_version_raw).to eq("v5.4.2")
    end

    it 'gets the latest version from tags' do
      allow(upgrader).to receive(:fetch_git_tags).and_return([
        '6f0733310546402c15d3ae6128a95052f6c8ea96  refs/tags/v7.1.1',
        'facfec4b242ce151af224e20715d58e628aa5e74  refs/tags/v7.1.1^{}',
        'f7068d99c79cf79befbd388030c051bb4b5e86d4  refs/tags/v7.10.4',
        '337225a4fcfa9674e2528cb6d41c46556bba9dfa  refs/tags/v7.10.4^{}',
        '880e0ba0adbed95d087f61a9a17515e518fc6440  refs/tags/v7.11.1',
        '6584346b604f981f00af8011cd95472b2776d912  refs/tags/v7.11.1^{}',
        '43af3e65a486a9237f29f56d96c3b3da59c24ae0  refs/tags/v7.11.2',
        'dac18e7728013a77410e926a1e64225703754a2d  refs/tags/v7.11.2^{}',
        '0bf21fd4b46c980c26fd8c90a14b86a4d90cc950  refs/tags/v7.9.4',
        'b10de29edbaff7219547dc506cb1468ee35065c3  refs/tags/v7.9.4^{}'
      ])
      expect(upgrader.latest_version_raw).to eq("v7.11.2")
    end
  end
end
