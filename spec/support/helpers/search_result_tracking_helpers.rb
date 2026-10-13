# frozen_string_literal: true

module Search
  module ResultTrackingHelpers
    # Reads the `click_search_result` join key off every tracked result link.
    #
    # Returns one entry per tracked link rather than a count, so a link that rendered
    # the tracking attribute but lost only the property shows up as nil. Partial
    # application changes the ratio, not the total, which an absolute count cannot see
    # at fixtures that yield a single result.
    def tracked_link_properties(html)
      Nokogiri::HTML.fragment(html.to_s)
        .css("[data-event-tracking='click_search_result']")
        .map { |node| node['data-event-property'] } # rubocop:disable Rails/Pluck -- Nokogiri NodeSet, not an AR relation
    end

    # Records every internal event fired after this call as an [name, kwargs] pair.
    # Wraps rather than replaces track_event, so the real event still fires and its
    # own definition validations still run.
    def capture_internal_events
      events = []

      allow(Gitlab::InternalEvents).to receive(:track_event).and_wrap_original do |method, *args, **kwargs|
        events << [args.first, kwargs]
        method.call(*args, **kwargs)
      end

      events
    end

    # The join key carried on `name`, or nil when that event never fired.
    def emitted_join_key(events, name = 'perform_search')
      _, kwargs = events.find { |event_name, _| event_name == name }

      kwargs&.dig(:additional_properties, :property)
    end
  end
end

RSpec.configure do |config|
  config.include Search::ResultTrackingHelpers, type: :view
  config.include Search::ResultTrackingHelpers, type: :controller
end
