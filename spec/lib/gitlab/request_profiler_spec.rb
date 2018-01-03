require 'spec_helper'

describe Gitlab::RequestProfiler do
  describe '.profile_token' do
    it 'returns a token' do
      expect(described_class.profile_token).to be_present
    end

    it 'caches the token' do
      expect(Rails.cache).to receive(:fetch).with('profile-token')

      described_class.profile_token
    end
  end

  describe '.remove_all_profiles' do
    it 'removes Gitlab::RequestProfiler::PROFILES_DIR directory' do
      dir = described_class::PROFILES_DIR
      FileUtils.mkdir_p(dir)

      expect(Dir.exist?(dir)).to be true

      described_class.remove_all_profiles
      expect(Dir.exist?(dir)).to be false
    end
  end
end
