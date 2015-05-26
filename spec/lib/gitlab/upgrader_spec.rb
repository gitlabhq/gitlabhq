require 'spec_helper'

describe Gitlab::Upgrader do
  let(:upgrader) { Gitlab::Upgrader.new }
  let(:current_version) { Gitlab::VERSION }

  describe 'current_version_raw' do
    it { expect(upgrader.current_version_raw).to eq(current_version) }
  end

  describe 'latest_version?' do
    it 'should be true if newest version' do
      allow(upgrader).to receive(:latest_version_raw).and_return(current_version)
      expect(upgrader.latest_version?).to be_truthy
    end
  end

  describe 'latest_version_raw' do
    it 'should be latest version for GitLab 5' do
      allow(upgrader).to receive(:current_version_raw).and_return("5.3.0")
      expect(upgrader.latest_version_raw).to eq("v5.4.2")
    end
  end
end
