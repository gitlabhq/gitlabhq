module EE
  module LicenseHelpers
    # Enable/Disable a feature on the License for a spec.
    #
    # Example:
    #
    #   stub_licensed_features(geo: true, deploy_board: false)
    #
    # This enables `geo` and disables `deploy_board` features for a spec.
    # Other features are still enabled/disabled as defined in the licence.
    def stub_licensed_features(features)
      allow(License).to receive(:feature_available?).and_call_original

      features.each do |feature, enabled|
        allow(License).to receive(:feature_available?).with(feature) { enabled }
      end
    end
  end
end
