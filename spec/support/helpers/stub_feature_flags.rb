# frozen_string_literal: true

module StubFeatureFlags
  # Stub Feature flags with `flag_name: true/false`
  #
  # @param [Hash] features where key is feature name and value is boolean whether enabled or not.
  #               Alternatively, you can specify Hash to enable the flag on a specific thing.
  #
  # Examples
  # - `stub_feature_flags(ci_live_trace: false)` ... Disable `ci_live_trace`
  #   feature flag globally.
  # - `stub_feature_flags(ci_live_trace: { enabled: false, thing: project })` ...
  #   Disable `ci_live_trace` feature flag on the specified project.
  def stub_feature_flags(features)
    features.each do |feature_name, option|
      if option.is_a?(Hash)
        enabled, thing = option.values_at(:enabled, :thing)
      else
        enabled = option
        thing = nil
      end

      if thing
        allow(Feature).to receive(:enabled?).with(feature_name, thing, any_args) { enabled }
        allow(Feature).to receive(:enabled?).with(feature_name.to_s, thing, any_args) { enabled }
      else
        allow(Feature).to receive(:enabled?).with(feature_name, any_args) { enabled }
        allow(Feature).to receive(:enabled?).with(feature_name.to_s, any_args) { enabled }
      end
    end
  end
end
