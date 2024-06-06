# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Environment, feature_category: :shared do
  describe '#hostname' do
    before do
      described_class.clear_memoization(:hostname)
    end

    it 'returns the hostname from the HOSTNAME environment variable' do
      stub_env('HOSTNAME', 'example.com')

      expect(described_class.hostname).to eq('example.com')
    end

    it 'returns the system hostname if the HOSTNAME environment variable is not set' do
      stub_env('HOSTNAME', nil)
      allow(Socket).to receive(:gethostname).and_return('localhost')

      expect(described_class.hostname).to eq('localhost')
    end
  end

  describe '#static_verification?' do
    it 'returns true if STATIC_VERIFICATION is set to true and the environment is production' do
      stub_env('STATIC_VERIFICATION', 'true')
      allow(Rails.env).to receive(:production?).and_return(true)

      expect(described_class.static_verification?).to be true
    end

    it 'returns false if STATIC_VERIFICATION is set to false' do
      stub_env('STATIC_VERIFICATION', 'false')

      expect(described_class.static_verification?).to be false
    end

    it 'returns false if STATIC_VERIFICATION is not set and the environment is not production' do
      stub_env('STATIC_VERIFICATION', nil)
      allow(Rails.env).to receive(:production?).and_return(false)

      expect(described_class.static_verification?).to be false
    end
  end
end
