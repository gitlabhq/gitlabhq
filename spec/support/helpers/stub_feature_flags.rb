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
  # - `stub_feature_flags(ci_live_trace: project)` ...
  # - `stub_feature_flags(ci_live_trace: [project1, project2])` ...
  #   Enable `ci_live_trace` feature flag only on the specified projects.
  def stub_feature_flags(features)
    features.each do |feature_name, actors|
      allow(Feature).to receive(:enabled?).with(feature_name, any_args).and_return(false)
      allow(Feature).to receive(:enabled?).with(feature_name.to_s, any_args).and_return(false)

      Array(actors).each do |actor|
        raise ArgumentError, "actor cannot be Hash" if actor.is_a?(Hash)

        case actor
        when false, true
          allow(Feature).to receive(:enabled?).with(feature_name, any_args).and_return(actor)
          allow(Feature).to receive(:enabled?).with(feature_name.to_s, any_args).and_return(actor)
        when nil, ActiveRecord::Base, Symbol, RSpec::Mocks::Double
          allow(Feature).to receive(:enabled?).with(feature_name, actor, any_args).and_return(true)
          allow(Feature).to receive(:enabled?).with(feature_name.to_s, actor, any_args).and_return(true)
        else
          raise ArgumentError, "#stub_feature_flags accepts only `nil`, `true`, `false`, `ActiveRecord::Base` or `Symbol` as actors"
        end
      end
    end
  end
end
