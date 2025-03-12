# frozen_string_literal: true

require "graphql/tracing/notifications_tracing"

module GraphQL
  module Tracing
    # This implementation forwards events to ActiveSupport::Notifications
    # with a `graphql` suffix.
    #
    # @see KEYS for event names
    module ActiveSupportNotificationsTracing
      # A cache of frequently-used keys to avoid needless string allocations
      KEYS = NotificationsTracing::KEYS
      NOTIFICATIONS_ENGINE = NotificationsTracing.new(ActiveSupport::Notifications) if defined?(ActiveSupport::Notifications)

      def self.trace(key, metadata, &blk)
        NOTIFICATIONS_ENGINE.trace(key, metadata, &blk)
      end
    end
  end
end
