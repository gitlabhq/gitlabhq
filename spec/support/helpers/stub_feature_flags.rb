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
    Feature.reset_flipper
  end

  def stub_with_new_feature_current_request
    return unless Gitlab::SafeRequestStore.active?

    new_request = Feature::FlipperRequest.new
    allow(new_request).to receive(:flipper_id).and_return("FlipperRequest:#{SecureRandom.uuid}")

    allow(Feature).to receive(:current_request).and_return(new_request)
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
      unless Feature::Definition.get(feature_name)
        ActiveSupport::Deprecation.warn "Invalid Feature Flag #{feature_name} stubbed"
      end

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

  def skip_default_enabled_yaml_check
    allow(Feature::Definition).to receive(:default_enabled?).and_return(false)
  end

  def stub_feature_flag_definition(name, opts = {})
    opts = opts.with_defaults(
      name: name,
      type: 'development',
      default_enabled: false
    )

    Feature::Definition.new("#{opts[:type]}/#{name}.yml", opts).tap do |definition|
      all_definitions = Feature::Definition.definitions
      all_definitions[definition.key] = definition
      allow(Feature::Definition).to receive(:definitions).and_return(all_definitions)
    end
  end
end
