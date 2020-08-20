# frozen_string_literal: true

# Extend the Feature class with the ability to stub feature flags.
module StubbedFeature
  extend ActiveSupport::Concern

  class_methods do
    # Turn stubbed feature flags on or off.
    def stub=(stub)
      @stub = stub
    end

    def stub?
      @stub.nil? ? true : @stub
    end

    # Wipe any previously set feature flags.
    def reset_flipper
      @flipper = nil
    end

    # Replace #flipper method with the optional stubbed/unstubbed version.
    def flipper
      if stub?
        @flipper ||= Flipper.new(Flipper::Adapters::Memory.new)
      else
        super
      end
    end

    # Replace #enabled? method with the optional stubbed/unstubbed version.
    def enabled?(*args)
      feature_flag = super(*args)
      return feature_flag unless stub?

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
end
