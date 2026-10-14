# frozen_string_literal: true

module Gitlab
  module Testing
    # Collects the Snowplow payloads a spec produces. Backend events arrive from
    # SnowplowTestEmitter and frontend ones from SnowplowCollectorMiddleware, so a spec reads
    # both from one list. Specs opt in with the :capture_snowplow_events tag, otherwise the
    # buffer grows for the whole suite.
    module SnowplowEvents
      class << self
        def capture!
          @events = Concurrent::Array.new
        end

        def stop_capturing!
          @events = nil
        end

        def all
          @events.to_a
        end

        def record(events)
          @events&.concat(events)
        end
      end
    end
  end
end
