# frozen_string_literal: true

module FeatureFlagToggleHelpers
  # Runs the wrapped example group twice: once with `flag` disabled and once
  # enabled, so a flag-gated feature is covered in both states. The enabled
  # variant is tagged `:js` by default (flag-gated Vue migrations render
  # client-side); pass `js: false` for flags whose enabled path needs no browser.
  #
  # The `stub_feature_flags` call is defined before the wrapped block, so it runs
  # ahead of any `before` hook the block adds (e.g. one that signs in and renders
  # the flag-dependent page).
  #
  # Temporary scaffold for in-progress rollouts; remove the wrapper when the
  # flag is deleted.
  def with_and_without_ff(flag, js: true, &block)
    context "with #{flag} feature flag disabled" do
      before do
        stub_feature_flags(flag => false)
      end

      module_eval(&block)
    end

    context "with #{flag} feature flag enabled", *(js ? [:js] : []) do
      before do
        stub_feature_flags(flag => true)
      end

      module_eval(&block)
    end
  end
end

RSpec.configure do |config|
  config.extend FeatureFlagToggleHelpers, type: :feature
end
