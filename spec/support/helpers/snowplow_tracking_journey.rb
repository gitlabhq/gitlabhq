# frozen_string_literal: true

# Loads the tracking contract for a user journey. The contract is a YAML file, kept separate
# from the spec so it stays readable to whoever owns the journey, and so it outlives whichever
# spec happens to walk that journey today.
#
# A journey an experiment is currently varying names the experiment and declares its arms under
# `variants:`. Events sit inside their arm, so neither the experiment nor the variant is
# repeated on them. When the experiment is cleaned up, move the winning arm's events to a
# top-level `events:` key and drop `experiment:` and `variants:`.
module SnowplowTrackingJourney
  DIRECTORY = Rails.root.join('spec/fixtures/snowplow_tracking_journeys')

  Journey = Struct.new(:experiment, :events, keyword_init: true)

  class << self
    def load(name, variant: nil)
      path = DIRECTORY.join("#{name}.yml")

      raise ArgumentError, "No tracking journey named '#{name}' in #{DIRECTORY}" unless path.exist?

      contents = YAML.safe_load(File.read(path))

      Journey.new(
        experiment: contents['experiment'],
        events: contents.fetch('events', []) + variant_events(contents, variant, name)
      )
    end

    private

    def variant_events(contents, variant, name)
      variants = contents['variants'].presence

      return [] unless variants || variant

      raise ArgumentError, "#{name} declares no variants, drop variant: #{variant}" unless variants
      raise ArgumentError, "#{name} declares variants #{variants.keys.join(', ')}, pass one" unless variant

      variants.fetch(variant.to_s) do
        raise ArgumentError, "#{name} has no variant '#{variant}', only #{variants.keys.join(', ')}"
      end.fetch('events', [])
    end
  end
end
