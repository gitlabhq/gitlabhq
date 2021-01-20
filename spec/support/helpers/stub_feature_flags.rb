# frozen_string_literal: true

module StubFeatureFlags
  def self.included(base)
    # Extend Feature class with methods that can stub feature flags.
    Feature.prepend(StubbedFeature)
  end

  class StubFeatureGate
    attr_reader :flipper_id

    def initialize(flipper_id)
      @flipper_id = flipper_id
    end
  end

  # Ensure feature flags are stubbed and reset.
  def stub_all_feature_flags
    Feature.stub = true
    Feature.reset_flipper
  end

  def unstub_all_feature_flags
    Feature.stub = false
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

  def skip_feature_flags_yaml_validation
    allow(Feature::Definition).to receive(:valid_usage!)
  end

  def skip_default_enabled_yaml_check
    allow(Feature::Definition).to receive(:default_enabled?).and_return(false)
  end
end
