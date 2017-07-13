module StubFeatureFlags
  def stub_feature_flags(features)
    features.each do |feature_name, enabled|
      allow(Feature).to receive(:enabled?).with(feature_name) { enabled }
      allow(Feature).to receive(:enabled?).with(feature_name.to_s) { enabled }
    end
  end
end
