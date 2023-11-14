# frozen_string_literal: true

module StubSaasFeatures
  # Stub SaaS feature with `feature_name: true/false`
  #
  # @param [Hash] features where key is feature name and value is boolean whether enabled or not.
  #
  # Examples
  # - `stub_saas_features(onboarding: false)` ... Disable `onboarding`
  #   SaaS feature globally.
  # - `stub_saas_features(onboarding: true)` ... Enable `onboarding`
  #   SaaS feature globally.
  def stub_saas_features(features)
    features.each do |feature_name, value|
      raise ArgumentError, 'value must be boolean' unless value.in? [true, false]

      allow(::Gitlab::Saas).to receive(:feature_available?).with(feature_name).and_return(value)
    end
  end
end
