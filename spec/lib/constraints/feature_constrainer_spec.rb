# frozen_string_literal: true

require 'spec_helper'

describe Constraints::FeatureConstrainer do
  describe '#matches' do
    it 'calls Feature.enabled? with the correct arguments' do
      expect(Feature).to receive(:enabled?).with(:feature_name, "an object", default_enabled: true)

      described_class.new(:feature_name, "an object", default_enabled: true).matches?(double('request'))
    end
  end
end
