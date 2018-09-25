module StubFeatureFlags
  # Stub Feature flags with `flag_name: true/false`
  #
  # @param [Hash] features where key is feature name and value is boolean whether enabled or not
  def stub_feature_flags(features)
    features.each do |feature_name, enabled|
      allow(Feature).to receive(:enabled?).with(feature_name, any_args) { enabled }
      allow(Feature).to receive(:enabled?).with(feature_name.to_s, any_args) { enabled }
    end
  end
end
