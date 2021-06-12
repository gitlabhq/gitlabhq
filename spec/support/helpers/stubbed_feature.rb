# frozen_string_literal: true

# Extend the Feature class with the ability to stub feature flags.
module StubbedFeature
  extend ActiveSupport::Concern

  prepended do
    cattr_reader(:persist_used) do
      # persist feature flags in CI
      # nil: indicates that we do not want to persist used feature flags
      Gitlab::Utils.to_boolean(ENV['CI']) ? {} : nil
    end
  end

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
    def enabled?(*args, **kwargs)
      feature_flag = super
      return feature_flag unless stub?

      persist_used!(args.first)

      # If feature flag is not persisted we mark the feature flag as enabled
      # We do `m.call` as we want to validate the execution of method arguments
      # and a feature flag state if it is not persisted
      unless Feature.persisted_name?(args.first)
        feature_flag = true
      end

      feature_flag
    end

    # This method creates a temporary file in `tmp/feature_flags`
    # if feature flag was touched during execution
    def persist_used!(name)
      return unless persist_used
      return if persist_used[name]

      persist_used[name] = true
      FileUtils.touch(
        Rails.root.join('tmp', 'feature_flags', name.to_s + ".used")
      )
    end
  end
end
