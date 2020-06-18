# frozen_string_literal: true

module StubFeatureFlags
  class StubFeatureGate
    attr_reader :flipper_id

    def initialize(flipper_id)
      @flipper_id = flipper_id
    end
  end

  def stub_all_feature_flags
    adapter = Flipper::Adapters::Memory.new
    flipper = Flipper.new(adapter)

    allow(Feature).to receive(:flipper).and_return(flipper)

    # All new requested flags are enabled by default
    allow(Feature).to receive(:enabled?).and_wrap_original do |m, *args|
      feature_flag = m.call(*args)

      # If feature flag is not persisted we mark the feature flag as enabled
      # We do `m.call` as we want to validate the execution of method arguments
      # and a feature flag state if it is not persisted
      unless Feature.persisted_name?(args.first)
        # TODO: this is hack to support `promo_feature_available?`
        # We enable all feature flags by default unless they are `promo_`
        # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/218667
        feature_flag = true unless args.first.to_s.start_with?('promo_')
      end

      feature_flag
    end
  end

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
      # Remove feature flag overwrite
      feature = Feature.get(feature_name) # rubocop:disable Gitlab/AvoidFeatureGet
      feature.remove

      Array(actors).each do |actor|
        raise ArgumentError, "actor cannot be Hash" if actor.is_a?(Hash)

        # Control a state of feature flag
        if actor == true || actor.nil? || actor.respond_to?(:flipper_id)
          feature.enable(actor)
        elsif actor == false
          feature.disable
        else
          raise ArgumentError, "#stub_feature_flags accepts only `nil`, `bool`, an object responding to `#flipper_id` or including `FeatureGate`."
        end
      end
    end
  end

  def stub_feature_flag_gate(object)
    return if object.nil?
    return object if object.is_a?(FeatureGate)

    StubFeatureGate.new(object)
  end
end
