# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::FIPS do
  describe ".enabled?" do
    subject { described_class.enabled? }

    context "feature flag is enabled" do
      it { is_expected.to be_truthy }
    end

    context "feature flag is disabled" do
      before do
        stub_feature_flags(fips_mode: false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
