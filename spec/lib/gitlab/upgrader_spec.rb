require 'spec_helper'

describe Gitlab::Upgrader do
  let(:upgrader) { Gitlab::Upgrader.new }
  let(:current_version) { Gitlab::VERSION }

  describe 'current_version_raw' do
    it { expect(upgrader.current_version_raw).to eq(current_version) }
  end

  describe 'latest_version?' do
    it 'should be true if newest version' do
      upgrader.stub(latest_version_raw: current_version)
      expect(upgrader.latest_version?).to be_truthy
    end
  end

  describe 'latest_version_raw' do
    it 'should be latest version for GitLab 5' do
      upgrader.stub(current_version_raw: "6.3.0-ee")
      expect(upgrader.latest_version_raw).to match(/v6\.\d\.\d-ee/)
    end
  end
end
