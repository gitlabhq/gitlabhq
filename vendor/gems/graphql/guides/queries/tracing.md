---
title: Tracing
layout: guide
doc_stub: false
search: true
section: Queries
desc: Observation hooks for execution
index: 11
redirect_from:
  - /queries/instrumentation
---

{{ "GraphQL::Tracing::Trace" | api_doc }} provides hooks to observe and modify events during runtime. Tracing hooks are methods, defined in modules and mixed in with {{ "Schema.trace_with" | api_doc }}.

```ruby
module CustomTrace
  def parse(query_string:)
    # measure, log, etc
    super
  end

  # ...
end
```

To include a trace module when running queries, add it to the schema with `trace_with`:

```ruby
# Run `MyCustomTrace` for all queries
class MySchema < GraphQL::Schema
  trace_with(MyCustomTrace)
end
```

For a full list of methods and their arguments, see {{ "GraphQL::Tracing::Trace" | api_doc }}.

By default, GraphQL-Ruby makes a new trace instance when it runs a query. You can pass an existing instance as `context: { trace: ... }`. Also, `GraphQL.parse( ..., trace: ...)` accepts a trace instance.

## Detailed Traces

You can capture detailed traces of query execution with {{ "Tracing::DetailedTrace" | api_doc }}. They can be viewed in Google's [Perfetto Trace Viewer](https://ui.perfetto.dev). They include a per-Fiber breakdown with links between fields and Dataloader sources.

{{ "/queries/perfetto_example.png" | link_to_img:"GraphQL-Ruby Dataloader Perfetto Trace" }}

Learn how to set it up in the {{ "Tracing::DetailedTrace" | api_doc }} docs.

## External Monitoring Platforms

There integrations for GraphQL-Ruby with several other monitoring systems:

- `ActiveSupport::Notifications`: See {{ "Tracing::ActiveSupportNotificationsTrace" | api_doc }}.
- [AppOptics](https://appoptics.com/) instrumentation is automatic in `appoptics_apm` v4.11.0+.
- [AppSignal](https://appsignal.com/): See {{ "Tracing::AppsignalTrace" | api_doc }}.
- [Datadog](https://www.datadoghq.com): See {{ "Tracing::DataDogTrace" | api_doc }}.
- [NewRelic](https://newrelic.com/): See {{ "Tracing::NewRelicTrace" | api_doc }}.
- [Prometheus](https://prometheus.io): See {{ "Tracing::PrometheusTrace" | api_doc }}.
- [Scout APM](https://scoutapp.com/): See {{ "Tracing::ScoutTrace" | api_doc }}.
- [Sentry](https://sentry.io): See {{ "Tracing::SentryTrace" | api_doc }}.
- [Skylight](https://www.skylight.io):  either enable the [GraphQL probe](https://www.skylight.io/support/getting-more-from-skylight#graphql) or use {{ "Tracing::ActiveSupportNotificationsTrace" | api_doc }}.
- Statsd: See {{ "Tracing::StatsdTrace" | api_doc }}.
