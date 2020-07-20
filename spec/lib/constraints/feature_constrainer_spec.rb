# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Constraints::FeatureConstrainer do
  describe '#matches' do
    it 'calls Feature.enabled? with the correct arguments' do
      gate = stub_feature_flag_gate("an object")

      expect(Feature).to receive(:enabled?)
        .with(:feature_name, gate, default_enabled: true)

      described_class.new(:feature_name, gate, default_enabled: true).matches?(double('request'))
    end
  end
end
