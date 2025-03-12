# frozen_string_literal: true


module GraphQL
  module Tracing
    autoload :Trace, "graphql/tracing/trace"
    autoload :CallLegacyTracers, "graphql/tracing/call_legacy_tracers"
    autoload :LegacyTrace, "graphql/tracing/legacy_trace"
    autoload :LegacyHooksTrace, "graphql/tracing/legacy_hooks_trace"
    autoload :NullTrace, "graphql/tracing/null_trace"

    autoload :ActiveSupportNotificationsTracing, "graphql/tracing/active_support_notifications_tracing"
    autoload :PlatformTracing, "graphql/tracing/platform_tracing"
    autoload :AppOpticsTracing, "graphql/tracing/appoptics_tracing"
    autoload :AppsignalTracing, "graphql/tracing/appsignal_tracing"
    autoload :DataDogTracing, "graphql/tracing/data_dog_tracing"
    autoload :NewRelicTracing, "graphql/tracing/new_relic_tracing"
    autoload :NotificationsTracing, "graphql/tracing/notifications_tracing"
    autoload :ScoutTracing, "graphql/tracing/scout_tracing"
    autoload :StatsdTracing, "graphql/tracing/statsd_tracing"
    autoload :PrometheusTracing, "graphql/tracing/prometheus_tracing"

    autoload :ActiveSupportNotificationsTrace, "graphql/tracing/active_support_notifications_trace"
    autoload :PlatformTrace, "graphql/tracing/platform_trace"
    autoload :AppOpticsTrace, "graphql/tracing/appoptics_trace"
    autoload :AppsignalTrace, "graphql/tracing/appsignal_trace"
    autoload :DataDogTrace, "graphql/tracing/data_dog_trace"
    autoload :NewRelicTrace, "graphql/tracing/new_relic_trace"
    autoload :NotificationsTrace, "graphql/tracing/notifications_trace"
    autoload :SentryTrace, "graphql/tracing/sentry_trace"
    autoload :ScoutTrace, "graphql/tracing/scout_trace"
    autoload :StatsdTrace, "graphql/tracing/statsd_trace"
    autoload :PrometheusTrace, "graphql/tracing/prometheus_trace"
    autoload :PerfettoTrace, "graphql/tracing/perfetto_trace"
    autoload :DetailedTrace, "graphql/tracing/detailed_trace"

    # Objects may include traceable to gain a `.trace(...)` method.
    # The object must have a `@tracers` ivar of type `Array<<#trace(k, d, &b)>>`.
    # @api private
    module Traceable
      # @param key [String] The name of the event in GraphQL internals
      # @param metadata [Hash] Event-related metadata (can be anything)
      # @return [Object] Must return the value of the block
      def trace(key, metadata, &block)
        return yield if @tracers.empty?
        call_tracers(0, key, metadata, &block)
      end

      private

      # If there's a tracer at `idx`, call it and then increment `idx`.
      # Otherwise, yield.
      #
      # @param idx [Integer] Which tracer to call
      # @param key [String] The current event name
      # @param metadata [Object] The current event object
      # @return Whatever the block returns
      def call_tracers(idx, key, metadata, &block)
        if idx == @tracers.length
          yield
        else
          @tracers[idx].trace(key, metadata) { call_tracers(idx + 1, key, metadata, &block) }
        end
      end
    end

    module NullTracer
      module_function
      def trace(k, v)
        yield
      end
    end
  end
end
