# frozen_string_literal: true

module Organizations
  module ReleaseHelpers
    # Pins organization release flags in specs, like `stub_feature_flags`:
    # `stub_organization_release(my_flag: false)`. Stubs `Organizations::Release.enabled?`
    # per flag, so features are pinned independently of the stage flags backing them.
    def stub_organization_release(**flags)
      # Resolve each flag so an unknown one raises, the same as a typo'd feature flag.
      flags.each_key { |flag| ::Organizations::Release::Registry.instance.find(flag) }

      @organization_release_stubs ||= {}
      @organization_release_stubs.merge!(flags)
      stubs = @organization_release_stubs

      allow(::Organizations::Release).to receive(:enabled?).and_wrap_original do |original, flag, actor|
        stubs.fetch(flag) { original.call(flag, actor) }
      end
    end
  end
end

RSpec.configure do |config|
  config.include Organizations::ReleaseHelpers
end
