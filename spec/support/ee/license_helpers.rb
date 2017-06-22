module EE
  module LicenseHelpers
    def stub_feature(feature, enabled = true)
      allow(License).to receive(:feature_available?).and_call_original

      allow(License).to receive(:feature_available?).with(feature) { enabled }
    end
  end
end
